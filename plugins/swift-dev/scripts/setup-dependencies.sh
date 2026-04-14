#!/usr/bin/env bash
set -euo pipefail

# Installs external dependencies for the swift-dev plugin.
# Called by /swift-dev:init. Can also be run standalone.
#
# Installs:
#   1. XcodeBuildMCP CLI (Homebrew)
#   2. XcodeBuildMCP CLI skill (npx skills)
#   3. Axiom plugin (claude plugin)
#   4. Paul Hudson's Pro skills (npx skills)
#   5. Swift Architecture Skill (npx skills)
#   6. Writing for Interfaces skill (npx skills)

echo "=== swift-dev: Installing dependencies ===" >&2

# --- XcodeBuildMCP CLI (optional) ---
if command -v xcodebuildmcp &>/dev/null; then
  echo "  ✅ xcodebuildmcp CLI detected — structured build output and UI automation available" >&2
  # Install the CLI skill so Claude knows the xcodebuildmcp command interface
  echo "  📦 Installing XcodeBuildMCP CLI skill..." >&2
  npx skills add getsentry/XcodeBuildMCP --skill xcodebuildmcp-cli -a claude-code -y 2>/dev/null && \
    echo "  ✅ XcodeBuildMCP CLI skill installed" >&2 || \
    echo "  ⚠️  Skill install failed. Try: npx skills add getsentry/XcodeBuildMCP --skill xcodebuildmcp-cli -a claude-code" >&2
else
  echo "  ℹ️  xcodebuildmcp CLI not installed (optional)." >&2
  echo "     The plugin works with native xcodebuild and xcrun simctl." >&2
  echo "     XcodeBuildMCP adds: structured JSON errors, UI automation, accessibility tree, LLDB debugging." >&2
  echo "     Install with: brew tap getsentry/xcodebuildmcp && brew install xcodebuildmcp" >&2
fi

# --- Axiom plugin ---
# Cannot reliably install plugins from within a running Claude Code session.
# Check if it's already installed, otherwise instruct the user.
if claude plugin list 2>/dev/null | grep -qi axiom; then
  echo "  ✅ Axiom plugin already installed" >&2
else
  echo "  ℹ️  Axiom plugin not detected. Install it after this session:" >&2
  echo "     claude plugin marketplace add CharlesWiltgen/Axiom" >&2
  echo "     claude plugin install axiom@axiom-marketplace" >&2
fi

# --- Hudson Pro skills ---
SKILLS=(
  "twostraws/SwiftUI-Agent-Skill"
  "twostraws/SwiftData-Agent-Skill"
  "twostraws/Swift-Concurrency-Agent-Skill"
  "twostraws/Swift-Testing-Agent-Skill"
)

HUDSON_FAILURES=0
for skill in "${SKILLS[@]}"; do
  echo "  📦 Installing: $skill" >&2
  npx skills add "$skill" -a claude-code -y 2>/dev/null || {
    echo "  ⚠️  Failed: $skill" >&2
    HUDSON_FAILURES=$((HUDSON_FAILURES + 1))
  }
done
if [ "$HUDSON_FAILURES" -eq 0 ]; then
  echo "  ✅ Hudson Pro skills installed" >&2
else
  echo "  ⚠️  ${HUDSON_FAILURES} Hudson Pro skill(s) failed — install manually with npx skills add" >&2
fi

# --- Architecture skill ---
echo "  📦 Installing Swift Architecture Skill..." >&2
npx skills add efremidze/swift-architecture-skill -a claude-code -y 2>/dev/null && \
  echo "  ✅ Architecture skill installed" >&2 || \
  echo "  ⚠️  Failed. Try: npx skills add efremidze/swift-architecture-skill -a claude-code" >&2

# --- Writing for Interfaces ---
echo "  📦 Installing Writing for Interfaces skill..." >&2
npx skills add andrewgleave/skills --skill writing-for-interfaces -a claude-code -y 2>/dev/null && \
  echo "  ✅ Writing for Interfaces installed" >&2 || \
  echo "  ⚠️  Failed. Try: npx skills add andrewgleave/skills --skill writing-for-interfaces -a claude-code" >&2

# --- SwiftLint (optional, for post-edit hook) ---
if command -v swiftlint &>/dev/null; then
  echo "  ✅ SwiftLint already installed" >&2
else
  echo "  ℹ️  SwiftLint not installed (optional). The post-edit hook will skip." >&2
  echo "     Install with: brew install swiftlint" >&2
fi

echo "=== swift-dev: Dependencies ready ===" >&2
