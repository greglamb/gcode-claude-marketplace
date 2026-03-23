---
name: fish-shell
description: Fish shell (friendly interactive shell) documentation - use when writing fish scripts, configuring fish shell, understanding fish syntax, or migrating from bash to fish
---

# Fish Shell Skill

Comprehensive assistance with fish shell (version 4.0.2), the friendly interactive shell.

## When to Use This Skill

This skill should be triggered when:
- Writing fish shell scripts or functions
- Configuring fish shell (config.fish, prompts, themes)
- Understanding fish syntax and features
- Migrating scripts from bash/zsh to fish
- Using fish builtins and commands
- Setting up abbreviations, aliases, or completions
- Debugging fish scripts

## Quick Reference

### Variables

```fish
# Set a variable
set name 'Mister Noodle'
echo $name

# Export a variable (for external commands)
set -gx EDITOR vim

# Erase a variable
set -e MyVariable

# List variables (list/array)
set PATH $PATH /usr/local/bin
echo $PATH[1]      # First element
echo $PATH[-1]     # Last element
echo $PATH[1..3]   # Slice
```

### Functions

```fish
# Define a function
function ll
    ls -l $argv
end

# Function with description
function greet --description 'Greet someone'
    echo "Hello, $argv!"
end

# Alias-style function
function ls
    command ls --color=auto $argv
end
```

### Control Flow

```fish
# If statement
if test -e /etc/os-release
    cat /etc/os-release
else if test -e /etc/lsb-release
    cat /etc/lsb-release
else
    echo "Unknown OS"
end

# Switch statement
switch (uname)
case Linux
    echo "Hi Tux!"
case Darwin
    echo "Hi Hexley!"
case '*'
    echo "Unknown system"
end

# For loop
for file in *.txt
    echo "Processing $file"
end

# While loop
while read -l line
    echo $line
end < myfile.txt
```

### Abbreviations

```fish
# Add abbreviation (expands when you type)
abbr --add gco git checkout
abbr --add gst git status

# Position-aware abbreviation
abbr -a --position anywhere -- -C --color

# List abbreviations
abbr --list

# Erase abbreviation
abbr --erase gco
```

### String Manipulation

```fish
# Match patterns
string match '*.txt' myfile.txt

# Replace text
string replace 'old' 'new' 'old text'

# Split strings
string split ',' 'a,b,c'

# Trim whitespace
string trim '  hello  '

# Change case
string upper 'hello'
string lower 'HELLO'

# Get substring
string sub -s 1 -l 5 'hello world'
```

### Command Substitution

```fish
# Capture command output
set os (uname)
echo "Running on $os"

# In strings (use $ form)
echo "Running on $(uname)"
```

### Redirections

```fish
# Redirect stdout
echo hello > output.txt

# Redirect stderr
command 2> errors.txt

# Redirect both
command &> all_output.txt

# Append
echo more >> output.txt

# Pipe
cat file.txt | grep pattern

# Pipe stderr too
make fish 2>| less
```

### Path Management

```fish
# Add to PATH (recommended way)
fish_add_path ~/bin

# Check if in PATH
contains ~/bin $PATH

# Modify PATH directly
set -gx PATH $PATH /new/path
```

### Test Conditions

```fish
# File tests
test -e file        # exists
test -f file        # is regular file
test -d dir         # is directory
test -r file        # readable
test -w file        # writable
test -x file        # executable

# String tests
test -n "$var"      # non-empty
test -z "$var"      # empty
test "$a" = "$b"    # equal
test "$a" != "$b"   # not equal

# Numeric tests
test $a -eq $b      # equal
test $a -gt $b      # greater than
test $a -lt $b      # less than
```

### Configuration

```fish
# Config file location
~/.config/fish/config.fish

# Additional config files (loaded first)
~/.config/fish/conf.d/*.fish

# Function files (autoloaded)
~/.config/fish/functions/funcname.fish

# Check if interactive/login
if status --is-interactive
    # interactive-only config
end

if status --is-login
    # login-only config
end
```

### Prompt Customization

```fish
function fish_prompt
    set -l user_char '>'
    if fish_is_root_user
        set user_char '#'
    end
    echo (set_color green)$PWD (set_color normal)$user_char ' '
end
```

### Key Bindings

```fish
# List bindings
bind

# Custom binding
bind \cg 'git status'

# Vi mode
fish_vi_key_bindings
```

## Reference Files

This skill includes comprehensive documentation in `references/`:

### Core References
- **tutorial.md** - Getting started with fish
- **language.md** - Complete fish language reference
- **interactive.md** - Interactive features (completions, history, bindings)
- **completions.md** - Writing custom completions
- **bash_users.md** - Fish for bash users (migration guide)
- **faq.md** - Frequently asked questions and common gotchas

### Command References (`references/commands/`)
- **string.md** - All string manipulation subcommands
- **variables.md** - set, read, export, status
- **functions.md** - function, funced, funcsave, return
- **control-flow.md** - if, switch, for, while, and, or, not
- **path.md** - Path manipulation commands
- **math.md** - Math and random commands
- **jobs.md** - Job control (jobs, fg, bg, disown, wait)
- **io.md** - Input/output (echo, printf, read)
- **misc.md** - test, type, command, builtin, eval

## Key Differences from Bash

| Bash | Fish |
|------|------|
| `export VAR=value` | `set -gx VAR value` |
| `VAR=value` | `set VAR value` |
| `$(command)` | `(command)` or `$(command)` |
| `[ test ]` | `test ...` |
| `${var:-default}` | `set -q var; or set var default` |
| `if [ ]; then ... fi` | `if ...; ... end` |
| `for i in ...; do ... done` | `for i in ...; ... end` |
| `function f() { ... }` | `function f; ... end` |
| `source file` | `source file` (same) |
| `alias x='y'` | `abbr -a x y` or `alias x y` |

## Working with This Skill

### For Beginners
Start with `tutorial.md` for a gentle introduction to fish concepts.

### For Bash Users
See `bash_users.md` for a quick mapping of bash concepts to fish equivalents.

### For Scripting
- `language.md` - Complete syntax reference
- `commands/control-flow.md` - If, switch, for, while loops
- `commands/string.md` - String manipulation
- `commands/variables.md` - Variable handling

### For Interactive Use
- `interactive.md` - Autosuggestions, tab completion, key bindings
- `completions.md` - Writing custom completions

### For Common Issues
See `faq.md` for frequently asked questions and common gotchas.

## Resources

- Official docs: https://fishshell.com/docs/current/
- GitHub: https://github.com/fish-shell/fish-shell
- Configuration: `fish_config` command opens web-based configurator

## Notes

- Fish 4.0.2 documentation
- Fish does NOT use POSIX sh syntax
- Variables are lists by default
- No need for `${}` - just `$var`
- Autosuggestions and syntax highlighting work out of the box
