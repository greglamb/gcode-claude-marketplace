# Writing Custom Completions

Complete guide to writing tab completions for fish shell commands.

---

## Overview

Fish provides powerful tab completion. Completions are defined with the `complete` command and stored in `~/.config/fish/completions/COMMAND.fish`.

---

## Basic Syntax

```fish
complete -c COMMAND [OPTIONS]
```

### Core Options

| Option | Description |
|--------|-------------|
| `-c, --command CMD` | Command to complete for |
| `-p, --path PATH` | Complete for absolute path |
| `-s, --short-option X` | Short option (-x) |
| `-l, --long-option NAME` | Long option (--name) |
| `-o, --old-option NAME` | Old-style option (-name) |
| `-a, --arguments ARGS` | Possible arguments |
| `-d, --description DESC` | Description |

### Behavior Options

| Option | Description |
|--------|-------------|
| `-r, --require-parameter` | Option requires argument |
| `-f, --no-files` | Don't complete with files |
| `-F, --force-files` | Force file completion |
| `-x, --exclusive` | `-r` and `-f` combined |
| `-k, --keep-order` | Don't sort arguments |
| `-n, --condition CMD` | Only if CMD returns 0 |
| `-w, --wraps CMD` | Inherit completions from CMD |
| `-e, --erase` | Remove completion |

---

## Simple Examples

### Boolean Flag

```fish
complete -c mycommand -s h -l help -d 'Show help'
complete -c mycommand -s v -l verbose -d 'Verbose output'
```

### Option with Required Argument

```fish
# -o FILE or --output FILE or --output=FILE
complete -c mycommand -s o -l output -r -d 'Output file'

# With file completion (default)
complete -c mycommand -s o -l output -rF -d 'Output file'
```

### Option with Specific Values

```fish
# --format json|xml|csv
complete -c mycommand -l format -xa 'json xml csv' -d 'Output format'
```

### Subcommands

```fish
# mycommand start|stop|status
complete -c mycommand -n __fish_use_subcommand -a 'start' -d 'Start service'
complete -c mycommand -n __fish_use_subcommand -a 'stop' -d 'Stop service'
complete -c mycommand -n __fish_use_subcommand -a 'status' -d 'Show status'
```

---

## Conditional Completions

Use `-n` to make completions conditional:

```fish
# Only suggest --debug when not already present
complete -c mycommand -l debug -n 'not __fish_contains_opt debug' -d 'Debug mode'

# Only after specific subcommand
complete -c git -n '__fish_seen_subcommand_from checkout' -a '(__fish_git_branches)'
```

### Useful Helper Functions

| Function | Description |
|----------|-------------|
| `__fish_use_subcommand` | No subcommand given yet |
| `__fish_seen_subcommand_from X` | Subcommand X was given |
| `__fish_contains_opt X` | Option X is present |
| `__fish_complete_suffix .ext` | Complete files with extension |

---

## Dynamic Completions

Arguments can come from command output:

```fish
# Complete with usernames
complete -c mycommand -s u -l user -xa '(getent passwd | cut -d: -f1)'

# Complete with git branches
complete -c mycommand -l branch -xa '(git branch --format="%(refname:short)")'

# Complete with running processes
complete -c mycommand -s p -l pid -xa '(ps -axo pid= -o comm=)'
```

### With Descriptions

Tab-separated: `VALUE\tDESCRIPTION`

```fish
function __mycommand_users
    getent passwd | while read -l line
        set -l user (string split ':' $line)[1]
        set -l name (string split ':' $line)[5]
        echo "$user\t$name"
    end
end

complete -c mycommand -s u -xa '(__mycommand_users)'
```

---

## Full Example: Complete Script

Create `~/.config/fish/completions/myapp.fish`:

```fish
# myapp - A sample application
#
# Usage:
#   myapp [options] <command> [args]
#
# Commands:
#   start   - Start the service
#   stop    - Stop the service
#   status  - Show status
#
# Options:
#   -h, --help      Show help
#   -v, --verbose   Verbose output
#   -c, --config    Config file
#   -f, --format    Output format

# Clear existing completions
complete -c myapp -e

# Global options
complete -c myapp -s h -l help -d 'Show help'
complete -c myapp -s v -l verbose -d 'Verbose output'
complete -c myapp -s c -l config -rF -d 'Config file'
complete -c myapp -s f -l format -xa 'json yaml text' -d 'Output format'

# Subcommands (only when no subcommand yet)
complete -c myapp -n __fish_use_subcommand -a start -d 'Start the service'
complete -c myapp -n __fish_use_subcommand -a stop -d 'Stop the service'
complete -c myapp -n __fish_use_subcommand -a status -d 'Show service status'

# Options for 'start' subcommand
complete -c myapp -n '__fish_seen_subcommand_from start' -s d -l daemon -d 'Run as daemon'
complete -c myapp -n '__fish_seen_subcommand_from start' -s p -l port -xa '(seq 1024 65535)' -d 'Port number'

# Options for 'stop' subcommand
complete -c myapp -n '__fish_seen_subcommand_from stop' -s f -l force -d 'Force stop'

# 'status' has no special options
```

---

## Wrapping Commands

Inherit completions from another command:

```fish
# Make 'g' complete like 'git'
complete -c g -w git

# In a function definition
function g --wraps git
    git $argv
end
```

---

## Option Styles

### Short Options (-x)

```fish
# Can be grouped: -abc = -a -b -c
complete -c cmd -s a -d 'Option A'
complete -c cmd -s b -d 'Option B'
```

### Long Options (--name)

```fish
# GNU style, use = for value: --output=file
complete -c cmd -l output -r -d 'Output file'
```

### Old-Style Options (-name)

```fish
# Cannot be grouped, single dash
complete -c cmd -o Wall -d 'Enable all warnings'
```

---

## Completing Files

```fish
# Default: complete with files
complete -c cmd -s f

# Only specific extensions
complete -c cmd -s f -a '(__fish_complete_suffix .txt)'

# Directories only
complete -c cmd -s d -a '(__fish_complete_directories)'

# No files
complete -c cmd -s x -f

# Force files even if -f was set elsewhere
complete -c cmd -s F -F
```

---

## Testing Completions

```fish
# Show all completions for a command
complete -c mycommand

# Test completion
complete -C 'mycommand --'

# Reload completions
source ~/.config/fish/completions/mycommand.fish
```

---

## Common Patterns

### Mutex Options

```fish
# --json and --xml are mutually exclusive
complete -c cmd -l json -n 'not __fish_contains_opt xml' -d 'JSON output'
complete -c cmd -l xml -n 'not __fish_contains_opt json' -d 'XML output'
```

### Required Options

```fish
# --name is required
complete -c cmd -n 'not __fish_contains_opt name' -a ''
# (By providing no completions, fish prompts for --name)
```

### Positional Arguments

```fish
# First argument: action
complete -c cmd -n '__fish_is_first_arg' -a 'start stop' -d 'Action'

# Second argument: target (after action)
complete -c cmd -n '__fish_is_nth_arg 2' -a 'web db cache' -d 'Target'
```

### Counting Arguments

```fish
function __fish_is_nth_arg
    set -l cmd (commandline -opc)
    # Count non-option arguments
    set -l count 0
    for arg in $cmd[2..-1]
        if not string match -q -- '-*' $arg
            set count (math $count + 1)
        end
    end
    test $count -eq $argv[1]
end
```

---

## Best Practices

1. **Clear existing first**: Start with `complete -c cmd -e`
2. **Add descriptions**: Always use `-d`
3. **Use conditions**: Make completions context-aware
4. **Test extensively**: Try various scenarios
5. **Keep dynamic completions fast**: Slow completions hurt UX
6. **Order matters**: Last matching completion wins

---

## File Location

Completions are autoloaded from:
- `~/.config/fish/completions/`
- `/usr/share/fish/completions/`
- Directories in `$fish_complete_path`

Filename must match command: `mycommand.fish` for `mycommand`.
