#!/bin/bash
# Check Plugin Dependencies - SessionStart hook
# Verifies that required plugins are available.

REQUIRED_PLUGINS=("superpowers" "episodic-memory" "project-standards")
MISSING=()

for plugin in "${REQUIRED_PLUGINS[@]}"; do
  if ! claude plugin list 2>/dev/null | grep -q "$plugin"; then
    MISSING+=("$plugin")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "Missing required plugins: ${MISSING[*]}" >&2
  echo "Install them with:" >&2
  for plugin in "${MISSING[@]}"; do
    echo "  claude plugin add $plugin" >&2
  done
  # Don't block session start, just warn
  exit 0
fi

exit 0
