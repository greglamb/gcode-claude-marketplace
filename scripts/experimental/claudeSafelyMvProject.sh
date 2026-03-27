#!/usr/bin/env bash
# claudeSafelyMvProject — Safely move project directories while preserving
#   Claude Code settings, conversation history, and configuration references.
#
# Usage: claudeSafelyMvProject.sh [OPTIONS] <source> <destination>
#
# Options:
#   -n, --dry-run     Show what would happen without making changes
#   -b, --backup      Create a timestamped backup of Claude state before migrating
#   -f, --force       Allow overwriting destination if it exists
#   -v, --verbose     Show detailed output for each step
#   -h, --help        Show this help message
#
# Examples:
#   claudeSafelyMvProject.sh ~/projects/myapp ~/projects/v2/myapp
#   claudeSafelyMvProject.sh --dry-run --verbose ./old-name ./new-name
#   claudeSafelyMvProject.sh --backup --force /src/app /dest/app

set -euo pipefail

# --------------------------------------------------------------------------- #
# Constants
# --------------------------------------------------------------------------- #
readonly CLAUDE_DIR="$HOME/.claude"
readonly CLAUDE_PROJECTS_DIR="$CLAUDE_DIR/projects"
readonly CLAUDE_USER_CONFIG="$HOME/.claude.json"
readonly CLAUDE_USER_SETTINGS="$CLAUDE_DIR/settings.json"
readonly CLAUDE_USER_LOCAL_SETTINGS="$CLAUDE_DIR/settings.local.json"
readonly VERSION="1.0.0"

# In-project config files that may contain absolute paths
readonly -a PROJECT_CONFIGS=(
  ".claude/settings.json"
  ".claude/settings.local.json"
  ".mcp.json"
)

# --------------------------------------------------------------------------- #
# State
# --------------------------------------------------------------------------- #
DRY_RUN=false
BACKUP=false
FORCE=false
VERBOSE=false
ROLLBACK_ACTIONS=()

# --------------------------------------------------------------------------- #
# Logging
# --------------------------------------------------------------------------- #
_log()    { printf '%s\n' "$1"; }
_info()   { printf '\033[0;36m[INFO]\033[0m  %s\n' "$1"; }
_warn()   { printf '\033[0;33m[WARN]\033[0m  %s\n' "$1" >&2; }
_error()  { printf '\033[0;31m[ERROR]\033[0m %s\n' "$1" >&2; }
_ok()     { printf '\033[0;32m[OK]\033[0m    %s\n' "$1"; }
_detail() { $VERBOSE && printf '         %s\n' "$1" || true; }
_dry()    { printf '\033[0;35m[DRY]\033[0m   %s\n' "$1"; }

# --------------------------------------------------------------------------- #
# Usage
# --------------------------------------------------------------------------- #
usage() {
  sed -n '2,/^$/{ s/^# \?//; p }' "$0"
  exit 0
}

# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #

# Resolve a path to absolute, handling ~, .., symlinks in parent dirs.
# Does NOT require the final component to exist (unlike realpath).
resolve_path() {
  local target="$1"
  # Expand ~ manually since it doesn't expand in variables
  target="${target/#\~/$HOME}"

  if [[ -d "$target" ]]; then
    (cd "$target" && pwd -P)
  elif [[ -d "$(dirname "$target")" ]]; then
    local parent
    parent="$(cd "$(dirname "$target")" && pwd -P)"
    echo "$parent/$(basename "$target")"
  else
    # Parent doesn't exist either — just normalize what we can
    echo "$(cd "$(dirname "$target")" 2>/dev/null && pwd -P || echo "$(dirname "$target")")/$(basename "$target")"
  fi
}

# Encode a path the way Claude Code does: replace / with -
encode_path() {
  echo "$1" | sed 's|/|-|g'
}

# Strip trailing slashes for consistency
strip_trailing_slash() {
  echo "$1" | sed 's|/*$||'
}

# Register a rollback action (executed in reverse order on failure)
register_rollback() {
  ROLLBACK_ACTIONS+=("$1")
}

# Execute rollback on failure
rollback() {
  if [[ ${#ROLLBACK_ACTIONS[@]} -eq 0 ]]; then
    return
  fi
  _warn "Rolling back changes..."
  for (( i=${#ROLLBACK_ACTIONS[@]}-1; i>=0; i-- )); do
    _detail "Rollback: ${ROLLBACK_ACTIONS[$i]}"
    eval "${ROLLBACK_ACTIONS[$i]}" 2>/dev/null || _warn "Rollback step failed: ${ROLLBACK_ACTIONS[$i]}"
  done
  _error "Rollback complete. Original state should be restored."
}

trap 'rc=$?; if [[ $rc -ne 0 ]]; then rollback; fi; exit $rc' EXIT

# --------------------------------------------------------------------------- #
# Validation
# --------------------------------------------------------------------------- #

validate_source() {
  local src="$1"

  if [[ ! -e "$src" ]]; then
    _error "Source does not exist: $src"
    exit 1
  fi

  if [[ -L "$src" ]]; then
    _warn "Source is a symlink. The symlink target will be moved."
    local real
    real="$(realpath "$src")"
    _detail "Symlink resolves to: $real"
    if [[ ! -d "$real" ]]; then
      _error "Symlink target is not a directory: $real"
      exit 1
    fi
  elif [[ ! -d "$src" ]]; then
    _error "Source is not a directory: $src"
    exit 1
  fi

  if [[ ! -r "$src" ]]; then
    _error "Source is not readable: $src"
    exit 1
  fi
}

validate_destination() {
  local dest="$1"

  if [[ -e "$dest" ]]; then
    if $FORCE; then
      _warn "Destination exists and --force specified: $dest"
      if [[ -d "$dest" ]] && [[ "$(ls -A "$dest" 2>/dev/null)" ]]; then
        _warn "Destination directory is NOT empty. Move will place source inside it."
      fi
    else
      _error "Destination already exists: $dest"
      _error "Use --force to overwrite, or choose a different destination."
      exit 1
    fi
  fi

  local parent
  parent="$(dirname "$dest")"
  if [[ ! -d "$parent" ]]; then
    _error "Destination parent directory does not exist: $parent"
    _error "Create it first with: mkdir -p \"$parent\""
    exit 1
  fi

  if [[ ! -w "$parent" ]]; then
    _error "Destination parent is not writable: $parent"
    exit 1
  fi
}

validate_not_same() {
  local src="$1" dest="$2"
  if [[ "$src" == "$dest" ]]; then
    _error "Source and destination are the same path."
    exit 1
  fi
}

validate_not_nested() {
  local src="$1" dest="$2"
  if [[ "$dest" == "$src"/* ]]; then
    _error "Destination is inside source — this would create a recursive move."
    exit 1
  fi
  if [[ "$src" == "$dest"/* ]]; then
    _error "Source is inside destination — this would create a recursive move."
    exit 1
  fi
}

check_cross_device() {
  local src="$1" dest_parent
  dest_parent="$(dirname "$2")"
  local src_dev dest_dev
  src_dev="$(stat -c '%d' "$src" 2>/dev/null || stat -f '%d' "$src" 2>/dev/null)"
  dest_dev="$(stat -c '%d' "$dest_parent" 2>/dev/null || stat -f '%d' "$dest_parent" 2>/dev/null)"
  if [[ "$src_dev" != "$dest_dev" ]]; then
    _warn "Cross-device move detected. This will copy+delete (slower for large projects)."
  fi
}

# --------------------------------------------------------------------------- #
# Claude Code migration steps
# --------------------------------------------------------------------------- #

migrate_projects_dir() {
  local old_abs="$1" new_abs="$2"
  local old_encoded new_encoded
  old_encoded="$(encode_path "$old_abs")"
  new_encoded="$(encode_path "$new_abs")"

  local old_dir="$CLAUDE_PROJECTS_DIR/$old_encoded"
  local new_dir="$CLAUDE_PROJECTS_DIR/$new_encoded"

  if [[ ! -d "$CLAUDE_PROJECTS_DIR" ]]; then
    _detail "No ~/.claude/projects/ directory found — nothing to migrate."
    return 0
  fi

  if [[ ! -d "$old_dir" ]]; then
    _detail "No Claude history found at: $old_dir"
    # Check for partial matches (in case of slight path differences)
    local partial_matches
    partial_matches="$(ls -d "$CLAUDE_PROJECTS_DIR"/*"$(basename "$old_abs")"* 2>/dev/null || true)"
    if [[ -n "$partial_matches" ]]; then
      _warn "No exact match, but found possible related entries:"
      echo "$partial_matches" | while read -r match; do
        _detail "  $match"
      done
    fi
    return 0
  fi

  if [[ -d "$new_dir" ]]; then
    if $FORCE; then
      _warn "Destination Claude history already exists. Merging (existing files preserved)."
      if $DRY_RUN; then
        _dry "Would merge: $old_dir -> $new_dir"
        return 0
      fi
      # Copy only files that don't already exist in destination
      cp -rn "$old_dir/." "$new_dir/" 2>/dev/null || cp -r "$old_dir/." "$new_dir/"
      register_rollback "rm -rf \"$new_dir\""
    else
      _warn "Claude history already exists for the destination path."
      _warn "  Existing: $new_dir"
      _warn "  Use --force to merge."
      return 0
    fi
  else
    if $DRY_RUN; then
      _dry "Would rename: $old_dir -> $new_dir"
      return 0
    fi
    mv "$old_dir" "$new_dir"
    register_rollback "mv \"$new_dir\" \"$old_dir\""
  fi

  _ok "Migrated Claude history: $old_encoded -> $new_encoded"
}

backup_claude_state() {
  local old_abs="$1"
  local old_encoded
  old_encoded="$(encode_path "$old_abs")"
  local old_dir="$CLAUDE_PROJECTS_DIR/$old_encoded"

  if [[ ! -d "$old_dir" ]]; then
    _detail "No Claude history to back up."
    return 0
  fi

  local timestamp
  timestamp="$(date +%Y%m%d_%H%M%S)"
  local backup_dir="$CLAUDE_DIR/backups/${old_encoded}_${timestamp}"

  if $DRY_RUN; then
    _dry "Would back up: $old_dir -> $backup_dir"
    return 0
  fi

  mkdir -p "$(dirname "$backup_dir")"
  cp -r "$old_dir" "$backup_dir"
  _ok "Backed up Claude history to: $backup_dir"
}

# Update absolute path references in a single file
update_paths_in_file() {
  local file="$1" old_abs="$2" new_abs="$3"

  if [[ ! -f "$file" ]]; then
    return 0
  fi

  if ! grep -q "$old_abs" "$file" 2>/dev/null; then
    return 0
  fi

  if $DRY_RUN; then
    _dry "Would update paths in: $file"
    grep -n "$old_abs" "$file" | while read -r line; do
      _detail "  $line"
    done
    return 0
  fi

  # Use a temp file for atomic replacement
  local tmp
  tmp="$(mktemp)"
  sed "s|$old_abs|$new_abs|g" "$file" > "$tmp"

  # Preserve original permissions
  chmod --reference="$file" "$tmp" 2>/dev/null || chmod "$(stat -f '%A' "$file" 2>/dev/null || echo '644')" "$tmp"
  mv "$tmp" "$file"

  _ok "Updated paths in: $file"
}

update_project_configs() {
  local new_project_dir="$1" old_abs="$2" new_abs="$3"

  for config in "${PROJECT_CONFIGS[@]}"; do
    local config_path="$new_project_dir/$config"
    update_paths_in_file "$config_path" "$old_abs" "$new_abs"
  done
}

update_user_configs() {
  local old_abs="$1" new_abs="$2"

  # ~/.claude.json — can contain project-keyed MCP servers and settings
  update_paths_in_file "$CLAUDE_USER_CONFIG" "$old_abs" "$new_abs"

  # ~/.claude/settings.json — user-level settings
  update_paths_in_file "$CLAUDE_USER_SETTINGS" "$old_abs" "$new_abs"

  # ~/.claude/settings.local.json
  update_paths_in_file "$CLAUDE_USER_LOCAL_SETTINGS" "$old_abs" "$new_abs"
}

# Scan for any other references we might have missed
scan_for_orphaned_refs() {
  local old_abs="$1"
  local found=false

  _detail "Scanning for remaining references to old path..."

  # Check all json files in ~/.claude/
  while IFS= read -r -d '' file; do
    if grep -ql "$old_abs" "$file" 2>/dev/null; then
      if ! $found; then
        _warn "Found remaining references to old path in:"
        found=true
      fi
      _warn "  $file"
    fi
  done < <(find "$CLAUDE_DIR" -name '*.json' -print0 2>/dev/null)

  if $found; then
    _warn "You may need to manually update these files."
  fi
}

# --------------------------------------------------------------------------- #
# Summary / report
# --------------------------------------------------------------------------- #

print_summary() {
  local src_abs="$1" dest_abs="$2"
  local old_encoded new_encoded
  old_encoded="$(encode_path "$src_abs")"
  new_encoded="$(encode_path "$dest_abs")"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if $DRY_RUN; then
    echo "  DRY RUN SUMMARY"
  else
    echo "  MIGRATION COMPLETE"
  fi
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Project:    $(basename "$dest_abs")"
  echo "  From:       $src_abs"
  echo "  To:         $dest_abs"
  echo "  History:    $old_encoded -> $new_encoded"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #

main() {
  local positional=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--dry-run)  DRY_RUN=true;  shift ;;
      -b|--backup)   BACKUP=true;   shift ;;
      -f|--force)    FORCE=true;    shift ;;
      -v|--verbose)  VERBOSE=true;  shift ;;
      -h|--help)     usage ;;
      --version)     echo "claudeSafelyMvProject $VERSION"; exit 0 ;;
      --)            shift; positional+=("$@"); break ;;
      -*)            _error "Unknown option: $1"; usage ;;
      *)             positional+=("$1"); shift ;;
    esac
  done

  if [[ ${#positional[@]} -ne 2 ]]; then
    _error "Expected exactly 2 arguments: <source> <destination>"
    echo ""
    usage
  fi

  local src dest
  src="$(strip_trailing_slash "${positional[0]}")"
  dest="$(strip_trailing_slash "${positional[1]}")"

  # ---- Resolve absolute paths ---- #
  local src_abs dest_abs
  src_abs="$(resolve_path "$src")"
  dest_abs="$(resolve_path "$dest")"

  _info "claudeSafelyMvProject $VERSION"
  $DRY_RUN && _info "DRY RUN — no changes will be made."
  echo ""

  # ---- Validate ---- #
  _info "Validating..."
  validate_source "$src_abs"
  validate_destination "$dest_abs"
  validate_not_same "$src_abs" "$dest_abs"
  validate_not_nested "$src_abs" "$dest_abs"
  check_cross_device "$src_abs" "$dest_abs"
  _ok "Validation passed."
  echo ""

  # ---- Backup ---- #
  if $BACKUP; then
    _info "Creating backup..."
    backup_claude_state "$src_abs"
    echo ""
  fi

  # ---- Move the project directory ---- #
  _info "Moving project directory..."
  if $DRY_RUN; then
    _dry "Would move: $src_abs -> $dest_abs"
  else
    mv "$src_abs" "$dest_abs"
    register_rollback "mv \"$dest_abs\" \"$src_abs\""
    _ok "Moved project directory."
  fi
  echo ""

  # ---- Migrate Claude Code history ---- #
  _info "Migrating Claude Code history..."
  migrate_projects_dir "$src_abs" "$dest_abs"
  echo ""

  # ---- Update config files inside the project ---- #
  _info "Updating in-project config files..."
  local effective_dest="$dest_abs"
  update_project_configs "$effective_dest" "$src_abs" "$dest_abs"
  echo ""

  # ---- Update user-level config files ---- #
  _info "Updating user-level config files..."
  update_user_configs "$src_abs" "$dest_abs"
  echo ""

  # ---- Scan for anything we missed ---- #
  if ! $DRY_RUN; then
    scan_for_orphaned_refs "$src_abs"
  fi

  # ---- Summary ---- #
  print_summary "$src_abs" "$dest_abs"

  if $DRY_RUN; then
    _info "Re-run without --dry-run to apply."
  fi
}

main "$@"