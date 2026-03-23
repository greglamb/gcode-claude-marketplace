# Fish Shell Documentation Index

Fish shell (friendly interactive shell) version 4.0.2 documentation.

---

## Reference Files

### Getting Started

- **tutorial.md** - Beginner-friendly introduction to fish
- **bash_users.md** - Quick reference for bash users migrating to fish
- **faq.md** - Frequently asked questions and common gotchas

### Core Reference

- **language.md** - Complete language reference (syntax, quoting, escapes)
- **interactive.md** - Interactive features (completions, bindings, prompts)
- **completions.md** - Writing custom completions

### Command References (`commands/`)

- **commands/string.md** - All string manipulation subcommands
- **commands/variables.md** - set, read, export, status
- **commands/functions.md** - function, funced, funcsave, return
- **commands/control-flow.md** - if, switch, for, while, and, or, not
- **commands/path.md** - Path manipulation commands
- **commands/math.md** - Math and random commands
- **commands/jobs.md** - Job control (jobs, fg, bg, disown, wait)
- **commands/io.md** - Input/output (echo, printf, read)
- **commands/misc.md** - test, type, command, builtin, eval

---

## Quick Links by Topic

### Variables

```fish
set name value           # Set variable
set -gx VAR value        # Global + exported
set -l name value        # Local
set -U name value        # Universal (persists)
set -e name              # Erase
set -q name              # Check if exists
```

### Functions

```fish
function name
    echo $argv
end

funced name              # Edit function
funcsave name            # Save to file
functions name           # Show definition
```

### Control Flow

```fish
if test condition
    # ...
else if test other
    # ...
else
    # ...
end

switch $var
case pattern
    # ...
case '*'
    # ...
end

for item in $list
    echo $item
end

while test condition
    # ...
end
```

### String Manipulation

```fish
string match PATTERN STRING
string replace OLD NEW STRING
string split DELIMITER STRING
string join DELIMITER STRINGS
string trim STRING
string upper/lower STRING
string length STRING
string sub -s START -l LEN STRING
```

### Path Management

```fish
fish_add_path ~/bin      # Add to PATH
cd /path                 # Change directory
pwd                      # Print working directory
```

### Abbreviations

```fish
abbr -a gco git checkout
abbr --list
abbr --erase gco
```

### Completions

```fish
complete -c cmd -s h -l help -d 'Help'
complete -c cmd -a 'arg1 arg2' -d 'Args'
```

---

## Configuration Files

| File | Purpose |
|------|---------|
| `~/.config/fish/config.fish` | Main configuration |
| `~/.config/fish/conf.d/*.fish` | Additional configs (loaded before config.fish) |
| `~/.config/fish/functions/*.fish` | Function definitions (autoloaded) |
| `~/.config/fish/completions/*.fish` | Custom completions |
| `~/.config/fish/fish_variables` | Universal variables |

---

## Key Differences from Bash

| Bash | Fish |
|------|------|
| `export VAR=val` | `set -gx VAR val` |
| `VAR=val` | `set VAR val` |
| `` `cmd` `` | `(cmd)` or `$(cmd)` |
| `$((1+2))` | `math 1+2` |
| `${var:-default}` | `set -q var; or set var default` |
| `if [ ]; then fi` | `if test; end` |
| `for i in; do done` | `for i in; end` |
| `function f() {}` | `function f; end` |
| `alias x='y'` | `abbr -a x y` |
| `~/.bashrc` | `~/.config/fish/config.fish` |

---

## Special Variables

| Variable | Description |
|----------|-------------|
| `$argv` | Function/script arguments |
| `$status` | Exit status of last command |
| `$fish_pid` | Fish's process ID |
| `$last_pid` | PID of last backgrounded job |
| `$PWD` | Current working directory |
| `$HOME` | User's home directory |
| `$USER` | Current username |
| `$PATH` | Command search path |
| `$fish_function_path` | Function search path |
| `$fish_complete_path` | Completion search path |

---

## Useful Commands

```fish
# Help
help                     # Open documentation
man cmd                  # Man page for cmd

# Configuration
fish_config              # Web-based configurator
fish_config theme show   # List themes
set -U fish_greeting ""  # Disable greeting

# Debugging
type cmd                 # What is 'cmd'?
functions func           # Show function definition
status                   # Current shell status

# History
history                  # Show history
history search pattern   # Search history
```

---

## Resources

- Official Documentation: https://fishshell.com/docs/current/
- GitHub: https://github.com/fish-shell/fish-shell
- Awesome Fish: https://github.com/jorgebucaran/awesome-fish
