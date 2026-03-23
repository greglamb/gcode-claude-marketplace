# Variables Command Reference

Complete reference for variable-related commands: `set`, `read`, `export`, and `status`.

---

## set - Display and Change Variables

```fish
set [OPTIONS] [NAME [VALUE ...]]
```

### Scope Options

| Option | Description |
|--------|-------------|
| `-l, --local` | Block-scoped variable (erased when block ends) |
| `-f, --function` | Function-scoped variable (erased when function ends) |
| `-g, --global` | Global variable (available to all functions in this shell) |
| `-U, --universal` | Universal variable (persisted, shared across all fish instances) |

### Export Options

| Option | Description |
|--------|-------------|
| `-x, --export` | Export to child processes (environment variable) |
| `-u, --unexport` | Don't export to child processes |

### Path Variable Options

| Option | Description |
|--------|-------------|
| `--path` | Treat as path variable (split/join on `:`) |
| `--unpath` | Don't treat as path variable |

### Modification Options

| Option | Description |
|--------|-------------|
| `-a, --append` | Append values to existing variable |
| `-p, --prepend` | Prepend values to existing variable |
| `-e, --erase` | Erase variable |
| `-q, --query` | Test if variable exists (exit status only) |
| `-S, --show` | Show variable info (scope, export status) |
| `-n, --names` | List only variable names |
| `-L, --long` | Don't abbreviate long values |
| `--no-event` | Don't trigger variable change event |

### Basic Usage

```fish
# Set a variable
set name 'value'

# Set with multiple values (creates a list)
set colors red green blue

# Set empty (creates empty list)
set empty

# Erase a variable
set -e name
```

### Scoped Variables

```fish
# Local to current block
if true
    set -l local_var 'only in this block'
end
# local_var is gone here

# Function-scoped
function myfunc
    set -f func_var 'only in this function'
end

# Global (available everywhere in this shell)
set -g global_var 'everywhere'

# Universal (persisted, shared across all fish sessions)
set -U fish_greeting 'Welcome!'
```

### Exported Variables

```fish
# Export for child processes (like bash: export VAR=value)
set -gx EDITOR vim
set -gx PATH $PATH ~/bin

# Check if exported
set -S PATH
```

### List Operations

```fish
# All variables are lists
set fruits apple banana cherry

# Access by index (1-based)
echo $fruits[1]      # apple
echo $fruits[-1]     # cherry (last)
echo $fruits[2..3]   # banana cherry
echo $fruits[2..-1]  # banana cherry (from 2nd to end)

# Count elements
count $fruits        # 3

# Append/prepend
set -a fruits orange     # apple banana cherry orange
set -p fruits grape      # grape apple banana cherry orange

# Modify specific index
set fruits[2] mango      # grape mango cherry orange

# Erase specific index
set -e fruits[2]         # grape cherry orange
```

### Query Variables

```fish
# Check if variable exists (returns 0 if exists)
if set -q myvar
    echo "myvar exists"
end

# Check if list has enough elements
if set -q mylist[5]
    echo "mylist has at least 5 elements"
end

# Multiple variables (returns count of missing)
set -q var1 var2 var3
echo $status  # 0 if all exist, 1 if one missing, etc.
```

### Show Variable Info

```fish
# See where variable is defined
set -S PATH
# Output shows scope, values, export status

# List all variables
set

# List only names
set -n

# Filter by scope
set -g   # global only
set -U   # universal only
set -x   # exported only
```

### Scoping Rules

1. **Explicit scope** - Uses the scope you specify
2. **Existing variable** - Uses the scope of the existing variable
3. **New variable in function** - Function scope (not block scope)
4. **New variable outside function** - Global scope

```fish
# This sets in the narrowest existing scope
set existing_var 'new value'

# This always creates in function scope
function foo
    set newvar 'value'  # function-scoped, not global
end
```

### Capture Command Output

```fish
# Capture output into variable
set output (some_command)

# Preserves exit status
if set result (command_that_might_fail)
    echo "Succeeded with: $result"
else
    echo "Failed with status: $status"
end
```

---

## read - Read Input Into Variables

```fish
read [OPTIONS] [VARIABLE ...]
```

### Scope Options

Same as `set`: `-l`, `-f`, `-g`, `-U`, `-x`, `-u`

### Input Control

| Option | Description |
|--------|-------------|
| `-d, --delimiter` | Split on delimiter (entire string) |
| `-n, --nchars N` | Read N characters max |
| `-t, --tokenize` | Split using shell tokenization |
| `-a, --list` | Store all tokens in one variable as list |
| `-z, --null` | Use NUL as line terminator |
| `-L, --line` | Read one line per variable |

### Interactive Mode

| Option | Description |
|--------|-------------|
| `-p, --prompt CMD` | Use output of CMD as prompt |
| `-P, --prompt-str STR` | Use STR as prompt directly |
| `-R, --right-prompt CMD` | Right-side prompt |
| `-s, --silent` | Hide input (for passwords) |
| `-S, --shell` | Enable syntax highlighting and completions |
| `-c, --command CMD` | Pre-fill with CMD |

### Basic Usage

```fish
# Read into variable
echo 'hello' | read greeting
echo $greeting  # hello

# Read from user
read -P 'Enter name: ' name

# Read password (hidden)
read -s -P 'Password: ' password

# Read with prompt command
read -p 'set_color green; echo -n "Name: "' name
```

### Reading Lines

```fish
# Read multiple lines into multiple variables
printf 'line1\nline2\nline3\n' | read -L a b c
echo $a  # line1
echo $b  # line2
echo $c  # line3

# Read line by line in loop
cat file.txt | while read -l line
    echo "Line: $line"
end
```

### Splitting Input

```fish
# Split on delimiter
echo 'a,b,c' | read -d ',' first second third
# first=a, second=b, third=c

# Split on multi-char delimiter
echo 'a==b==c' | read -d '==' -l a b c

# Tokenize like shell
echo 'foo "bar baz" qux' | read -t first second third
# first=foo, second=bar baz, third=qux

# Read into list
echo 'a b c d' | read -a -l items
echo $items[1]  # a
count $items    # 4
```

### Command Substitution Pattern

```fish
# Read password inline (doesn't show in history)
mysql -u user -p(read -s)
```

---

## export - Set Environment Variable

```fish
export NAME=VALUE
```

Shorthand for `set -gx NAME VALUE`.

```fish
export EDITOR=vim
# Equivalent to:
set -gx EDITOR vim
```

---

## status - Query Runtime Information

```fish
status [SUBCOMMAND]
```

### Shell State Queries

| Subcommand | Description |
|------------|-------------|
| `is-interactive` | True if connected to terminal |
| `is-login` | True if login shell |
| `is-block` | True if in a block |
| `is-command-substitution` | True if in command substitution |
| `is-breakpoint` | True if at breakpoint prompt |

### Script Information

| Subcommand | Description |
|------------|-------------|
| `filename` | Path to current script |
| `basename` | Filename only |
| `dirname` | Directory only |
| `line-number` | Current line number |
| `current-command` | Currently running command |
| `current-commandline` | Full commandline |
| `function` | Current function name |
| `stack-trace` | Print call stack |
| `fish-path` | Path to fish executable |

### Examples

```fish
# Check if interactive
if status is-interactive
    # Only in interactive shell
    set -g fish_greeting 'Hello!'
end

# Check if login shell
if status is-login
    # Login-only setup
end

# Get script directory
set script_dir (status dirname)
source $script_dir/helper.fish

# Debug info
echo "Running: "(status filename)":"(status line-number)
```

---

## Special Variables

### Automatic Variables

| Variable | Description |
|----------|-------------|
| `$status` | Exit status of last command |
| `$pipestatus` | Exit statuses of all pipeline commands |
| `$argv` | Arguments to function/script |
| `$fish_pid` | Fish's process ID |
| `$last_pid` | PID of last backgrounded job |
| `$CMD_DURATION` | Duration of last command (ms) |

### Environment Variables

| Variable | Description |
|----------|-------------|
| `$PWD` | Current directory |
| `$HOME` | Home directory |
| `$USER` | Current username |
| `$PATH` | Command search path |
| `$CDPATH` | cd search path |
| `$EDITOR` | Default editor |

### Fish-Specific Variables

| Variable | Description |
|----------|-------------|
| `$fish_greeting` | Greeting message |
| `$fish_function_path` | Function search paths |
| `$fish_complete_path` | Completion search paths |
| `$fish_emoji_width` | Emoji display width |
| `$fish_ambiguous_width` | Ambiguous char width |

### Using $status and $pipestatus

```fish
# Check exit status
false
if test $status -ne 0
    echo "Command failed"
end

# Pipeline status (all commands)
echo foo | false | true
echo $pipestatus  # 0 1 0

# Check any failure in pipeline
echo foo | false | true
if string match -q '*1*' (string join ' ' $pipestatus)
    echo "Something in pipeline failed"
end
```

---

## Common Mistakes (Bash Users)

| Bash | Fish |
|------|------|
| `export VAR=value` | `set -gx VAR value` |
| `VAR=value` | `set VAR value` |
| `local VAR=value` | `set -l VAR value` |
| `unset VAR` | `set -e VAR` |
| `$@` or `$*` | `$argv` |
| `$1`, `$2`, etc. | `$argv[1]`, `$argv[2]` |
| `$#` | `count $argv` |
| `$?` | `$status` |
| `$$` | `$fish_pid` |
| `$!` | `$last_pid` |
| `${var:-default}` | `set -q var; or set var default` |
| `${#var}` | `string length $var` |
| `declare -a arr` | `set arr` (all vars are lists) |
| `${arr[@]}` | `$arr` |
| `${arr[0]}` | `$arr[1]` (1-indexed!) |
| `read VAR` | `read VAR` (same, but no REPLY default) |
| `read -p "Prompt: "` | `read -P "Prompt: "` |

### Word Splitting Difference

```fish
# In bash, unquoted variables split on whitespace
# In fish, they DON'T split!

set foo 'hello world'

# Creates ONE directory named "hello world"
mkdir $foo

# To iterate words, use explicit splitting
for word in (string split ' ' $foo)
    echo $word
end
```
