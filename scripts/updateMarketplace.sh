#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/scripts/projects/bumpCalver.sh" "$ROOT/.claude-plugin/marketplace.json" "metadata.version"
