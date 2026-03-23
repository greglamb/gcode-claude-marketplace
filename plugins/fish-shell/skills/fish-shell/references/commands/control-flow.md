# Control Flow Command Reference

Complete reference for control flow commands: `if`, `else`, `switch`, `case`, `for`, `while`, `break`, `continue`, `and`, `or`, `not`, `begin`, `end`.

---

## if / else if / else

Conditional execution.

```fish
if CONDITION
    COMMANDS
else if OTHER_CONDITION
    COMMANDS
else
    COMMANDS
end
```

**Key difference from bash:** No `then`, no `fi`. Use `end`.

### Examples

```fish
# Basic if
if test -f myfile.txt
    echo "File exists"
end

# if-else
if test $status -eq 0
    echo "Success"
else
    echo "Failure"
end

# if-else if-else
if test $count -lt 10
    echo "Small"
else if test $count -lt 100
    echo "Medium"
else
    echo "Large"
end

# Using command exit status
if grep -q pattern file.txt
    echo "Pattern found"
end

# Negation
if not test -f file.txt
    echo "File missing"
end

# Combined conditions
if test -f file.txt; and test -r file.txt
    echo "File exists and is readable"
end
```

---

## switch / case

Pattern matching on values.

```fish
switch VALUE
case PATTERN1
    COMMANDS
case PATTERN2 PATTERN3
    COMMANDS
case '*'
    COMMANDS
end
```

**Key difference from bash:** No `;;`, no `esac`. Patterns are glob-style. **No fallthrough.**

### Patterns

- `*` - Match any string
- `?` - Match single character
- `[abc]` - Match character class
- Multiple patterns per case (space-separated)

### Examples

```fish
# Basic switch
switch $animal
case dog
    echo "Woof"
case cat
    echo "Meow"
case '*'
    echo "Unknown animal"
end

# Multiple patterns
switch $fruit
case apple pear
    echo "Pome fruit"
case banana orange
    echo "Tropical"
case '*'
    echo "Other"
end

# Wildcard patterns
switch $file
case '*.txt'
    echo "Text file"
case '*.jpg' '*.png' '*.gif'
    echo "Image file"
case '*'
    echo "Unknown type"
end

# Character class
switch $char
case '[aeiou]'
    echo "Vowel"
case '[0-9]'
    echo "Digit"
end

# Match command-line flags
switch $argv[1]
case -h --help
    echo "Help message"
case -v --version
    echo "Version 1.0"
case '-*'
    echo "Unknown option: $argv[1]"
case '*'
    echo "Argument: $argv[1]"
end
```

---

## for

Iterate over a list.

```fish
for VAR in LIST
    COMMANDS
end
```

**Key difference from bash:** No `do`, no `done`. Use `end`.

### Examples

```fish
# Iterate over literal values
for color in red green blue
    echo $color
end

# Iterate over variable (list)
set fruits apple banana cherry
for fruit in $fruits
    echo $fruit
end

# Iterate over command output
for file in (ls *.txt)
    echo "Processing $file"
end

# Iterate over range
for i in (seq 1 10)
    echo $i
end

# Iterate over files (glob)
for file in *.txt
    echo $file
end

# Recursive glob
for file in **/*.py
    echo "Python file: $file"
end

# Iterate over arguments
for arg in $argv
    echo "Argument: $arg"
end

# Break and continue
for i in (seq 1 10)
    if test $i -eq 5
        continue  # skip 5
    end
    if test $i -eq 8
        break     # stop at 8
    end
    echo $i
end
```

---

## while

Loop while condition is true.

```fish
while CONDITION
    COMMANDS
end
```

### Examples

```fish
# Basic while
set count 0
while test $count -lt 5
    echo $count
    set count (math $count + 1)
end

# Read lines from file
while read -l line
    echo "Line: $line"
end < file.txt

# Read from command
echo -e "a\nb\nc" | while read -l letter
    echo "Got: $letter"
end

# Infinite loop with break
while true
    read -P "Enter 'quit' to exit: " input
    if test "$input" = quit
        break
    end
end

# Until pattern (no until keyword)
while not test -f /tmp/ready
    echo "Waiting..."
    sleep 1
end
```

---

## break / continue

Control loop execution.

```fish
break     # Exit the innermost loop
continue  # Skip to next iteration
```

```fish
for i in (seq 1 10)
    if test $i -eq 3
        continue  # skip 3
    end
    if test $i -eq 7
        break     # stop before 7
    end
    echo $i
end
# Output: 1 2 4 5 6
```

---

## and / or / not

Boolean operators.

```fish
# and - run if previous succeeded
COMMAND1; and COMMAND2

# or - run if previous failed
COMMAND1; or COMMAND2

# not - invert exit status
not COMMAND

# Also available as && and ||
COMMAND1 && COMMAND2
COMMAND1 || COMMAND2
! COMMAND
```

### Examples

```fish
# Sequential execution with and
test -f file.txt; and cat file.txt

# Short-circuit or
test -f file.txt; or echo "File not found"

# Chain with &&
mkdir -p dir && cd dir && touch file

# Default value pattern
set -q var; or set var default

# Invert condition
if not test -f file.txt
    echo "Missing"
end

# Combined
test -f a.txt; and test -f b.txt; and echo "Both exist"
```

### Precedence

`and` and `or` have the same precedence and associate left-to-right.

```fish
# This:
false; and true; or echo "printed"

# Is parsed as:
((false; and true); or echo "printed")

# So "printed" appears because (false && true) = false, then || runs
```

---

## begin / end

Group commands into a block.

```fish
begin
    COMMANDS
end
```

### Uses

1. **Group for redirection**
2. **Create local scope**
3. **Group for logical operators**

### Examples

```fish
# Redirect a block
begin
    echo "Line 1"
    echo "Line 2"
end > output.txt

# Local scope
begin
    set -l temp "temporary"
    echo $temp
end
# temp is gone here

# Group for or/and
begin
    cd /some/dir
    and make
    and make install
end; or echo "Failed"

# Temporarily change variable
begin
    set -lx PATH /custom/bin $PATH
    my_command
end
# PATH is restored
```

---

## Complete Examples

### Parse Command-Line Arguments

```fish
function mycommand
    set -l verbose false
    set -l files

    for arg in $argv
        switch $arg
        case -v --verbose
            set verbose true
        case '-*'
            echo "Unknown option: $arg" >&2
            return 1
        case '*'
            set -a files $arg
        end
    end

    for file in $files
        if $verbose
            echo "Processing: $file"
        end
        # do something with $file
    end
end
```

### Process Pipeline with Error Handling

```fish
if cat file.txt | grep -q pattern
    echo "Found"
else
    echo "Not found or error"
end

# Check specific pipeline status
cat file.txt | grep pattern | wc -l
if test $pipestatus[2] -eq 0
    echo "grep succeeded"
end
```

---

## Common Mistakes (Bash Users)

| Bash | Fish |
|------|------|
| `if [ ]; then ... fi` | `if test ...; ... end` |
| `if [[ ]]; then ... fi` | `if test ...; ... end` (no `[[`) |
| `for i in; do ... done` | `for i in; ... end` |
| `while ...; do ... done` | `while ...; ... end` |
| `case in) ;; esac` | `switch; case; end` |
| `until ...; do ... done` | `while not ...; ... end` |
| `[[ $a == $b ]]` | `test $a = $b` (single `=`) |
| `&&` inside `[[ ]]` | `; and` or `-a` in test |
| `cmd1 && cmd2` | `cmd1; and cmd2` or `cmd1 && cmd2` |
| `((i++))` | `set i (math $i + 1)` |

### No C-style for Loop

```fish
# Bash: for ((i=0; i<10; i++))
# Fish:
for i in (seq 0 9)
    echo $i
end
```

### No Arithmetic Expressions in Test

```fish
# Wrong: if test $a > $b (this is redirection!)
# Right:
if test $a -gt $b
    echo "a is greater"
end
```
