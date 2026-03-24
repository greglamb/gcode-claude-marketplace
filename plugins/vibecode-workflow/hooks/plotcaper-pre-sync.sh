#!/bin/bash
# Plotcaper Pre-Sync - PreToolUse hook for Skill
# Automatically runs `episodic-memory sync` before plotcaper executes.

INPUT=$(cat)
SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // empty')

# Only trigger for plotcaper
if [ "$SKILL" != "plotcaper" ]; then
  exit 0
fi

# Run episodic-memory sync
if command -v episodic-memory &>/dev/null; then
  episodic-memory sync 2>&1
else
  echo "Warning: episodic-memory CLI not found. Skipping sync." >&2
fi

exit 0
