# claude-gcode-tools

A collection of [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugins for AI-assisted development workflows.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Included Plugins](#included-plugins)
- [Understanding Scopes](#understanding-scopes)
- [Install via npx skills (Alternative)](#install-via-npx-skills-alternative)
- [Recommended Extras](#recommended-extras)
- [Managing & Updating](#managing--updating)
- [License](#license)

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- [Node.js](https://nodejs.org/) (for `npx skills` commands)

Some recommended extras have additional dependencies — these are noted per item.

## Quick Start

```bash
claude plugin marketplace add greglamb/claude-gcode-tools
claude plugin install goodvibes-workflow@claude-gcode-tools
```

## Included Plugins

| Plugin                                                     | Description                                                                                                                                                 |
|------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [goodvibes-workflow](plugins/goodvibes-workflow/README.md) | Structured development workflow with commands, skills, hooks, and documentation conventions                                                                 |
| vscode-api                                                 | VS Code Extension API documentation — commands, webviews, tree views, language features, activation events, contribution points, and the extension manifest |
| fish-shell                                                 | Fish shell (v4.0.2) documentation — scripting, configuration, syntax, and bash migration                                                                    |
| gas-typescript                                             | Best practices, patterns, and toolchain for Google Apps Script projects using TypeScript, Rollup, and clasp                                                 |
| project-documentation                                      | Documentation framework that resists decay — ADRs, conceptual guides, README templates, domain guides, and CLAUDE.md guidance                               |
| presentation-design                                        | Tool-agnostic slide presentation design — storytelling frameworks, color palettes, typography, layout patterns, and data visualization                      |

### Installation

First, add the marketplace (only needed once):

```bash
claude plugin marketplace add greglamb/claude-gcode-tools
```

Then install the plugins you want:

```bash
claude plugin install goodvibes-workflow@claude-gcode-tools
```

```bash
claude plugin install vscode-api@claude-gcode-tools
```

```bash
claude plugin install fish-shell@claude-gcode-tools
```

```bash
claude plugin install gas-typescript@claude-gcode-tools
```

```bash
claude plugin install project-documentation@claude-gcode-tools
```

```bash
claude plugin install presentation-design@claude-gcode-tools
```

## Understanding Scopes

Plugins and skills each have their own scope system that controls where they're installed. The defaults are **opposite** — be aware of this when mixing both systems.

### Plugin Scopes (`claude plugin install`)

| Scope       | Flag              | Location                  | Use Case                                      |
|-------------|-------------------|---------------------------|-----------------------------------------------|
| **User**    | _(default)_       | `~/.claude/settings.json` | Available across all projects                 |
| **Project** | `--scope project` | `.claude/settings.json`   | Committed with your project, shared with team |

```bash
# Example: install a plugin at project scope instead of the default user scope
claude plugin install vscode-api@claude-gcode-tools --scope project
```

### npx skills Scopes (`npx skills add`)

| Scope       | Flag        | Location            | Use Case                                      |
|-------------|-------------|---------------------|-----------------------------------------------|
| **Project** | _(default)_ | `.claude/skills/`   | Committed with your project, shared with team |
| **User**    | `-g`        | `~/.claude/skills/` | Available across all projects                 |

```bash
# Example: install a skill at user scope instead of the default project scope
npx skills add owner/repo -a claude-code -g
```

### Recommendation

> **As of March 2026**, scoped plugin usage in Claude Code is still buggy — installing plugins at project scope can lead to issues where they appear "installed" but aren't available, or can't be reinstalled at a different scope without manual edits to `installed_plugins.json`.
>
> **My recommendation:** Keep **marketplaces and plugins at user scope** (the default) and use **Vercel's `npx skills` at project scope** (also the default) when you want repo-level, team-shared configuration. Both defaults just work.

## Install via npx skills (Alternative)

Five of the six included plugins are also available as standalone skills via Vercel's [`skills` CLI](https://github.com/vercel-labs/skills). This is useful if you don't need the full marketplace, want to install individual skills outside the plugin system, or want project-scoped installation that works reliably.

> **Note:** goodvibes-workflow uses hooks, which are only supported via the plugin marketplace — it cannot be installed via npx skills.

```bash
npx skills add https://github.com/greglamb/claude-gcode-tools/tree/main/plugins/vscode-api/skills/vscode-api -a claude-code
```

```bash
npx skills add https://github.com/greglamb/claude-gcode-tools/tree/main/plugins/fish-shell/skills/fish-shell -a claude-code
```

```bash
npx skills add https://github.com/greglamb/claude-gcode-tools/tree/main/plugins/gas-typescript/skills/gas-typescript -a claude-code
```

```bash
npx skills add https://github.com/greglamb/claude-gcode-tools/tree/main/plugins/project-documentation/skills/project-documentation -a claude-code
```

```bash
npx skills add https://github.com/greglamb/claude-gcode-tools/tree/main/plugins/presentation-design/skills/presentation-design -a claude-code
```

Browse more community skills at [skills.sh](https://skills.sh).

## Recommended Extras

Plugins, skills, and tools from other sources that pair well with this marketplace. Items marked with 🔌 are plugins (installed via `claude plugin install`). Items marked with 🧩 are skills (installed via `npx skills add`).

### General Plugins

<details>
<summary>🔌 <strong>superpowers</strong> — Extended planning, brainstorming, TDD, code review, and verification capabilities</summary>

Requires adding the third-party marketplace first (one-time setup):

```bash
claude plugin marketplace add obra/superpowers-marketplace
claude plugin install superpowers@superpowers-marketplace
```

</details>

<details>
<summary>🔌 <strong>episodic-memory</strong> — Persistent context and conversation recall across Claude Code sessions</summary>

From the same marketplace as superpowers (one-time setup if not already added):

```bash
claude plugin marketplace add obra/superpowers-marketplace
claude plugin install episodic-memory@superpowers-marketplace
```

</details>

<details>
<summary>🔌 <strong>skill-creator</strong> — Create, modify, and optimize Claude Code skills</summary>

Available from the built-in official marketplace — no marketplace setup needed.

```bash
claude plugin install skill-creator@claude-plugins-official
```

</details>

<details>
<summary>🔌 <strong>skill-seekers</strong> — Create AI skills from documentation, repos, and other sources</summary>

Requires [Skill Seekers](https://github.com/yusufkaraaslan/Skill_Seekers) (`pipx install skill-seekers[mcp]` or `brew install skill-seekers`).

```bash
claude plugin install skill-seekers@claude-plugin-directory
```

</details>

### General Skills

<details>
<summary>🧩 <strong>Google Workspace CLI</strong> — CLI tools for Google Workspace APIs (Drive, Gmail, Calendar, Sheets, Docs, Chat, Admin)</summary>

Requires the [`gws` CLI](https://github.com/googleworkspace/cli) (`npm install -g @googleworkspace/cli` or `brew install googleworkspace-cli`), a [Google Cloud project](https://console.cloud.google.com/) with OAuth credentials, and authentication via `gws auth setup` + `gws auth login`. See the [gws README](https://github.com/googleworkspace/cli#authentication) for full setup instructions.

```bash
npx skills add https://github.com/googleworkspace/cli -a claude-code
```

</details>

<details>
<summary>🧩 <strong>Draw.io Diagrams</strong> — Generate native draw.io diagrams from natural language, with optional PNG/SVG/PDF export</summary>

Requires [draw.io Desktop](https://github.com/jgraph/drawio-desktop) for PNG/SVG/PDF export (optional — diagram generation works without it).

```bash
npx skills add https://github.com/jgraph/drawio-mcp/tree/main/skill-cli/drawio -a claude-code
```

</details>

<details>
<summary>🔌 <strong>PPTX (PowerPoint)</strong> — Create, read, edit, and convert PowerPoint presentations</summary>

Requires `pipx install "markitdown[pptx]"`, `pipx install Pillow`, and `npm install -g pptxgenjs`. LibreOffice optional for PDF conversion.

```bash
claude plugin marketplace add anthropics/skills
claude plugin install document-skills@anthropic-agent-skills
```

</details>

### Swift / Apple Development

<details>
<summary>🧩 <strong>SwiftUI Agent Skill</strong> — Better SwiftUI code with guidance on API usage, design, performance, and accessibility</summary>

No additional dependencies — pure instruction skill.

```bash
npx skills add twostraws/SwiftUI-Agent-Skill -a claude-code
```

</details>

<details>
<summary>🧩 <strong>SwiftData Agent Skill</strong> — Targets common LLM mistakes in SwiftData model definitions, queries, predicates, indexes, migrations, and iCloud sync</summary>

No additional dependencies — pure instruction skill.

```bash
npx skills add twostraws/SwiftData-Agent-Skill -a claude-code
```

</details>

<details>
<summary>🧩 <strong>Swift Concurrency Agent Skill</strong> — Targets common LLM mistakes in async/await, actors, Sendable, and structured concurrency patterns</summary>

No additional dependencies — pure instruction skill.

```bash
npx skills add twostraws/Swift-Concurrency-Agent-Skill -a claude-code
```

</details>

<details>
<summary>🧩 <strong>Swift Testing Agent Skill</strong> — Improves Swift test code with <code>@Test</code>, <code>#expect</code>, parameterized testing, and traits</summary>

No additional dependencies — pure instruction skill.

```bash
npx skills add twostraws/Swift-Testing-Agent-Skill -a claude-code
```

</details>

<details>
<summary>🧩 <strong>Swift API Design Guidelines</strong> — Naming, argument labels, terminology, and conventions aligned with Apple's guidelines</summary>

No additional dependencies — pure instruction skill.

```bash
npx skills add Erikote04/Swift-API-Design-Guidelines-Agent-Skill -a claude-code
```

</details>

<details>
<summary>🧩 <strong>Swift Architecture Skill</strong> — Routes to the right design pattern based on your feature's needs</summary>

No additional dependencies — pure instruction skill.

```bash
npx skills add efremidze/swift-architecture-skill -a claude-code
```

</details>

<details>
<summary>🧩 <strong>Swift Security Skill</strong> — Secure credential storage, biometric auth, and cryptography using Keychain Services and CryptoKit</summary>

No additional dependencies — pure instruction skill.

```bash
npx skills add ivan-magda/swift-security-skill -a claude-code
```

</details>

<details>
<summary>🧩 <strong>SwiftUI Performance Audit</strong> — Identifies and resolves performance issues in SwiftUI applications</summary>

No additional dependencies — pure instruction skill.

```bash
npx skills add Dimillian/Skills --skill swiftui-performance-audit -a claude-code
```

</details>

<details>
<summary>🧩 <strong>iOS Simulator Skill</strong> — Automation toolkit for building, testing, and interacting with iOS apps</summary>

Requires macOS, Xcode (with `xcrun simctl`), and Python 3. [Facebook's idb](https://fbidb.io/) is optional but recommended for advanced UI automation. Run `bash scripts/sim_health_check.sh` after install to verify your environment.

```bash
npx skills add conorluddy/ios-simulator-skill -a claude-code
```

</details>

<details>
<summary>🧩 <strong>Writing for Interfaces</strong> — Reviews UI copy for clarity, purpose, and consistency</summary>

No additional dependencies — pure instruction skill.

```bash
npx skills add andrewgleave/skills --skill writing-for-interfaces -a claude-code
```

</details>

## Managing & Updating

### Marketplaces

```bash
# List configured marketplaces
claude plugin marketplace list

# Update a marketplace catalog
claude plugin marketplace update claude-gcode-tools

# Remove a marketplace (also uninstalls its plugins)
claude plugin marketplace remove claude-gcode-tools
```

Auto-update is available but **disabled by default for third-party marketplaces**. To enable it, open the `/plugin` UI in Claude Code, navigate to the Marketplaces tab, and select "Enable auto-update." When enabled, Claude Code refreshes marketplace data and updates installed plugins at startup.

### Plugins

```bash
# Disable a plugin without uninstalling
claude plugin disable plugin-name@marketplace-name

# Re-enable a disabled plugin
claude plugin enable plugin-name@marketplace-name

# Uninstall a plugin
claude plugin uninstall plugin-name@marketplace-name
```

> **Note:** As of March 2026, there is no `claude plugin upgrade` command. Plugin updates depend on marketplace auto-update or manually uninstalling and reinstalling. If auto-update doesn't pick up changes, the workaround is to delete the cached plugin from `~/.claude/plugins/cache/` and its entry in `~/.claude/plugins/installed_plugins.json`, then reinstall.

### npx skills

```bash
# Check if installed skills have updates available
npx skills check

# Update all installed skills to latest versions
npx skills update

# Remove a specific skill
npx skills remove skill-name -a claude-code

# Remove interactively (select from installed)
npx skills remove
```

## License

MIT