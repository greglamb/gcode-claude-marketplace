#!/usr/bin/env bash
# claudeBuggyPluginRepair.sh
#
# Workaround for Claude Code plugin scope bug (anthropics/claude-code#29240)
#
# When a plugin is installed at project/local scope, Claude Code's UI shows it
# as "Installed" globally, blocking reinstallation at a different scope or in
# other projects. This script manually edits the registry and settings files
# to promote, add, or fix plugin scope entries.
#
# Usage:
#   claudeBuggyPluginRepair.sh <command> [plugin@marketplace] [options]
#
# Commands:
#   doctor     Audit the entire plugin registry for common problems
#   promote    Promote a project/local-scoped plugin to user (global) scope
#   add        Add a plugin entry for the current project (project or local scope)
#   remove     Remove a plugin entry from a specific scope
#   clean      Remove all orphaned/stale entries from the registry
#   list       Show all entries for a plugin (or all plugins if none specified)
#   dedup      Remove duplicate entries for a plugin (or all plugins)
#   status     Show current scope status for a plugin across all projects
#
# Options:
#   --scope <user|project|local>   Target scope (default: user for promote, project for add)
#   --project-path <path>          Project path (default: current directory, for add/status)
#   --fix                          Auto-fix all issues found by doctor
#   --dry-run                      Show what would change without modifying files
#   --no-backup                    Skip creating .bak files
#   --no-lock                      Skip file locking (not recommended)
#   -y, --yes                      Skip confirmation prompts
#   -h, --help                     Show this help
#
# Examples:
#   # Full audit of plugin health (run from anywhere)
#   claudeBuggyPluginRepair.sh doctor
#
#   # Audit and auto-fix all issues
#   claudeBuggyPluginRepair.sh doctor --fix
#
#   # Promote a plugin from project scope to user (global) scope
#   claudeBuggyPluginRepair.sh promote my-plugin@my-marketplace
#
#   # Add a plugin to the current project with project scope
#   claudeBuggyPluginRepair.sh add my-plugin@my-marketplace
#
#   # Add a plugin to a specific project with local scope
#   claudeBuggyPluginRepair.sh add my-plugin@my-marketplace --scope local --project-path /path/to/project
#
#   # Remove a plugin entry from user scope
#   claudeBuggyPluginRepair.sh remove my-plugin@my-marketplace --scope user
#
#   # Remove a plugin entry from a specific project
#   claudeBuggyPluginRepair.sh remove my-plugin@my-marketplace --scope project --project-path /path/to/project
#
#   # Clean all orphaned entries
#   claudeBuggyPluginRepair.sh clean
#
#   # See what's registered for a plugin
#   claudeBuggyPluginRepair.sh status my-plugin@my-marketplace
#
#   # Remove duplicate entries for all plugins
#   claudeBuggyPluginRepair.sh dedup
#
#   # List all installed plugins
#   claudeBuggyPluginRepair.sh list
#
# Reference: https://github.com/anthropics/claude-code/issues/29240

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════
# Constants & Platform Detection
# ═══════════════════════════════════════════════════════════════════════

INSTALLED_PLUGINS="$HOME/.claude/plugins/installed_plugins.json"
KNOWN_MARKETPLACES="$HOME/.claude/plugins/known_marketplaces.json"
USER_SETTINGS="$HOME/.claude/settings.json"
PLUGIN_CACHE="$HOME/.claude/plugins/cache"
BACKUP_SUFFIX=".bak.$(date +%Y-%m-%d--%H-%M-%S)"

# Managed settings location (platform-dependent)
case "$(uname -s)" in
    Darwin)
        MANAGED_SETTINGS="/Library/Application Support/ClaudeCode/managed-settings.json"
        ;;
    Linux)
        MANAGED_SETTINGS="/etc/claude-code/managed-settings.json"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        MANAGED_SETTINGS="C:\\Program Files\\ClaudeCode\\managed-settings.json"
        ;;
    *)
        MANAGED_SETTINGS=""
        ;;
esac

# ═══════════════════════════════════════════════════════════════════════
# Defaults
# ═══════════════════════════════════════════════════════════════════════

DRY_RUN=false
NO_BACKUP=false
NO_LOCK=false
AUTO_YES=false
FIX_MODE=false
SCOPE=""
PROJECT_PATH=""

# ═══════════════════════════════════════════════════════════════════════
# Colors
# ═══════════════════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

# ═══════════════════════════════════════════════════════════════════════
# Output Helpers
# ═══════════════════════════════════════════════════════════════════════

info()  { echo -e "${GREEN}✓${NC} $*"; }
warn()  { echo -e "${YELLOW}⚠${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*" >&2; }
dry()   { echo -e "${CYAN}[dry-run]${NC} $*"; }
dim()   { echo -e "${DIM}  $*${NC}"; }

usage() {
    sed -n '/^# Usage:/,/^# Reference:/p' "$0" | sed 's/^# \?//'
    exit 0
}

confirm() {
    if $AUTO_YES || $FIX_MODE; then return 0; fi
    read -rp "$1 [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

# ═══════════════════════════════════════════════════════════════════════
# Prerequisites
# ═══════════════════════════════════════════════════════════════════════

require_jq() {
    if ! command -v jq &>/dev/null; then
        error "jq is required but not installed."
        echo "  Install: brew install jq (macOS) or sudo apt install jq (Linux)"
        exit 1
    fi
}

ensure_installed_plugins() {
    if [[ ! -f "$INSTALLED_PLUGINS" ]]; then
        error "installed_plugins.json not found at $INSTALLED_PLUGINS"
        echo "  Is Claude Code installed and has at least one plugin been installed?"
        exit 1
    fi
}

ensure_plugin_arg() {
    if [[ -z "${PLUGIN_ID:-}" ]]; then
        error "Plugin ID required in format: plugin-name@marketplace-name"
        exit 1
    fi
    if [[ "$PLUGIN_ID" != *@* ]]; then
        error "Plugin ID must include marketplace: plugin-name@marketplace-name"
        exit 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════
# Schema Validation
# ═══════════════════════════════════════════════════════════════════════

validate_registry_schema() {
    SCHEMA_ERRORS=()

    if ! jq empty "$INSTALLED_PLUGINS" 2>/dev/null; then
        SCHEMA_ERRORS+=("File is not valid JSON")
        return 1
    fi

    local top_type
    top_type=$(jq -r 'type' "$INSTALLED_PLUGINS")
    if [[ "$top_type" != "object" ]]; then
        SCHEMA_ERRORS+=("Top-level must be an object, got: $top_type")
        return 1
    fi

    local bad_keys
    bad_keys=$(jq -r 'keys[] | select(contains("@") | not)' "$INSTALLED_PLUGINS" 2>/dev/null || true)
    if [[ -n "$bad_keys" ]]; then
        while IFS= read -r k; do
            [[ -z "$k" ]] && continue
            SCHEMA_ERRORS+=("Key missing @marketplace separator: $k")
        done <<< "$bad_keys"
    fi

    local bad_values
    bad_values=$(jq -r 'to_entries[] | select(.value | type != "array") | .key' "$INSTALLED_PLUGINS" 2>/dev/null || true)
    if [[ -n "$bad_values" ]]; then
        while IFS= read -r k; do
            [[ -z "$k" ]] && continue
            SCHEMA_ERRORS+=("Value must be array, not scalar: $k")
        done <<< "$bad_values"
    fi

    local bad_entries
    bad_entries=$(jq -r '
        to_entries[] |
        select(.value | type == "array") |
        .key as $k |
        .value[] |
        select(
            (type != "object") or
            (has("scope") | not) or
            (.scope | type != "string") or
            (.scope | IN("user", "project", "local", "managed") | not)
        ) | $k
    ' "$INSTALLED_PLUGINS" 2>/dev/null || true)
    if [[ -n "$bad_entries" ]]; then
        while IFS= read -r k; do
            [[ -z "$k" ]] && continue
            SCHEMA_ERRORS+=("Entry missing or invalid 'scope' field: $k")
        done <<< "$bad_entries"
    fi

    local missing_pp
    missing_pp=$(jq -r '
        to_entries[] |
        .key as $k |
        .value[] |
        select(.scope == "project" or .scope == "local") |
        select(.projectPath == null or .projectPath == "") |
        $k
    ' "$INSTALLED_PLUGINS" 2>/dev/null || true)
    if [[ -n "$missing_pp" ]]; then
        while IFS= read -r k; do
            [[ -z "$k" ]] && continue
            SCHEMA_ERRORS+=("Project/local-scoped entry missing projectPath: $k")
        done <<< "$missing_pp"
    fi

    [[ ${#SCHEMA_ERRORS[@]} -eq 0 ]]
}

# ═══════════════════════════════════════════════════════════════════════
# Path Handling
# ═══════════════════════════════════════════════════════════════════════

canonical_path() {
    local p="$1"
    if command -v realpath &>/dev/null; then
        realpath -m "$p" 2>/dev/null || echo "$p"
    elif [[ -d "$p" ]]; then
        (cd "$p" 2>/dev/null && pwd -P) || echo "$p"
    else
        echo "$p"
    fi
}

expand_tilde() {
    local p="$1"
    if [[ "$p" == "~/"* ]]; then
        echo "${HOME}${p:1}"
    elif [[ "$p" == "~" ]]; then
        echo "$HOME"
    else
        echo "$p"
    fi
}

resolve_project_path() {
    if [[ -z "$PROJECT_PATH" ]]; then
        PROJECT_PATH="$(pwd)"
    fi
    PROJECT_PATH="$(canonical_path "$PROJECT_PATH")"
    if [[ ! -d "$PROJECT_PATH" ]]; then
        error "Project path does not exist: $PROJECT_PATH"
        exit 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════
# File Locking
# ═══════════════════════════════════════════════════════════════════════

LOCK_FD=""
LOCK_FILE=""

acquire_lock() {
    if $NO_LOCK || $DRY_RUN; then return 0; fi

    if ! command -v flock &>/dev/null; then
        warn "flock not available — skipping file lock (concurrent edits possible)"
        return 0
    fi

    LOCK_FILE="${INSTALLED_PLUGINS}.lock"
    exec {LOCK_FD}>"$LOCK_FILE"
    if ! flock -n "$LOCK_FD" 2>/dev/null; then
        error "Cannot acquire lock on $LOCK_FILE"
        echo "  Another instance may be running, or Claude Code is modifying plugins."
        echo "  Use --no-lock to bypass (not recommended)."
        exit 1
    fi
}

release_lock() {
    if [[ -n "${LOCK_FD:-}" ]]; then
        flock -u "$LOCK_FD" 2>/dev/null || true
        exec {LOCK_FD}>&- 2>/dev/null || true
    fi
    if [[ -n "${LOCK_FILE:-}" && -f "$LOCK_FILE" ]]; then
        rm -f "$LOCK_FILE" 2>/dev/null || true
    fi
}

trap release_lock EXIT

# ═══════════════════════════════════════════════════════════════════════
# Backup & Write Helpers
# ═══════════════════════════════════════════════════════════════════════

backup_file() {
    local file="$1"
    if $NO_BACKUP || $DRY_RUN; then return 0; fi
    if [[ -f "$file" ]]; then
        cp "$file" "${file}${BACKUP_SUFFIX}"
        info "Backed up $(basename "$file") → $(basename "$file")${BACKUP_SUFFIX}"
    fi
}

write_json() {
    local file="$1"
    local content="$2"
    echo "$content" > "${file}.tmp" && mv "${file}.tmp" "$file"
}

settings_file_for_scope() {
    local scope="$1"
    local proj_path="$2"
    case "$scope" in
        user)    echo "$USER_SETTINGS" ;;
        project) echo "${proj_path}/.claude/settings.json" ;;
        local)   echo "${proj_path}/.claude/settings.local.json" ;;
        managed) echo "$MANAGED_SETTINGS" ;;
        *)       error "Unknown scope: $scope"; exit 1 ;;
    esac
}

ensure_settings_file() {
    local file="$1"
    local dir
    dir="$(dirname "$file")"
    if [[ ! -d "$dir" ]]; then
        if $DRY_RUN; then dry "Would create directory: $dir"; return 0; fi
        mkdir -p "$dir"
    fi
    if [[ ! -f "$file" ]]; then
        if $DRY_RUN; then dry "Would create settings file: $file"; return 0; fi
        echo '{}' > "$file"
    fi
}

# ═══════════════════════════════════════════════════════════════════════
# Git Worktree Detection
# ═══════════════════════════════════════════════════════════════════════

git_common_dir() {
    local p="$1"
    if [[ ! -d "$p" ]]; then echo ""; return; fi
    local common
    common=$(git -C "$p" rev-parse --git-common-dir 2>/dev/null) || { echo ""; return; }
    canonical_path "$common"
}

# ═══════════════════════════════════════════════════════════════════════
# Managed Settings / Dev Plugin Detection / Disable Check
# ═══════════════════════════════════════════════════════════════════════

get_managed_plugins() {
    if [[ -z "$MANAGED_SETTINGS" || ! -f "$MANAGED_SETTINGS" ]]; then return; fi
    jq -r '.enabledPlugins // {} | keys[]' "$MANAGED_SETTINGS" 2>/dev/null || true
}

detect_plugin_dir_sessions() {
    if command -v ps &>/dev/null; then
        ps aux 2>/dev/null | grep -E 'claude.*--plugin-dir' | grep -v grep || true
    fi
}

is_explicitly_disabled() {
    local plugin_id="$1"
    local settings_file="$2"
    if [[ ! -f "$settings_file" ]]; then echo "false"; return; fi
    local val
    val=$(jq -r --arg id "$plugin_id" '.enabledPlugins[$id] // "absent"' "$settings_file")
    if [[ "$val" == "false" ]]; then echo "true"; else echo "false"; fi
}

# ═══════════════════════════════════════════════════════════════════════
# Doctor auto-fix helpers
# ═══════════════════════════════════════════════════════════════════════

_fix_promote() {
    local pid="$1"
    local install_path version now new_json
    install_path=$(jq -r --arg id "$pid" '.[$id][0].installPath' "$INSTALLED_PLUGINS")
    version=$(jq -r --arg id "$pid" '.[$id][0].version' "$INSTALLED_PLUGINS")
    now=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

    if $DRY_RUN; then dry "Would promote $pid to user scope"; return 0; fi

    backup_file "$INSTALLED_PLUGINS"
    new_json=$(jq --arg id "$pid" --arg ip "$install_path" --arg ver "$version" --arg now "$now" \
       '.[$id] = [{"scope":"user","installPath":$ip,"version":$ver,"installedAt":$now,"lastUpdated":$now}]
        + [.[$id][] | select(.scope != "user")]' "$INSTALLED_PLUGINS")
    write_json "$INSTALLED_PLUGINS" "$new_json"

    ensure_settings_file "$USER_SETTINGS"
    backup_file "$USER_SETTINGS"
    new_json=$(jq --arg id "$pid" '.enabledPlugins[$id] = true' "$USER_SETTINGS")
    write_json "$USER_SETTINGS" "$new_json"
    info "Promoted $pid to user scope"
}

_fix_dedup() {
    local pid="$1"
    if $DRY_RUN; then dry "Would deduplicate $pid"; return 0; fi
    backup_file "$INSTALLED_PLUGINS"
    local new_json
    new_json=$(jq --arg id "$pid" '.[$id] = (.[$id] | unique_by(.scope, .projectPath))' "$INSTALLED_PLUGINS")
    write_json "$INSTALLED_PLUGINS" "$new_json"
    info "Deduplicated $pid"
}

_fix_remove_entry() {
    local pid="$1" scope="$2" ppath="$3"
    if $DRY_RUN; then dry "Would remove $scope entry for $pid at $ppath"; return 0; fi
    backup_file "$INSTALLED_PLUGINS"
    local new_json
    new_json=$(jq --arg id "$pid" --arg sc "$scope" --arg pp "$ppath" '
        .[$id] = [.[$id][] | select(.scope != $sc or .projectPath != $pp)] |
        if .[$id] | length == 0 then del(.[$id]) else . end
    ' "$INSTALLED_PLUGINS")
    write_json "$INSTALLED_PLUGINS" "$new_json"
    info "Removed $scope entry for $pid (project: $ppath)"
}

# ═══════════════════════════════════════════════════════════════════════
# COMMAND: doctor
# ═══════════════════════════════════════════════════════════════════════

cmd_doctor() {
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "  Claude Code Plugin Doctor"
    echo "  Registry: $INSTALLED_PLUGINS"
    $FIX_MODE && echo "  Mode:     AUTO-FIX"
    echo "════════════════════════════════════════════════════════"
    echo ""

    local issues=0 warnings=0 fixed=0

    # ── Pre-flight: Schema validation ──────────────────────────────────
    echo "── Schema validation ─────────────────────────────────────────"
    if validate_registry_schema; then
        info "Registry schema is valid"
    else
        for e in "${SCHEMA_ERRORS[@]}"; do
            error "SCHEMA: $e"
            : $((issues += 1))
        done
        echo ""
        error "Registry has schema errors — other checks may produce unreliable results."
        echo "  Fix the schema issues manually before running doctor again."
        echo ""
    fi
    echo ""

    local plugin_count total_entries
    plugin_count=$(jq 'keys | length' "$INSTALLED_PLUGINS")
    total_entries=$(jq '[.[] | length] | add // 0' "$INSTALLED_PLUGINS")
    info "Found $plugin_count plugin(s) with $total_entries total registry entries"

    if [[ -n "$MANAGED_SETTINGS" && -f "$MANAGED_SETTINGS" ]]; then
        local managed_count
        managed_count=$(jq '.enabledPlugins // {} | keys | length' "$MANAGED_SETTINGS" 2>/dev/null || echo "0")
        dim "Managed settings: $MANAGED_SETTINGS ($managed_count plugins)"
    else
        dim "Managed settings: not found (normal for non-enterprise setups)"
    fi
    echo ""

    # Collect plugin IDs once for reuse
    local plugin_ids
    plugin_ids=$(jq -r 'keys[]' "$INSTALLED_PLUGINS")

    # ── Check 1: Ghost installs (#29240) ───────────────────────────────
    echo "── Ghost installs (core #29240 bug) ──────────────────────────"
    local ghosts
    ghosts=$(jq -r '
        to_entries[] |
        select(.value | all(.scope != "user" and .scope != "managed")) |
        .key
    ' "$INSTALLED_PLUGINS")

    if [[ -n "$ghosts" ]]; then
        while IFS= read -r pid; do
            [[ -z "$pid" ]] && continue
            # Skip if covered by managed settings outside the registry
            if [[ -n "$MANAGED_SETTINGS" && -f "$MANAGED_SETTINGS" ]]; then
                local mgd
                mgd=$(jq -r --arg id "$pid" '.enabledPlugins[$id] // "absent"' "$MANAGED_SETTINGS" 2>/dev/null || echo "absent")
                if [[ "$mgd" != "absent" ]]; then
                    dim "SKIP: $pid — covered by managed settings"
                    continue
                fi
            fi
            warn "GHOST: $pid"
            jq -r --arg id "$pid" '.[$id][] | "         scope=\(.scope) project=\(.projectPath // "n/a")"' "$INSTALLED_PLUGINS"
            echo -e "         ${CYAN}Fix: $(basename "$0") promote $pid${NC}"
            : $((issues += 1))
            if $FIX_MODE; then
                echo -e "         ${CYAN}[auto-fix] Promoting to user scope...${NC}"
                _fix_promote "$pid"; : $((fixed += 1))
            fi
        done <<< "$ghosts"
    else
        info "No ghost installs found"
    fi
    echo ""

    # ── Check 2: Duplicate entries ─────────────────────────────────────
    echo "── Duplicate entries ─────────────────────────────────────────"
    local has_dupes=false
    if [[ -n "$plugin_ids" ]]; then
        while IFS= read -r pid; do
            [[ -z "$pid" ]] && continue
            local count unique_count
            count=$(jq -r --arg id "$pid" '.[$id] | length' "$INSTALLED_PLUGINS")
            unique_count=$(jq -r --arg id "$pid" '.[$id] | unique_by(.scope, .projectPath) | length' "$INSTALLED_PLUGINS")
            if [[ "$count" -ne "$unique_count" ]]; then
                local dupes=$((count - unique_count))
                warn "DUPES: $pid ($dupes duplicate(s), $count total → $unique_count unique)"
                echo -e "         ${CYAN}Fix: $(basename "$0") dedup $pid${NC}"
                has_dupes=true; : $((issues += 1))
                if $FIX_MODE; then
                    echo -e "         ${CYAN}[auto-fix] Deduplicating...${NC}"
                    _fix_dedup "$pid"; : $((fixed += 1))
                fi
            fi
        done <<< "$plugin_ids"
    fi
    $has_dupes || info "No duplicate entries found"
    echo ""

    # ── Check 3: Orphaned project paths ────────────────────────────────
    echo "── Orphaned project paths ────────────────────────────────────"
    local has_orphans=false
    local project_entries
    project_entries=$(jq -r '
        to_entries[] | .key as $k | .value[] |
        select(.scope == "project" or .scope == "local") |
        select(.projectPath != null) |
        "\($k)\t\(.scope)\t\(.projectPath)"
    ' "$INSTALLED_PLUGINS")

    if [[ -n "$project_entries" ]]; then
        while IFS=$'\t' read -r pid scope ppath; do
            [[ -z "$pid" ]] && continue
            if [[ ! -d "$ppath" ]]; then
                warn "ORPHAN: $pid → $ppath (directory not found)"
                echo "         scope=$scope"
                echo -e "         ${CYAN}Fix: $(basename "$0") remove $pid --scope $scope --project-path $ppath${NC}"
                has_orphans=true; : $((warnings += 1))
                if $FIX_MODE; then
                    echo -e "         ${CYAN}[auto-fix] Removing orphaned entry...${NC}"
                    _fix_remove_entry "$pid" "$scope" "$ppath"; : $((fixed += 1))
                fi
            fi
        done <<< "$project_entries"
    fi
    $has_orphans || info "All project paths exist"
    echo ""

    # ── Check 4: Missing plugin cache ──────────────────────────────────
    echo "── Missing plugin cache ──────────────────────────────────────"
    local has_missing_cache=false
    local cache_entries
    cache_entries=$(jq -r '
        to_entries[] | .key as $k | .value[] |
        select(.installPath != null) |
        "\($k)\t\(.installPath)"
    ' "$INSTALLED_PLUGINS")

    if [[ -n "$cache_entries" ]]; then
        local -A seen_cache
        while IFS=$'\t' read -r pid ipath; do
            [[ -z "$pid" ]] && continue
            local expanded
            expanded="$(expand_tilde "$ipath")"
            if [[ -n "${seen_cache[$expanded]+x}" ]]; then continue; fi
            seen_cache[$expanded]=1
            if [[ ! -d "$expanded" ]]; then
                warn "MISSING CACHE: $pid → $ipath"
                has_missing_cache=true; : $((warnings += 1))
            fi
        done <<< "$cache_entries"
    fi
    $has_missing_cache || info "All plugin caches present"
    echo ""

    # ── Check 5: User settings desync ──────────────────────────────────
    echo "── User settings sync ────────────────────────────────────────"
    local has_desync=false

    if [[ -f "$USER_SETTINGS" ]]; then
        # 5a: User-scope registry entries without enabledPlugins
        local user_scope_plugins
        user_scope_plugins=$(jq -r 'to_entries[] | select(.value | any(.scope == "user")) | .key' "$INSTALLED_PLUGINS")
        if [[ -n "$user_scope_plugins" ]]; then
            while IFS= read -r pid; do
                [[ -z "$pid" ]] && continue
                local enabled_val
                enabled_val=$(jq -r --arg id "$pid" '.enabledPlugins[$id] // "absent"' "$USER_SETTINGS")
                if [[ "$enabled_val" == "absent" ]]; then
                    warn "DESYNC: $pid has user-scope registry entry but not in enabledPlugins"
                    echo -e "         ${CYAN}Fix: add enabledPlugins entry to $USER_SETTINGS${NC}"
                    has_desync=true; : $((issues += 1))
                    if $FIX_MODE; then
                        echo -e "         ${CYAN}[auto-fix] Adding enabledPlugins entry...${NC}"
                        backup_file "$USER_SETTINGS"
                        local nj; nj=$(jq --arg id "$pid" '.enabledPlugins[$id] = true' "$USER_SETTINGS")
                        write_json "$USER_SETTINGS" "$nj"; : $((fixed += 1))
                    fi
                fi
            done <<< "$user_scope_plugins"
        fi

        # 5b: Stale enabledPlugins (no registry entry)
        local enabled_plugins
        enabled_plugins=$(jq -r '.enabledPlugins // {} | keys[]' "$USER_SETTINGS" 2>/dev/null || true)
        if [[ -n "$enabled_plugins" ]]; then
            while IFS= read -r pid; do
                [[ -z "$pid" ]] && continue
                local has_entry
                has_entry=$(jq -r --arg id "$pid" 'has($id)' "$INSTALLED_PLUGINS")
                if [[ "$has_entry" != "true" ]]; then
                    warn "STALE: $pid in enabledPlugins but not in registry"
                    echo -e "         ${CYAN}Fix: $(basename "$0") clean${NC}"
                    has_desync=true; : $((warnings += 1))
                fi
            done <<< "$enabled_plugins"
        fi

        # 5c: Explicitly disabled plugins (informational)
        local disabled_plugins
        disabled_plugins=$(jq -r '.enabledPlugins // {} | to_entries[] | select(.value == false) | .key' "$USER_SETTINGS" 2>/dev/null || true)
        if [[ -n "$disabled_plugins" ]]; then
            while IFS= read -r pid; do
                [[ -z "$pid" ]] && continue
                dim "NOTE: $pid is explicitly disabled (enabledPlugins: false)"
            done <<< "$disabled_plugins"
        fi
    else
        warn "User settings file not found: $USER_SETTINGS"
        : $((warnings += 1))
    fi
    $has_desync || info "User settings in sync with registry"
    echo ""

    # ── Check 6: Project settings audit ────────────────────────────────
    echo "── Project settings audit ────────────────────────────────────"
    local has_stale_project=false

    if [[ -n "$project_entries" ]]; then
        local unique_projects
        unique_projects=$(jq -r '[.[][] | select(.projectPath != null) | .projectPath] | unique[]' "$INSTALLED_PLUGINS")
        if [[ -n "$unique_projects" ]]; then
            while IFS= read -r ppath; do
                [[ -z "$ppath" || ! -d "$ppath" ]] && continue
                for sfile in "${ppath}/.claude/settings.json" "${ppath}/.claude/settings.local.json"; do
                    [[ ! -f "$sfile" ]] && continue
                    local proj_enabled
                    proj_enabled=$(jq -r '.enabledPlugins // {} | keys[]' "$sfile" 2>/dev/null || true)
                    [[ -z "$proj_enabled" ]] && continue
                    while IFS= read -r pid; do
                        [[ -z "$pid" ]] && continue
                        local scope_for_file
                        [[ "$sfile" == *"settings.local.json" ]] && scope_for_file="local" || scope_for_file="project"
                        local matched
                        matched=$(jq -r --arg id "$pid" --arg pp "$ppath" --arg sc "$scope_for_file" '
                            .[$id] // [] | any(.scope == $sc and .projectPath == $pp)
                        ' "$INSTALLED_PLUGINS")
                        if [[ "$matched" != "true" ]]; then
                            local has_user
                            has_user=$(jq -r --arg id "$pid" '.[$id] // [] | any(.scope == "user")' "$INSTALLED_PLUGINS")
                            if [[ "$has_user" != "true" ]]; then
                                warn "STALE PROJECT: $pid enabled in $sfile but no matching registry entry"
                                has_stale_project=true; : $((warnings += 1))
                            fi
                        fi
                    done <<< "$proj_enabled"
                done
            done <<< "$unique_projects"
        fi
    fi
    $has_stale_project || info "Project settings consistent"
    echo ""

    # ── Check 7: Version mismatches ────────────────────────────────────
    echo "── Version consistency ────────────────────────────────────────"
    local has_version_mismatch=false
    if [[ -n "$plugin_ids" ]]; then
        while IFS= read -r pid; do
            [[ -z "$pid" ]] && continue
            local ver_count
            ver_count=$(jq -r --arg id "$pid" '[.[$id][] | .version // "unknown"] | unique | length' "$INSTALLED_PLUGINS")
            if [[ "$ver_count" -gt 1 ]]; then
                warn "VERSION MISMATCH: $pid has entries at different versions:"
                jq -r --arg id "$pid" '.[$id][] | "         v\(.version // "?") scope=\(.scope) project=\(.projectPath // "n/a")"' "$INSTALLED_PLUGINS"
                echo -e "         ${CYAN}Tip: Update the plugin to sync versions across scopes${NC}"
                has_version_mismatch=true; : $((warnings += 1))
            fi
        done <<< "$plugin_ids"
    fi
    $has_version_mismatch || info "All plugin versions consistent across scopes"
    echo ""

    # ── Check 8: Git worktree conflicts ────────────────────────────────
    echo "── Git worktree detection ────────────────────────────────────"
    local has_worktree_issue=false

    if command -v git &>/dev/null && [[ -n "$project_entries" ]]; then
        local -A repo_paths
        local unique_pp
        unique_pp=$(jq -r '[.[][] | select(.projectPath != null) | .projectPath] | unique[]' "$INSTALLED_PLUGINS")
        if [[ -n "$unique_pp" ]]; then
            while IFS= read -r ppath; do
                [[ -z "$ppath" || ! -d "$ppath" ]] && continue
                local common
                common=$(git_common_dir "$ppath")
                if [[ -n "$common" ]]; then
                    if [[ -n "${repo_paths[$common]+x}" ]]; then
                        repo_paths[$common]="${repo_paths[$common]}"$'\n'"$ppath"
                    else
                        repo_paths[$common]="$ppath"
                    fi
                fi
            done <<< "$unique_pp"

            for common in "${!repo_paths[@]}"; do
                local path_count
                path_count=$(echo "${repo_paths[$common]}" | wc -l | tr -d ' ')
                if [[ "$path_count" -gt 1 ]]; then
                    warn "WORKTREE: Multiple project paths share the same git repo:"
                    echo "         Git common dir: $common"
                    echo "${repo_paths[$common]}" | while IFS= read -r wp; do echo "         ↳ $wp"; done
                    echo -e "         ${CYAN}Tip: Plugins installed to one worktree won't be found via another${NC}"
                    has_worktree_issue=true; : $((warnings += 1))
                fi
            done
        fi
    fi
    $has_worktree_issue || info "No git worktree conflicts detected"
    echo ""

    # ── Check 9: Marketplace validation ────────────────────────────────
    echo "── Marketplace validation ────────────────────────────────────"
    local has_marketplace_issue=false

    if [[ -f "$KNOWN_MARKETPLACES" ]]; then
        local registry_mps known_names
        registry_mps=$(jq -r 'keys[] | split("@")[1]' "$INSTALLED_PLUGINS" | sort -u)
        known_names=$(jq -r '.[].name // empty' "$KNOWN_MARKETPLACES" 2>/dev/null | sort -u || true)

        if [[ -n "$registry_mps" && -n "$known_names" ]]; then
            while IFS= read -r mp; do
                [[ -z "$mp" ]] && continue
                if ! echo "$known_names" | grep -qxF "$mp"; then
                    warn "UNKNOWN MARKETPLACE: '$mp' referenced in plugins but not in known_marketplaces.json"
                    dim "May be fine if the marketplace was removed after installation"
                    has_marketplace_issue=true; : $((warnings += 1))
                fi
            done <<< "$registry_mps"
        fi
    else
        dim "known_marketplaces.json not found — skipping marketplace validation"
    fi
    $has_marketplace_issue || info "All marketplaces validated (or no data available)"
    echo ""

    # ── Check 10: Development plugin sessions ──────────────────────────
    echo "── Development plugin sessions ───────────────────────────────"
    local dev_sessions
    dev_sessions=$(detect_plugin_dir_sessions)
    if [[ -n "$dev_sessions" ]]; then
        warn "Active Claude Code sessions using --plugin-dir detected:"
        echo "$dev_sessions" | while IFS= read -r line; do dim "$line"; done
        echo -e "         ${CYAN}Tip: --plugin-dir plugins bypass the cache and registry${NC}"
        echo -e "         ${CYAN}Tip: Conflicts may arise if a cached version also exists${NC}"
        : $((warnings += 1))
    else
        info "No --plugin-dir development sessions detected"
    fi
    echo ""

    # ── Check 11: Redundant scope entries ──────────────────────────────
    echo "── Redundant scope entries ───────────────────────────────────"
    local has_redundant=false
    if [[ -n "$plugin_ids" ]]; then
        while IFS= read -r pid; do
            [[ -z "$pid" ]] && continue
            local has_user
            has_user=$(jq -r --arg id "$pid" '.[$id] // [] | any(.scope == "user")' "$INSTALLED_PLUGINS")
            if [[ "$has_user" == "true" ]]; then
                local proj_entries
                proj_entries=$(jq -r --arg id "$pid" '
                    .[$id][] | select(.scope == "project" or .scope == "local") |
                    "         scope=\(.scope) project=\(.projectPath // "n/a")"
                ' "$INSTALLED_PLUGINS")
                if [[ -n "$proj_entries" ]]; then
                    warn "REDUNDANT: $pid has user-scope (global) AND project/local entries:"
                    echo "$proj_entries"
                    dim "The project/local entries are redundant since user-scope covers all projects"
                    has_redundant=true; : $((warnings += 1))
                fi
            fi
        done <<< "$plugin_ids"
    fi
    $has_redundant || info "No redundant scope entries"
    echo ""

    # ── Check 12: Path normalization issues ────────────────────────────
    echo "── Path normalization ────────────────────────────────────────"
    local has_path_issue=false
    if [[ -n "$project_entries" ]]; then
        while IFS=$'\t' read -r pid scope ppath; do
            [[ -z "$pid" || ! -d "$ppath" ]] && continue
            local canon
            canon="$(canonical_path "$ppath")"
            if [[ "$canon" != "$ppath" ]]; then
                warn "PATH MISMATCH: $pid"
                echo "         Registry:  $ppath"
                echo "         Canonical: $canon"
                dim "Symlink or non-canonical path — Claude Code may not match this entry"
                has_path_issue=true; : $((warnings += 1))
            fi
        done <<< "$project_entries"
    fi
    $has_path_issue || info "All project paths are canonical"
    echo ""

    # ── Summary ────────────────────────────────────────────────────────
    echo "════════════════════════════════════════════════════════"
    if [[ $issues -eq 0 && $warnings -eq 0 ]]; then
        info "All clear — no issues found"
    else
        [[ $issues -gt 0 ]]   && error "$issues issue(s) found (will cause problems)"
        [[ $warnings -gt 0 ]] && warn  "$warnings warning(s) found (may cause confusion)"
        if $FIX_MODE; then
            [[ $fixed -gt 0 ]] && info "Auto-fixed $fixed item(s)"
            local remaining=$(( issues + warnings - fixed ))
            [[ $remaining -gt 0 ]] && echo "  Some items require manual attention — see warnings above."
        else
            echo ""
            echo "  Run with --fix to auto-fix issues, or use individual commands:"
            echo "    $(basename "$0") promote <plugin@marketplace>"
            echo "    $(basename "$0") dedup [plugin@marketplace]"
            echo "    $(basename "$0") remove <plugin@marketplace> --scope <scope>"
            echo "    $(basename "$0") clean"
        fi
    fi
    echo "════════════════════════════════════════════════════════"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════
# COMMAND: promote
# ═══════════════════════════════════════════════════════════════════════

cmd_promote() {
    ensure_plugin_arg; acquire_lock
    local target_scope="${SCOPE:-user}"

    if [[ "$target_scope" != "user" ]]; then
        error "Promote target must be 'user' scope. Use 'add' for project scope."
        exit 1
    fi

    local entries
    entries=$(jq -r --arg id "$PLUGIN_ID" '.[$id] // empty' "$INSTALLED_PLUGINS")
    [[ -z "$entries" ]] && { error "Plugin '$PLUGIN_ID' not found in installed_plugins.json"; exit 1; }

    local has_user
    has_user=$(jq -r --arg id "$PLUGIN_ID" '.[$id] // [] | any(.scope == "user")' "$INSTALLED_PLUGINS")
    if [[ "$has_user" == "true" ]]; then
        warn "Plugin '$PLUGIN_ID' already has a user-scope entry."
        jq -r --arg id "$PLUGIN_ID" '.[$id][] | "    scope=\(.scope) projectPath=\(.projectPath // "n/a")"' "$INSTALLED_PLUGINS"
        exit 0
    fi

    # Respect explicit disable
    if [[ "$(is_explicitly_disabled "$PLUGIN_ID" "$USER_SETTINGS")" == "true" ]]; then
        warn "Plugin '$PLUGIN_ID' is explicitly disabled in user settings (enabledPlugins: false)."
        if ! confirm "Override and enable at user scope?"; then echo "Aborted."; exit 0; fi
    fi

    local install_path version
    install_path=$(jq -r --arg id "$PLUGIN_ID" '.[$id][0].installPath' "$INSTALLED_PLUGINS")
    version=$(jq -r --arg id "$PLUGIN_ID" '.[$id][0].version' "$INSTALLED_PLUGINS")

    echo ""
    echo "Plugin:       $PLUGIN_ID"
    echo "Install path: $install_path"
    echo "Version:      $version"
    echo ""
    echo "Current entries:"
    jq -r --arg id "$PLUGIN_ID" '.[$id][] | "  scope=\(.scope) projectPath=\(.projectPath // "n/a")"' "$INSTALLED_PLUGINS"
    echo ""
    echo "Action: Add a user-scope entry (making plugin available globally)"
    echo ""
    if ! confirm "Proceed?"; then echo "Aborted."; exit 0; fi

    if $DRY_RUN; then
        dry "Would add user-scope entry to installed_plugins.json"
        dry "Would add enabledPlugins entry to $USER_SETTINGS"
        return 0
    fi

    _fix_promote "$PLUGIN_ID"
    echo ""
    info "Done. Run /reload-plugins in Claude Code (or restart) to activate."
}

# ═══════════════════════════════════════════════════════════════════════
# COMMAND: add
# ═══════════════════════════════════════════════════════════════════════

cmd_add() {
    ensure_plugin_arg; acquire_lock; resolve_project_path
    local target_scope="${SCOPE:-project}"

    [[ "$target_scope" == "user" ]] && { error "Use 'promote' for user scope."; exit 1; }

    local entries
    entries=$(jq -r --arg id "$PLUGIN_ID" '.[$id] // empty' "$INSTALLED_PLUGINS")
    if [[ -z "$entries" ]]; then
        error "Plugin '$PLUGIN_ID' not found in installed_plugins.json"
        echo "  The plugin must be installed at least once before adding to another project."
        exit 1
    fi

    # Idempotency: warn if user-scope already covers it
    local has_user
    has_user=$(jq -r --arg id "$PLUGIN_ID" '.[$id] // [] | any(.scope == "user")' "$INSTALLED_PLUGINS")
    if [[ "$has_user" == "true" ]]; then
        warn "Plugin '$PLUGIN_ID' already has a user-scope entry (covers all projects)."
        echo "  Adding a $target_scope entry for $PROJECT_PATH would be redundant."
        if ! confirm "Add redundant entry anyway?"; then echo "Aborted."; exit 0; fi
    fi

    local canonical_pp
    canonical_pp="$(canonical_path "$PROJECT_PATH")"
    local already
    already=$(jq -r --arg id "$PLUGIN_ID" --arg pp "$canonical_pp" --arg sc "$target_scope" '
        .[$id] // [] | any(.scope == $sc and .projectPath == $pp)
    ' "$INSTALLED_PLUGINS")
    if [[ "$already" == "true" ]]; then
        warn "Plugin '$PLUGIN_ID' already has a $target_scope entry for $PROJECT_PATH"
        exit 0
    fi

    # Respect explicit disable
    local settings_file
    settings_file=$(settings_file_for_scope "$target_scope" "$PROJECT_PATH")
    if [[ "$(is_explicitly_disabled "$PLUGIN_ID" "$settings_file")" == "true" ]]; then
        warn "Plugin '$PLUGIN_ID' is explicitly disabled in $settings_file (enabledPlugins: false)."
        if ! confirm "Override and enable?"; then echo "Aborted."; exit 0; fi
    fi

    local install_path version
    install_path=$(jq -r --arg id "$PLUGIN_ID" '.[$id][0].installPath' "$INSTALLED_PLUGINS")
    version=$(jq -r --arg id "$PLUGIN_ID" '.[$id][0].version' "$INSTALLED_PLUGINS")

    echo ""
    echo "Plugin:       $PLUGIN_ID"
    echo "Scope:        $target_scope"
    echo "Project:      $PROJECT_PATH"
    echo "Install path: $install_path"
    echo "Version:      $version"
    echo ""
    echo "Action: Add $target_scope-scope entry for this project"
    echo ""
    if ! confirm "Proceed?"; then echo "Aborted."; exit 0; fi

    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

    if $DRY_RUN; then
        dry "Would add $target_scope-scope entry to installed_plugins.json"
        dry "Would add enabledPlugins entry to $settings_file"
        return 0
    fi

    backup_file "$INSTALLED_PLUGINS"
    local new_json
    new_json=$(jq --arg id "$PLUGIN_ID" --arg ip "$install_path" --arg ver "$version" \
       --arg sc "$target_scope" --arg pp "$canonical_pp" --arg now "$now" \
       '.[$id] += [{"scope":$sc,"projectPath":$pp,"installPath":$ip,"version":$ver,"installedAt":$now,"lastUpdated":$now}]' \
       "$INSTALLED_PLUGINS")
    write_json "$INSTALLED_PLUGINS" "$new_json"
    info "Added $target_scope-scope entry to installed_plugins.json"

    ensure_settings_file "$settings_file"
    backup_file "$settings_file"
    new_json=$(jq --arg id "$PLUGIN_ID" '.enabledPlugins[$id] = true' "$settings_file")
    write_json "$settings_file" "$new_json"
    info "Enabled plugin in $settings_file"
    echo ""
    info "Done. Run /reload-plugins in Claude Code (or restart) to activate."
}

# ═══════════════════════════════════════════════════════════════════════
# COMMAND: remove
# ═══════════════════════════════════════════════════════════════════════

cmd_remove() {
    ensure_plugin_arg; acquire_lock
    local target_scope="${SCOPE:-}"

    if [[ -z "$target_scope" ]]; then
        error "--scope is required for remove."
        echo "  Specify: --scope user, --scope project, or --scope local"
        exit 1
    fi
    [[ "$target_scope" == "managed" ]] && { error "Cannot remove managed-scope plugins — controlled by your administrator."; exit 1; }

    local entries
    entries=$(jq -r --arg id "$PLUGIN_ID" '.[$id] // empty' "$INSTALLED_PLUGINS")
    [[ -z "$entries" ]] && { error "Plugin '$PLUGIN_ID' not found in registry."; exit 1; }

    local target_pp=""
    if [[ "$target_scope" == "project" || "$target_scope" == "local" ]]; then
        resolve_project_path
        target_pp="$PROJECT_PATH"
    fi

    local exists
    if [[ "$target_scope" == "user" ]]; then
        exists=$(jq -r --arg id "$PLUGIN_ID" '.[$id] // [] | any(.scope == "user")' "$INSTALLED_PLUGINS")
    else
        exists=$(jq -r --arg id "$PLUGIN_ID" --arg sc "$target_scope" --arg pp "$target_pp" '
            .[$id] // [] | any(.scope == $sc and .projectPath == $pp)
        ' "$INSTALLED_PLUGINS")
    fi

    if [[ "$exists" != "true" ]]; then
        error "No $target_scope entry found for '$PLUGIN_ID'$([ -n "$target_pp" ] && echo " at $target_pp")"
        jq -r --arg id "$PLUGIN_ID" '.[$id][] | "    scope=\(.scope) projectPath=\(.projectPath // "n/a")"' "$INSTALLED_PLUGINS"
        exit 1
    fi

    echo ""
    echo "Plugin:  $PLUGIN_ID"
    echo "Scope:   $target_scope"
    [[ -n "$target_pp" ]] && echo "Project: $target_pp"
    echo ""
    echo "Action: Remove this entry from the registry and settings"

    local remaining
    if [[ "$target_scope" == "user" ]]; then
        remaining=$(jq -r --arg id "$PLUGIN_ID" '.[$id] // [] | [.[] | select(.scope != "user")] | length' "$INSTALLED_PLUGINS")
    else
        remaining=$(jq -r --arg id "$PLUGIN_ID" --arg sc "$target_scope" --arg pp "$target_pp" '
            .[$id] // [] | [.[] | select(.scope != $sc or .projectPath != $pp)] | length
        ' "$INSTALLED_PLUGINS")
    fi
    [[ "$remaining" == "0" ]] && warn "This is the last entry — the plugin key will be removed entirely."
    echo ""
    if ! confirm "Proceed?"; then echo "Aborted."; exit 0; fi

    if $DRY_RUN; then
        dry "Would remove $target_scope entry from installed_plugins.json"
        return 0
    fi

    # Remove from registry
    backup_file "$INSTALLED_PLUGINS"
    local new_json
    if [[ "$target_scope" == "user" ]]; then
        new_json=$(jq --arg id "$PLUGIN_ID" '
            .[$id] = [.[$id][] | select(.scope != "user")] |
            if .[$id] | length == 0 then del(.[$id]) else . end
        ' "$INSTALLED_PLUGINS")
    else
        new_json=$(jq --arg id "$PLUGIN_ID" --arg sc "$target_scope" --arg pp "$target_pp" '
            .[$id] = [.[$id][] | select(.scope != $sc or .projectPath != $pp)] |
            if .[$id] | length == 0 then del(.[$id]) else . end
        ' "$INSTALLED_PLUGINS")
    fi
    write_json "$INSTALLED_PLUGINS" "$new_json"
    info "Removed $target_scope entry from registry"

    # Remove from settings
    local settings_file
    settings_file=$(settings_file_for_scope "$target_scope" "${target_pp:-$HOME}")
    if [[ -f "$settings_file" ]]; then
        local has_key
        has_key=$(jq -r --arg id "$PLUGIN_ID" '.enabledPlugins | has($id)' "$settings_file" 2>/dev/null || echo "false")
        if [[ "$has_key" == "true" ]]; then
            backup_file "$settings_file"
            new_json=$(jq --arg id "$PLUGIN_ID" 'del(.enabledPlugins[$id])' "$settings_file")
            write_json "$settings_file" "$new_json"
            info "Removed from enabledPlugins in $settings_file"
        fi
    fi
    echo ""
    info "Done. Run /reload-plugins in Claude Code (or restart) to apply."
}

# ═══════════════════════════════════════════════════════════════════════
# COMMAND: clean
# ═══════════════════════════════════════════════════════════════════════

cmd_clean() {
    acquire_lock
    echo ""
    echo "Scanning for cleanable entries..."
    echo ""

    local cleaned=0

    # 1. Orphaned project paths
    echo "── Orphaned project entries ──"
    local orphans
    orphans=$(jq -r '
        to_entries[] | .key as $k | .value[] |
        select(.scope == "project" or .scope == "local") |
        select(.projectPath != null) |
        "\($k)\t\(.scope)\t\(.projectPath)"
    ' "$INSTALLED_PLUGINS")

    local orphan_found=false
    if [[ -n "$orphans" ]]; then
        while IFS=$'\t' read -r pid scope ppath; do
            [[ -z "$pid" ]] && continue
            if [[ ! -d "$ppath" ]]; then
                warn "ORPHAN: $pid (scope=$scope, path=$ppath)"
                orphan_found=true
            fi
        done <<< "$orphans"
    fi
    $orphan_found || info "No orphaned entries"

    # 2. Stale user settings
    echo ""
    echo "── Stale user settings entries ──"
    local stale_user_found=false
    if [[ -f "$USER_SETTINGS" ]]; then
        local enabled_plugins
        enabled_plugins=$(jq -r '.enabledPlugins // {} | keys[]' "$USER_SETTINGS" 2>/dev/null || true)
        if [[ -n "$enabled_plugins" ]]; then
            while IFS= read -r pid; do
                [[ -z "$pid" ]] && continue
                local has_entry
                has_entry=$(jq -r --arg id "$pid" 'has($id)' "$INSTALLED_PLUGINS")
                if [[ "$has_entry" != "true" ]]; then
                    warn "STALE: $pid in user enabledPlugins but not in registry"
                    stale_user_found=true
                fi
            done <<< "$enabled_plugins"
        fi
    fi
    $stale_user_found || info "No stale user settings entries"

    # 3. Duplicates
    echo ""
    echo "── Duplicates ──"
    local dedup_found=false
    local all_plugins
    all_plugins=$(jq -r 'keys[]' "$INSTALLED_PLUGINS")
    if [[ -n "$all_plugins" ]]; then
        while IFS= read -r pid; do
            [[ -z "$pid" ]] && continue
            local count unique_count
            count=$(jq -r --arg id "$pid" '.[$id] | length' "$INSTALLED_PLUGINS")
            unique_count=$(jq -r --arg id "$pid" '.[$id] | unique_by(.scope, .projectPath) | length' "$INSTALLED_PLUGINS")
            [[ "$count" -ne "$unique_count" ]] && { warn "DUPES: $pid ($count → $unique_count)"; dedup_found=true; }
        done <<< "$all_plugins"
    fi
    $dedup_found || info "No duplicates"

    if ! $orphan_found && ! $stale_user_found && ! $dedup_found; then
        echo ""; info "Nothing to clean."; return 0
    fi

    echo ""
    if ! confirm "Clean all of the above?"; then echo "Aborted."; exit 0; fi
    if $DRY_RUN; then dry "Would clean orphans, stale entries, and duplicates"; return 0; fi

    # Execute: dedup first
    backup_file "$INSTALLED_PLUGINS"
    local new_json
    new_json=$(jq 'to_entries | map(.value |= unique_by(.scope, .projectPath)) | from_entries' "$INSTALLED_PLUGINS")

    # Remove orphans
    if $orphan_found; then
        while IFS=$'\t' read -r pid scope ppath; do
            [[ -z "$pid" ]] && continue
            [[ -d "$ppath" ]] && continue
            new_json=$(echo "$new_json" | jq --arg id "$pid" --arg sc "$scope" --arg pp "$ppath" '
                if has($id) then
                    .[$id] = [.[$id][] | select(.scope != $sc or .projectPath != $pp)] |
                    if .[$id] | length == 0 then del(.[$id]) else . end
                else . end
            ')
            : $((cleaned += 1))
        done <<< "$orphans"
    fi

    write_json "$INSTALLED_PLUGINS" "$new_json"
    info "Cleaned registry"

    # Clean stale user settings
    if $stale_user_found && [[ -f "$USER_SETTINGS" ]]; then
        backup_file "$USER_SETTINGS"
        local reg_keys
        reg_keys=$(jq -r 'keys[]' "$INSTALLED_PLUGINS" | jq -R -s 'split("\n") | map(select(length > 0))')
        new_json=$(jq --argjson valid_keys "$reg_keys" '
            .enabledPlugins //= {} |
            .enabledPlugins = (
                .enabledPlugins | to_entries |
                map(select(.key as $k | $valid_keys | any(. == $k))) |
                from_entries
            )
        ' "$USER_SETTINGS")
        write_json "$USER_SETTINGS" "$new_json"
        info "Cleaned user settings"
        : $((cleaned += 1))
    fi
    $dedup_found && : $((cleaned += 1))

    echo ""
    info "Cleaned $cleaned category(s). Run /reload-plugins to apply."
}

# ═══════════════════════════════════════════════════════════════════════
# COMMAND: list
# ═══════════════════════════════════════════════════════════════════════

cmd_list() {
    if [[ -n "${PLUGIN_ID:-}" ]]; then
        local entries
        entries=$(jq -r --arg id "$PLUGIN_ID" '.[$id] // empty' "$INSTALLED_PLUGINS")
        [[ -z "$entries" ]] && { error "Plugin '$PLUGIN_ID' not found in registry."; exit 1; }
        echo ""
        echo "Entries for $PLUGIN_ID:"
        jq -r --arg id "$PLUGIN_ID" '
            .[$id][] | "  scope=\(.scope)  projectPath=\(.projectPath // "n/a")  version=\(.version // "?")  installedAt=\(.installedAt // "?")"
        ' "$INSTALLED_PLUGINS"
    else
        echo ""
        echo "All registered plugins:"
        jq -r '
            to_entries[] | .key as $k | .value[] |
            "  \($k)  scope=\(.scope)  projectPath=\(.projectPath // "n/a")"
        ' "$INSTALLED_PLUGINS"
    fi
}

# ═══════════════════════════════════════════════════════════════════════
# COMMAND: status
# ═══════════════════════════════════════════════════════════════════════

cmd_status() {
    ensure_plugin_arg; resolve_project_path

    local entries
    entries=$(jq -r --arg id "$PLUGIN_ID" '.[$id] // empty' "$INSTALLED_PLUGINS")
    [[ -z "$entries" ]] && { error "Plugin '$PLUGIN_ID' not found in registry."; exit 1; }

    local canonical_pp
    canonical_pp="$(canonical_path "$PROJECT_PATH")"

    echo ""
    echo "Plugin: $PLUGIN_ID"
    echo "Current project: $PROJECT_PATH"
    [[ "$canonical_pp" != "$PROJECT_PATH" ]] && echo "Canonical path:  $canonical_pp"
    echo ""
    echo "Registry entries:"
    jq -r --arg id "$PLUGIN_ID" '
        .[$id][] | "  scope=\(.scope)  projectPath=\(.projectPath // "n/a")  version=\(.version // "?")"
    ' "$INSTALLED_PLUGINS"

    # Check availability (canonical path)
    local available
    available=$(jq -r --arg id "$PLUGIN_ID" --arg pp "$canonical_pp" '
        .[$id] // [] | any(.scope == "user" or .scope == "managed" or
        ((.scope == "project" or .scope == "local") and .projectPath == $pp))
    ' "$INSTALLED_PLUGINS")

    # Try original path too
    if [[ "$available" != "true" && "$canonical_pp" != "$PROJECT_PATH" ]]; then
        available=$(jq -r --arg id "$PLUGIN_ID" --arg pp "$PROJECT_PATH" '
            .[$id] // [] | any(.scope == "user" or .scope == "managed" or
            ((.scope == "project" or .scope == "local") and .projectPath == $pp))
        ' "$INSTALLED_PLUGINS")
    fi

    # Worktree check
    if [[ "$available" != "true" ]] && command -v git &>/dev/null; then
        local my_common
        my_common=$(git_common_dir "$canonical_pp")
        if [[ -n "$my_common" ]]; then
            local wt_paths
            wt_paths=$(jq -r --arg id "$PLUGIN_ID" '
                .[$id] // [] | map(select(.scope == "project" or .scope == "local") | .projectPath // empty) | .[]
            ' "$INSTALLED_PLUGINS")
            if [[ -n "$wt_paths" ]]; then
                while IFS= read -r pp; do
                    [[ -z "$pp" || ! -d "$pp" ]] && continue
                    local their_common
                    their_common=$(git_common_dir "$pp")
                    if [[ "$their_common" == "$my_common" && "$pp" != "$canonical_pp" ]]; then
                        echo ""
                        warn "Plugin is registered for a different worktree of the same repo:"
                        echo "  Registered: $pp"
                        echo "  Current:    $canonical_pp"
                        echo "  Shared git: $my_common"
                    fi
                done <<< "$wt_paths"
            fi
        fi
    fi

    echo ""
    if [[ "$available" == "true" ]]; then
        info "Plugin IS available in current project"
    else
        warn "Plugin is NOT available in current project"
        echo "  The UI will show it as 'Installed' but it won't load."
        echo "  Fix with: $(basename "$0") promote $PLUGIN_ID"
        echo "       or:  $(basename "$0") add $PLUGIN_ID --scope project"
    fi

    echo ""
    echo "Settings files:"
    for sf in "$USER_SETTINGS" \
              "${PROJECT_PATH}/.claude/settings.json" \
              "${PROJECT_PATH}/.claude/settings.local.json"; do
        if [[ -f "$sf" ]]; then
            local enabled
            enabled=$(jq -r --arg id "$PLUGIN_ID" '.enabledPlugins[$id] // "not set"' "$sf")
            local marker=""
            [[ "$enabled" == "false" ]] && marker=" ${RED}(explicitly disabled)${NC}"
            echo -e "  $sf → enabledPlugins: $enabled$marker"
        else
            echo "  $sf → (file does not exist)"
        fi
    done
    if [[ -n "$MANAGED_SETTINGS" && -f "$MANAGED_SETTINGS" ]]; then
        local mgd
        mgd=$(jq -r --arg id "$PLUGIN_ID" '.enabledPlugins[$id] // "not set"' "$MANAGED_SETTINGS" 2>/dev/null || echo "not set")
        echo "  $MANAGED_SETTINGS → enabledPlugins: $mgd (managed)"
    fi
}

# ═══════════════════════════════════════════════════════════════════════
# COMMAND: dedup
# ═══════════════════════════════════════════════════════════════════════

cmd_dedup() {
    acquire_lock

    # If no plugin specified, dedup all
    if [[ -z "${PLUGIN_ID:-}" ]]; then
        echo ""; echo "Scanning all plugins for duplicates..."
        local any_dupes=false
        local all_plugins
        all_plugins=$(jq -r 'keys[]' "$INSTALLED_PLUGINS")
        while IFS= read -r pid; do
            [[ -z "$pid" ]] && continue
            local count unique_count
            count=$(jq -r --arg id "$pid" '.[$id] | length' "$INSTALLED_PLUGINS")
            unique_count=$(jq -r --arg id "$pid" '.[$id] | unique_by(.scope, .projectPath) | length' "$INSTALLED_PLUGINS")
            if [[ "$count" -ne "$unique_count" ]]; then
                warn "$pid: $((count - unique_count)) duplicate(s) ($count → $unique_count)"
                any_dupes=true
            fi
        done <<< "$all_plugins"

        if ! $any_dupes; then info "No duplicates found across any plugins."; return 0; fi
        echo ""
        if ! confirm "Remove all duplicates?"; then echo "Aborted."; exit 0; fi
        if $DRY_RUN; then dry "Would deduplicate all plugins"; return 0; fi

        backup_file "$INSTALLED_PLUGINS"
        local new_json
        new_json=$(jq 'to_entries | map(.value |= unique_by(.scope, .projectPath)) | from_entries' "$INSTALLED_PLUGINS")
        write_json "$INSTALLED_PLUGINS" "$new_json"
        info "Deduplicated all plugins."
        return 0
    fi

    ensure_plugin_arg

    local count
    count=$(jq -r --arg id "$PLUGIN_ID" '.[$id] // [] | length' "$INSTALLED_PLUGINS")
    [[ "$count" == "0" ]] && { error "Plugin '$PLUGIN_ID' not found in registry."; exit 1; }

    local unique_count
    unique_count=$(jq -r --arg id "$PLUGIN_ID" '.[$id] // [] | unique_by(.scope, .projectPath) | length' "$INSTALLED_PLUGINS")
    if [[ "$count" == "$unique_count" ]]; then info "No duplicates found for '$PLUGIN_ID' ($count entries)"; exit 0; fi

    local dupes=$((count - unique_count))
    warn "Found $dupes duplicate(s) for '$PLUGIN_ID' ($count entries → $unique_count unique)"
    if ! confirm "Remove duplicates?"; then echo "Aborted."; exit 0; fi
    if $DRY_RUN; then dry "Would deduplicate entries"; return 0; fi

    backup_file "$INSTALLED_PLUGINS"
    local new_json
    new_json=$(jq --arg id "$PLUGIN_ID" '.[$id] = (.[$id] | unique_by(.scope, .projectPath))' "$INSTALLED_PLUGINS")
    write_json "$INSTALLED_PLUGINS" "$new_json"
    info "Deduplicated: $count → $unique_count entries"
}

# ═══════════════════════════════════════════════════════════════════════
# Argument Parsing
# ═══════════════════════════════════════════════════════════════════════

COMMAND=""
PLUGIN_ID=""

parse_args() {
    [[ $# -eq 0 ]] && usage

    COMMAND="$1"; shift
    [[ "$COMMAND" == "-h" || "$COMMAND" == "--help" ]] && usage

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --scope)       SCOPE="$2"; shift 2 ;;
            --project-path) PROJECT_PATH="$2"; shift 2 ;;
            --fix)         FIX_MODE=true; AUTO_YES=true; shift ;;
            --dry-run)     DRY_RUN=true; shift ;;
            --no-backup)   NO_BACKUP=true; shift ;;
            --no-lock)     NO_LOCK=true; shift ;;
            -y|--yes)      AUTO_YES=true; shift ;;
            -h|--help)     usage ;;
            -*)            error "Unknown option: $1"; exit 1 ;;
            *)
                if [[ -z "$PLUGIN_ID" ]]; then PLUGIN_ID="$1"
                else error "Unexpected argument: $1"; exit 1; fi
                shift ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════════

main() {
    parse_args "$@"
    require_jq
    ensure_installed_plugins

    case "$COMMAND" in
        doctor)  cmd_doctor ;;
        promote) cmd_promote ;;
        add)     cmd_add ;;
        remove)  cmd_remove ;;
        clean)   cmd_clean ;;
        list)    cmd_list ;;
        status)  cmd_status ;;
        dedup)   cmd_dedup ;;
        *)
            error "Unknown command: $COMMAND"
            echo "  Valid commands: doctor, promote, add, remove, clean, list, status, dedup"
            exit 1 ;;
    esac
}

main "$@"