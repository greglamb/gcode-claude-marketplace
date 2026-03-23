# vibecode-workflow-marketplace

## Install

```bash
claude plugin marketplace add greglamb/vibecode-workflow-marketplace
claude plugin install vibecode-workflow@vibecode-workflow-marketplace
```

## Plugin: vibecode-workflow

A project template for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that provides structured commands, skills, and documentation conventions out of the box.

### Getting Started

1. **Install Claude Code** if you haven't already:
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```

2. **Install the plugin** from your project directory:
   ```bash
   claude plugin marketplace add greglamb/vibecode-workflow-marketplace
   claude plugin install vibecode-workflow@vibecode-workflow-marketplace
   ```

3. **Install dependency plugins** — The workflow uses two additional marketplace plugins:
   ```bash
   /plugin marketplace add obra/superpowers-marketplace
   /plugin install superpowers@superpowers-marketplace
   /plugin install episodic-memory@superpowers-marketplace
   ```

4. **Run setup** — Use `/setthevibe` to initialize your project environment (creates `.worktrees/`, `_reference/`, `TODO.md`, `CHANGELOG.md`, and configures `CLAUDE.md`).

5. **Define your standards** — Use `/preparestandards` to generate a `project-standards` skill, or manually edit `.claude/skills/project-standards/SKILL.md` with your project's coding conventions, linting rules, and architectural guidelines. This skill is invoked before any code is written or modified. For help authoring skills, try using the [Anthropic Skill Creator](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md) or the [Skill Seekers](https://github.com/yusufkaraaslan/Skill_Seekers) tool.

6. **Add reference files** — Drop style guides, API specs, or other reference material into `.claude/skills/project-standards/references/`.

7. **Start Claude Code** from the project root:
   ```bash
   claude
   ```

8. **Use the commands** — Type `/check`, `/commit`, `/todo`, etc. in your Claude Code session.

### What's Included

#### Custom Slash Commands (`.claude/commands/`)

| Command             | Example                                                                                                         | Description                                                                                                                                                                                                                                                             |
|---------------------|-----------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `/plotcaper`        | /plotcaper Phase 2 from TODO.md OR /plotcaper The implementation of REQUIREMENTS.md using a phased approach      | Syncs episodic memory, loads superpowers, then plans using brainstorm + extension skills. Afterward it will ask if you want to start implementation or make changes to the plan. You will also have the option to perform the implementation as a Subagent-Driven task. |
| `/check`            | /check                                                                                                          | Runs unit and integration tests, validates code against project standards                                                                                                                                                                                               |
| `/commit`           | /commit                                                                                                         | Diffs changes, generates a [Conventional Commits](https://www.conventionalcommits.org/) message with [Gitmoji](https://gitmoji.dev/), stages, and commits                                                                                                               |
| `/push`             | /push                                                                                                           | Push changes to remote                                                                                                                                                                                                                                                  |
| `/next`             | /next                                                                                                           | Asks Claude what it thinks the next logical step is (doesn't actually do it yet)                                                                                                                                                                                        |
| `/todo`             | /todo                                                                                                           | Review the current `TODO.md` contents                                                                                                                                                                                                                                   |
| `/clean`            | /clean                                                                                                          | Cleans up the current `TODO.md` contents                                                                                                                                                                                                                                |
| `/setthevibe`       | /setthevibe                                                                                                     | Sets up the development environment: creates `.worktrees/`, `_reference/`, `TODO.md`, `CHANGELOG.md`, and verifies required plugins are available                                                                                                                       |
| `/preparestandards` | /preparestandards Apply best practices for developing this application such as solid, yagni, kiss, dry, and tdd  | Creates the `project-standards` skill based on your requirements using `superpowers:writing-skills`                                                                                                                                                                      |
| `/backup`           | /backup TODO.md _reference/_archive/todo/                                                                       | Copies a file to a target directory with a Unix epoch timestamp in the filename                                                                                                                                                                                         |
| `/vibedebug`        | /vibedebug                                                                                                      | Uses `superpowers:systematic-debugging` to review files in `_reference/debug`                                                                                                                                                                                           |

#### Project Skills (`.claude/skills/`)

- **project-standards** — Define your coding standards, linting rules, and conventions here. Referenced by `CLAUDE.md` as a required skill before any code changes.

#### Plugins (`.claude/settings.json`)

Two marketplace plugins are enabled by default:

- **superpowers** — Extended planning, brainstorming, and verification capabilities
- **episodic-memory** — Persistent context across Claude Code sessions

#### Documentation Conventions

- **`CLAUDE.md`** — Project-level instructions Claude reads automatically. Enforces that all changes update `CHANGELOG.md` and `TODO.md`.
- **`CHANGELOG.md`** — Track all user-facing changes here.
- **`TODO.md`** — Track deferred work, known limitations, and planned features. The template enforces a "no silent deferrals" rule: anything out of scope must be logged.
- **`docs/plans/`** — Directory for longer-form planning documents.

### Customization

#### Adding Commands

Create a new markdown file in `.claude/commands/`:

```markdown
---
name: my-command
description: What it does
---
Your prompt instructions here
```

#### Adding Skills

Create a directory under `.claude/skills/` with a `SKILL.md` file and an optional `references/` folder for supporting docs. For help authoring skills, try using the [Anthropic Skill Creator](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md) or the [Skill Seekers](https://github.com/yusufkaraaslan/Skill_Seekers) tool.

#### Restricting Tool Access

Commands can declare `allowed-tools` in their frontmatter to limit what Claude can do (see `commit.md` for an example that restricts to git operations only).

## License

MIT
