# Miscellaneous Commands Reference

Reference for utility commands: `test`, `type`, `command`, `builtin`, `eval`, `exec`, `source`, `time`, `argparse`.

---

## test - Evaluate Conditions

```fish
test EXPRESSION
[ EXPRESSION ]
```

Returns 0 (true) or 1 (false).

### File Tests

| Test | Description |
|------|-------------|
| `-e FILE` | Exists |
| `-f FILE` | Regular file |
| `-d FILE` | Directory |
| `-L FILE` | Symbolic link |
| `-r FILE` | Readable |
| `-w FILE` | Writable |
| `-x FILE` | Executable |
| `-s FILE` | Size > 0 |
| `-b FILE` | Block device |
| `-c FILE` | Character device |
| `-p FILE` | Named pipe (FIFO) |
| `-S FILE` | Socket |
| `-t FD` | FD is terminal |

### File Comparisons

| Test | Description |
|------|-------------|
| `FILE1 -nt FILE2` | FILE1 newer than FILE2 |
| `FILE1 -ot FILE2` | FILE1 older than FILE2 |
| `FILE1 -ef FILE2` | Same file (hard link) |

### String Tests

| Test | Description |
|------|-------------|
| `-n STRING` | Non-empty |
| `-z STRING` | Empty (zero length) |
| `STR1 = STR2` | Equal (single `=`!) |
| `STR1 != STR2` | Not equal |

### Numeric Tests

| Test | Description |
|------|-------------|
| `N1 -eq N2` | Equal |
| `N1 -ne N2` | Not equal |
| `N1 -lt N2` | Less than |
| `N1 -le N2` | Less or equal |
| `N1 -gt N2` | Greater than |
| `N1 -ge N2` | Greater or equal |

### Logical Operators

| Test | Description |
|------|-------------|
| `! EXPR` | NOT |
| `EXPR1 -a EXPR2` | AND |
| `EXPR1 -o EXPR2` | OR |
| `( EXPR )` | Grouping |

### Examples

```fish
# File exists
if test -f myfile.txt
    echo "File exists"
end

# Directory exists
test -d /etc && echo "Directory exists"

# Check readable and writable
if test -r file -a -w file
    echo "Readable and writable"
end

# String comparison (single =, not ==!)
if test "$a" = "$b"
    echo "Equal"
end

# Numeric comparison
if test $count -gt 10
    echo "More than 10"
end

# Non-empty string
if test -n "$var"
    echo "var is set"
end

# Empty string
if test -z "$var"
    echo "var is empty"
end

# File newer than
if test file1 -nt file2
    echo "file1 is newer"
end

# Combined with or
if test -f a.txt -o -f b.txt
    echo "At least one exists"
end
```

---

## type - Show Command Type

```fish
type [OPTIONS] NAME ...
```

### Options

| Option | Description |
|--------|-------------|
| `-t, --type` | Print type only |
| `-p, --path` | Print path (for files) |
| `-P, --force-path` | Print path only |
| `-q, --query` | Silent, set exit status |
| `-f, --no-functions` | Ignore functions |

### Output Types

- `builtin` - Fish builtin command
- `function` - Fish function
- `file` - External command

```fish
type ls
# ls is a function with definition...

type -t ls
# function

type -p python
# /usr/bin/python

# Check if command exists
if type -q git
    echo "git is available"
end
```

---

## command - Run External Command

```fish
command [OPTIONS] NAME [ARGS ...]
```

Run the external command, bypassing functions with the same name.

### Options

| Option | Description |
|--------|-------------|
| `-v, --search` | Print path or name |
| `-s, --search` | Search for command path |
| `-q, --query` | Check if exists (silent) |

```fish
# Wrap ls but use real ls inside
function ls
    command ls --color=auto $argv
end

# Check if external command exists
if command -q python3
    echo "python3 available"
end

# Get command path
set python_path (command -s python)
```

---

## builtin - Run Builtin Command

```fish
builtin NAME [ARGS ...]
builtin -n
```

Run the builtin version, bypassing functions with the same name.

```fish
# List all builtins
builtin -n

# Use builtin cd instead of any function
builtin cd /path
```

---

## eval - Evaluate String as Command

```fish
eval STRING ...
```

Executes the string as fish commands.

```fish
# Simple eval
eval echo hello

# Build command dynamically
set cmd "echo"
set args "hello world"
eval $cmd $args

# From variable
set script "set x 5; echo \$x"
eval $script
```

**Warning:** Be careful with user input - potential for command injection!

---

## exec - Replace Shell with Command

```fish
exec COMMAND [ARGS ...]
```

Replaces the current shell process with the command.

```fish
# Replace shell with bash
exec bash

# Start application (shell exits when done)
exec /usr/bin/my-app

# Useful in scripts that just set up and run something
exec $program_to_run
```

---

## source - Execute File in Current Shell

```fish
source FILE [ARGS ...]
. FILE [ARGS ...]
```

Execute commands from file in current shell context.

```fish
# Source config file
source ~/.config/fish/local.fish

# With arguments
source script.fish arg1 arg2

# From command (use psub)
source (generate_config | psub)

# From stdin
echo "set x 1" | source
```

---

## time - Measure Command Duration

```fish
time COMMAND
```

Reports real, user, and system time for command.

```fish
time sleep 1
# Executed in   1.01 secs
#    usr time    5.14 millis
#    sys time    6.05 millis

time make -j4
```

**Also:** `$CMD_DURATION` contains duration of last command in milliseconds.

---

## argparse - Parse Command Options

```fish
argparse [OPTIONS] OPTION_SPEC ... -- $argv
```

Parse command-line options in functions.

### Option Spec Format

```
NAME[/SHORT][=?!][+]
```

- `/SHORT` - Short option letter
- `=` - Requires argument
- `=?` - Optional argument
- `=!` - Requires argument (must have value)
- `+` - Can repeat (creates list)

### Examples

```fish
function mycommand
    argparse 'h/help' 'v/verbose' 'f/file=' -- $argv
    or return

    if set -q _flag_help
        echo "Usage: mycommand [-h] [-v] [-f FILE]"
        return 0
    end

    if set -q _flag_verbose
        echo "Verbose mode"
    end

    if set -q _flag_file
        echo "File: $_flag_file"
    end

    echo "Remaining args: $argv"
end

# Usage:
mycommand -v -f input.txt extra args
# Output:
# Verbose mode
# File: input.txt
# Remaining args: extra args
```

### Advanced argparse

```fish
function mycmd
    # n - name (optional short)
    # c/count= - requires value
    # d/debug - boolean flag
    # v/verbose+ - can repeat (-v -v -v)
    argparse 'n/name=' 'c/count=' 'd/debug' 'v/verbose+' -- $argv
    or return

    if set -q _flag_name
        echo "Name: $_flag_name"
    end

    if set -q _flag_count
        echo "Count: $_flag_count"
    end

    # Repeated flags become list
    echo "Verbosity level: "(count $_flag_verbose)
end
```

---

## contains - Check List Membership

```fish
contains [OPTIONS] KEY LIST ...
```

Check if KEY is in LIST.

```fish
if contains foo $mylist
    echo "found"
end

# With --
if contains -- -v $argv
    echo "verbose flag found"
end

# Get index
if set idx (contains -i foo $mylist)
    echo "Found at index: $idx"
end
```

---

## count - Count Elements

```fish
count ITEMS ...
```

```fish
count $argv        # Number of arguments
count $PATH        # Number of PATH entries
count (ls)         # Number of files
```

---

## Common Mistakes (Bash Users)

| Bash | Fish |
|------|------|
| `[ ]` | `test` or `[ ]` (same) |
| `[[ ]]` | `test` (no double bracket) |
| `[[ $a == $b ]]` | `test $a = $b` (single =) |
| `[[ $a =~ regex ]]` | `string match -r` |
| `source ~/.bashrc` | `source ~/.config/fish/config.fish` |
| `eval $(cmd)` | `eval (cmd)` |
| `type -a` | `type` |
| `which cmd` | `command -s cmd` or `type -p cmd` |

### test Pitfalls

```fish
# Wrong: == (this is a bash-ism)
test "$a" == "$b"  # Error!

# Right: single =
test "$a" = "$b"

# Wrong: > for comparison (this is redirection!)
test $a > $b  # Creates file named $b!

# Right: -gt
test $a -gt $b
```
