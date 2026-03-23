# Fish Language Reference

Complete reference for the fish shell scripting language.

**URL:** https://fishshell.com/docs/current/language.html

---

## Syntax Overview

Commands are executed by writing the command name followed by arguments:

```fish
echo hello world
```

Commands are separated by newlines or semicolons:

```fish
echo hello; echo world
```

## Terminology

- **Argument**: Parameter to a command (`foo` in `echo foo`)
- **Builtin**: Command implemented by the shell (`echo`, `set`)
- **Command**: External program fish runs (`/bin/ls`)
- **Function**: User-defined command
- **Job**: Running pipeline or command
- **Pipeline**: Commands connected with `|`
- **Redirection**: Changing stdin/stdout/stderr
- **Switch/Option**: Argument starting with `-`

## Quotes

### Single Quotes

No expansion inside single quotes:

```fish
echo 'Hello $USER'    # Prints literal $USER
```

### Double Quotes

Variable and command substitution expanded:

```fish
echo "Hello $USER"    # Prints Hello username
echo "Today is $(date)"
```

## Escape Sequences

```fish
\n    # Newline
\t    # Tab
\r    # Carriage return
\e    # Escape
\\    # Backslash
\'    # Single quote
\"    # Double quote
\$    # Dollar sign
\*    # Asterisk
\?    # Question mark
\~    # Tilde
\#    # Hash
\(    # Left paren
\)    # Right paren
\{    # Left brace
\}    # Right brace
\[    # Left bracket
\]    # Right bracket
\<    # Less than
\>    # Greater than
\&    # Ampersand
\|    # Pipe
\;    # Semicolon
\ \   # Space (escaped)
```

Unicode escapes:

```fish
\xHH        # Byte value (hex)
\ooo        # Octal value
\uXXXX      # 16-bit Unicode
\UXXXXXXXX  # 32-bit Unicode
```

## Redirections

```fish
# Redirect stdout
cmd > file
cmd >> file          # Append
cmd >? file          # No clobber

# Redirect stderr
cmd 2> file
cmd 2>> file         # Append
cmd 2>? file         # No clobber

# Redirect both
cmd &> file
cmd &>> file

# Redirect to file descriptor
cmd >&2              # stdout to stderr
cmd 2>&1             # stderr to stdout

# Read from file
cmd < file
cmd <? file          # Or /dev/null if file doesn't exist

# Close file descriptor
cmd 2>&-
```

## Pipes

```fish
cmd1 | cmd2          # stdout of cmd1 to stdin of cmd2
cmd1 2>| cmd2        # stderr of cmd1 to stdin of cmd2
cmd1 &| cmd2         # both stdout and stderr
```

## Job Control

```fish
cmd &                # Run in background

jobs                 # List jobs
fg                   # Foreground
bg                   # Background
disown               # Detach job

Ctrl+Z               # Suspend foreground job
```

## Variables

### Setting

```fish
set name value       # Set (local or global depending on context)
set -l name value    # Local
set -g name value    # Global
set -U name value    # Universal (persists across sessions)
set -x name value    # Export (visible to child processes)
set -gx name value   # Global and export
```

### Erasing

```fish
set -e name          # Erase variable
set -eg name         # Erase global
set -eU name         # Erase universal
```

### Querying

```fish
set -q name          # Returns 0 if exists
set -q name[1]       # Returns 0 if has at least 1 element
```

### Lists (Arrays)

All variables are lists:

```fish
set list a b c
echo $list[1]        # First element
echo $list[-1]       # Last element
echo $list[2..3]     # Slice
echo $list[2..-1]    # From 2nd to end
count $list          # Number of elements

# Append/prepend
set -a list d e      # Append
set -p list z        # Prepend
```

### Expansion

```fish
echo $var            # Expand variable
echo "$var"          # In double quotes
echo '$var'          # Literal (no expansion)
echo {$var}foo       # Append to variable
```

### Special Variables

```fish
$argv                # Arguments to function/script
$status              # Exit status of last command
$pipestatus          # Exit statuses of pipeline commands
$fish_pid            # Fish's PID
$last_pid            # PID of last background job
$CMD_DURATION        # Duration of last command in ms
$PWD                 # Current directory
$HOME                # Home directory
$USER                # Current user
$hostname            # Hostname
$version             # Fish version
```

## Command Substitution

```fish
echo (pwd)           # Traditional form
echo $(pwd)          # Dollar form (works in quotes)

set os (uname)
echo "Running on $(uname)"
```

## Brace Expansion

```fish
echo file{1,2,3}.txt     # file1.txt file2.txt file3.txt
echo {a,b}{1,2}          # a1 a2 b1 b2
echo file{1..5}.txt      # file1.txt file2.txt ... file5.txt
```

## Wildcards (Globs)

```fish
*        # Any string (no /)
**       # Any string (including /)
?        # Single character (deprecated)
```

```fish
ls *.txt
ls **/*.py           # Recursive
```

Glob failures cause the command to fail (unless in `for`, `set`, `count`).

## Functions

```fish
function name
    echo $argv
end

function name --description 'Description'
    echo "Args: $argv"
end

function name --argument-names arg1 arg2
    echo "First: $arg1, Second: $arg2"
end

# Wrapping another command
function ls --wraps ls
    command ls --color=auto $argv
end
```

### Autoloading

Functions in `~/.config/fish/functions/name.fish` are autoloaded.

### Event Handlers

```fish
function handler --on-event fish_exit
    echo "Goodbye"
end

function handler --on-variable VAR
    echo "VAR changed to $VAR"
end

function handler --on-signal SIGINT
    echo "Interrupted"
end

function handler --on-job-exit $pid
    echo "Job $pid finished"
end
```

## Control Flow

### If

```fish
if condition
    # ...
else if other_condition
    # ...
else
    # ...
end
```

### Switch

```fish
switch $variable
case pattern1
    # ...
case 'pat2' 'pat3'
    # ...
case '*'
    # Default
end
```

Patterns support wildcards. No fallthrough.

### For

```fish
for var in list
    echo $var
end

for i in (seq 1 10)
    echo $i
end
```

### While

```fish
while condition
    # ...
end

while read -l line
    echo $line
end < file.txt
```

### Break and Continue

```fish
break                # Exit loop
continue             # Next iteration
```

### And/Or/Not

```fish
cmd1; and cmd2       # cmd2 runs if cmd1 succeeds
cmd1; or cmd2        # cmd2 runs if cmd1 fails
not cmd              # Invert exit status

# Also:
cmd1 && cmd2
cmd1 || cmd2
! cmd
```

### Begin/End

```fish
begin
    set -l local_var value
    cmd1
    cmd2
end
```

## Comments

```fish
# This is a comment
set var value  # Inline comment
```

No multiline comments; use `#` on each line.

## Test Command

```fish
# File tests
test -e file         # Exists
test -f file         # Regular file
test -d file         # Directory
test -L file         # Symlink
test -r file         # Readable
test -w file         # Writable
test -x file         # Executable
test -s file         # Non-empty

# String tests
test -n "$var"       # Non-empty string
test -z "$var"       # Empty string
test "$a" = "$b"     # Equal
test "$a" != "$b"    # Not equal

# Numeric tests
test $a -eq $b       # Equal
test $a -ne $b       # Not equal
test $a -lt $b       # Less than
test $a -le $b       # Less or equal
test $a -gt $b       # Greater than
test $a -ge $b       # Greater or equal

# Logical
test cond1 -a cond2  # AND
test cond1 -o cond2  # OR
test ! condition     # NOT
```

## Math

```fish
math 1 + 2
math "5 * 3"
math 10 / 3          # 3.333...
math "floor(10/3)"   # 3
math "2 ^ 10"        # 1024
math "sin(pi)"
math "abs(-5)"
```

Operators: `+ - * / ^ %`
Functions: `sin cos tan abs ceil floor log log10 sqrt round`
Constants: `pi e`

## String Command

```fish
string match [-r] PATTERN STRING
string replace [-a] [-r] OLD NEW STRING
string split DELIM STRING
string join DELIM STRINGS
string trim STRING
string upper STRING
string lower STRING
string length STRING
string sub -s START -l LENGTH STRING
string repeat -n COUNT STRING
string escape STRING
string unescape STRING
string pad -w WIDTH STRING
string collect STRINGS
```
