#!/usr/bin/env bash
set -euo pipefail

# Adds the greglamb/claude-gcode-tools and enables the goodvibes-workflow
# plugin in the current project's .claude/settings.json.
#
# Usage: ./vibePrepareProject.sh [project-root]
#   project-root defaults to current directory

MARKETPLACE_NAME="claude-gcode-tools"
MARKETPLACE_REPO="greglamb/claude-gcode-tools"
PLUGIN_NAME="goodvibes-workflow"

PROJECT_ROOT="${1:-.}"
SETTINGS_DIR="${PROJECT_ROOT}/.claude"
SETTINGS_FILE="${SETTINGS_DIR}/settings.json"

# Require jq
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed." >&2
  echo "  brew install jq  (macOS)" >&2
  echo "  sudo apt install jq  (Linux)" >&2
  exit 1
fi

# Create .claude directory if needed
mkdir -p "${SETTINGS_DIR}"

# Seed empty settings if file doesn't exist
if [[ ! -f "${SETTINGS_FILE}" ]]; then
  echo "{}" > "${SETTINGS_FILE}"
fi

# Validate existing JSON
if ! jq empty "${SETTINGS_FILE}" 2>/dev/null; then
  echo "Error: ${SETTINGS_FILE} contains invalid JSON." >&2
  exit 1
fi

# Add extraKnownMarketplaces entry (preserves existing entries)
jq --arg name "${MARKETPLACE_NAME}" \
   --arg repo "${MARKETPLACE_REPO}" \
   '.extraKnownMarketplaces[$name] = {
      "source": {
        "source": "github",
        "repo": $repo
      }
    }' "${SETTINGS_FILE}" > "${SETTINGS_FILE}.tmp"

# Enable the plugin (preserves existing enabled plugins)
jq --arg plugin "${PLUGIN_NAME}@${MARKETPLACE_NAME}" \
   '.enabledPlugins[$plugin] = true' "${SETTINGS_FILE}.tmp" > "${SETTINGS_FILE}"

rm -f "${SETTINGS_FILE}.tmp"

# Final validation
if ! jq empty "${SETTINGS_FILE}" 2>/dev/null; then
  echo "Error: Generated invalid JSON. Check ${SETTINGS_FILE}" >&2
  exit 1
fi

echo "✔ Updated ${SETTINGS_FILE}"
echo "  Marketplace: ${MARKETPLACE_REPO}"
echo "  Plugin:      ${PLUGIN_NAME}@${MARKETPLACE_NAME} (enabled)"
echo ""
echo "Next steps:"
echo "  1. Commit .claude/settings.json"
echo "  2. Open the project in Claude Code"
echo "  3. Trust the folder when prompted — marketplace and plugin install automatically"