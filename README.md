# gcode-claude-marketplace

A collection of [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugins for AI-assisted development workflows.

## Quick Start

```bash
claude plugin marketplace add greglamb/gcode-claude-marketplace
claude plugin install goodvibes-workflow@gcode-claude-marketplace
```

## Included Plugins

| Plugin                                                     | Install                                                                | Description                                                                                                                                                 |
|------------------------------------------------------------|------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [goodvibes-workflow](plugins/goodvibes-workflow/README.md) | `claude plugin install goodvibes-workflow@gcode-claude-marketplace`    | Structured development workflow with commands, skills, hooks, and documentation conventions                                                                 |
| vscode-api                                                 | `claude plugin install vscode-api@gcode-claude-marketplace`            | VS Code Extension API documentation — commands, webviews, tree views, language features, activation events, contribution points, and the extension manifest |
| fish-shell                                                 | `claude plugin install fish-shell@gcode-claude-marketplace`            | Fish shell (v4.0.2) documentation — scripting, configuration, syntax, and bash migration                                                                    |
| gas-typescript                                             | `claude plugin install gas-typescript@gcode-claude-marketplace`        | Best practices, patterns, and toolchain for Google Apps Script projects using TypeScript, Rollup, and clasp                                                 |
| project-documentation                                      | `claude plugin install project-documentation@gcode-claude-marketplace` | Documentation framework that resists decay — ADRs, conceptual guides, README templates, domain guides, and CLAUDE.md guidance                               |
| presentation-design                                        | `claude plugin install presentation-design@gcode-claude-marketplace`   | Tool-agnostic slide presentation design — storytelling frameworks, color palettes, typography, layout patterns, and data visualization                      |

## Recommended Extras

Plugins, skills, and tools from other sources that pair well with this marketplace.

### General Plugins

<details>
<summary><strong>skill-seekers</strong> — Create AI skills from documentation, repos, and other sources</summary>

Requires [Skill Seekers](https://github.com/yusufkaraaslan/Skill_Seekers) to be installed (`pipx install skill-seekers[mcp]` or `brew install skill-seekers`).

```bash
claude plugin install skill-seekers@claude-plugin-directory
```

</details>

### General Skills

<details>
<summary><strong>Google Workspace CLI</strong> — CLI tools for Google Workspace APIs</summary>

```bash
npx skills add https://github.com/googleworkspace/cli
```

</details>

<details>
<summary><strong>Draw.io Diagrams</strong> — Generate native draw.io diagrams from natural language, with optional PNG/SVG/PDF export</summary>

Requires [draw.io Desktop](https://github.com/jgraph/drawio-desktop) for PNG/SVG/PDF export (optional).

```bash
git clone https://github.com/jgraph/drawio-mcp.git /tmp/drawio-mcp && cp -r /tmp/drawio-mcp/skill-cli/drawio .claude/skills/ && rm -rf /tmp/drawio-mcp
```

</details>

### Swift / Apple Development Skills

<details>
<summary><strong>SwiftUI Agent Skill</strong> — Better SwiftUI code with guidance on API usage, design, performance, and accessibility</summary>

```bash
npx skills add https://github.com/twostraws/SwiftUI-Agent-Skill --skill swiftui-pro
```

</details>

<details>
<summary><strong>SwiftData Agent Skill</strong> — Targets common LLM mistakes in SwiftData model definitions, queries, predicates, indexes, migrations, and iCloud sync</summary>

```bash
npx skills add https://github.com/twostraws/SwiftData-Agent-Skill --skill swiftdata-pro
```

</details>

<details>
<summary><strong>Swift Concurrency Agent Skill</strong> — Targets common LLM mistakes in async/await, actors, Sendable, and structured concurrency patterns</summary>

```bash
npx skills add https://github.com/twostraws/Swift-Concurrency-Agent-Skill --skill swift-concurrency-pro
```

</details>

<details>
<summary><strong>Swift Testing Agent Skill</strong> — Improves Swift test code with <code>@Test</code>, <code>#expect</code>, parameterized testing, and traits</summary>

```bash
npx skills add https://github.com/twostraws/Swift-Testing-Agent-Skill --skill swift-testing-pro
```

</details>

<details>
<summary><strong>Swift API Design Guidelines</strong> — Naming, argument labels, terminology, and conventions aligned with Apple's guidelines</summary>

```bash
npx skills add https://github.com/Erikote04/Swift-API-Design-Guidelines-Agent-Skill --skill swift-api-design-guidelines-skill
```

</details>

<details>
<summary><strong>Swift Architecture Skill</strong> — Routes to the right design pattern based on your feature's needs</summary>

```bash
npx skills add https://github.com/efremidze/swift-architecture-skill --skill swift-architecture-skill
```

</details>

<details>
<summary><strong>Swift Security Skill</strong> — Secure credential storage, biometric auth, and cryptography using Keychain Services and CryptoKit</summary>

```bash
npx skills add https://github.com/ivan-magda/swift-security-skill --skill swift-security-expert
```

</details>

<details>
<summary><strong>SwiftUI Performance Audit</strong> — Identifies and resolves performance issues in SwiftUI applications</summary>

```bash
git clone https://github.com/Dimillian/Skills.git /tmp/dimillian-skills && cp -r /tmp/dimillian-skills/swiftui-performance-audit .claude/skills/ && rm -rf /tmp/dimillian-skills
```

</details>

<details>
<summary><strong>iOS Simulator Skill</strong> — Automation toolkit for building, testing, and interacting with iOS apps</summary>

```bash
git clone https://github.com/conorluddy/ios-simulator-skill.git /tmp/ios-sim && cp -r /tmp/ios-sim/ios-simulator-skill .claude/skills/ && rm -rf /tmp/ios-sim
```

</details>

<details>
<summary><strong>Writing for Interfaces</strong> — Reviews UI copy for clarity, purpose, and consistency</summary>

```bash
git clone https://github.com/andrewgleave/skills.git /tmp/andrewgleave-skills && cp -r /tmp/andrewgleave-skills/writing-for-interfaces .claude/skills/ && rm -rf /tmp/andrewgleave-skills
```

</details>

## License

MIT
