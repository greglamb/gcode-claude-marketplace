#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXTENSION="${1:?Usage: updatePlugin.sh <extension-name>}"
"$ROOT/scripts/projects/bumpCalver.sh" "$ROOT/plugins/$EXTENSION/.claude-plugin/plugin.json" "version"
