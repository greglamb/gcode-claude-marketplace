#!/bin/bash
# Worktree Safety Gate - PreToolUse hook for Bash
# Blocks `git worktree add` if there are uncommitted changes.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only check commands that create worktrees
if ! echo "$COMMAND" | grep -qE 'git\s+worktree\s+add'; then
  exit 0
fi

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
if [ -n "$CWD" ]; then
  cd "$CWD" || exit 0
fi

# Check for uncommitted changes
STATUS=$(git status --porcelain 2>/dev/null)
if [ -n "$STATUS" ]; then
  echo "BLOCKED: Working tree has uncommitted changes. Commit them before creating a worktree." >&2
  echo "Uncommitted files on the source branch will be silently orphaned during worktree operations." >&2
  echo "" >&2
  echo "Dirty files:" >&2
  echo "$STATUS" >&2
  exit 2
fi

exit 0
