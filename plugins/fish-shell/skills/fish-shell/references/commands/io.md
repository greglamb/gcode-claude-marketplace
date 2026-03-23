# Input/Output Command Reference

Complete reference for I/O commands: `echo`, `printf`, `read`, and redirection syntax.

---

## echo - Print Text

```fish
echo [OPTIONS] [STRING ...]
```

### Options

| Option | Description |
|--------|-------------|
| `-n` | Don't print newline |
| `-s` | Don't separate arguments with spaces |
| `-e` | Interpret escape sequences |
| `-E` | Don't interpret escape sequences (default) |

### Examples

```fish
# Basic output
echo hello world
# Output: hello world

# No newline
echo -n "Enter name: "

# No spaces between arguments
echo -s a b c
# Output: abc

# Escape sequences (with -e)
echo -e "Line1\nLine2\tTabbed"
# Output:
# Line1
# Line2   Tabbed

# Variables
echo "Hello, $USER!"
echo "Path is $PATH"
```

### Escape Sequences (with -e)

| Escape | Description |
|--------|-------------|
| `\n` | Newline |
| `\t` | Tab |
| `\r` | Carriage return |
| `\\` | Backslash |
| `\a` | Bell |
| `\b` | Backspace |
| `\e` | Escape |

---

## printf - Formatted Output

```fish
printf FORMAT [ARGUMENT ...]
```

### Format Specifiers

| Specifier | Description |
|-----------|-------------|
| `%s` | String |
| `%d` or `%i` | Integer |
| `%f` | Float |
| `%e` | Scientific notation |
| `%x` | Hexadecimal (lowercase) |
| `%X` | Hexadecimal (uppercase) |
| `%o` | Octal |
| `%c` | Character |
| `%%` | Literal % |

### Modifiers

| Modifier | Description |
|----------|-------------|
| `-` | Left-align |
| `+` | Show sign |
| `0` | Zero-pad |
| `N` | Minimum width |
| `.N` | Precision |

### Examples

```fish
# Basic string
printf "%s\n" hello

# Integer
printf "%d\n" 42

# Float with precision
printf "%.2f\n" 3.14159
# Output: 3.14

# Width and padding
printf "%10s\n" hello
# Output:      hello

printf "%-10s|\n" hello
# Output: hello     |

# Zero padding
printf "%05d\n" 42
# Output: 00042

# Hexadecimal
printf "%x\n" 255
# Output: ff

printf "0x%X\n" 255
# Output: 0xFF

# Multiple arguments
printf "%s is %d years old\n" Alice 30
# Output: Alice is 30 years old

# Arguments cycle through format
printf "%s\n" a b c
# Output:
# a
# b
# c

# Table formatting
printf "%-20s %10s %10s\n" "Name" "Size" "Date"
printf "%-20s %10d %10s\n" "file.txt" 1234 "2024-01-01"
```

---

## Redirection

### Output Redirection

```fish
# Stdout to file (overwrite)
command > file.txt

# Stdout to file (append)
command >> file.txt

# Stderr to file
command 2> errors.txt

# Both stdout and stderr
command &> all.txt
command > file.txt 2>&1

# Stdout to stderr
command >&2

# Stderr to stdout (for piping)
command 2>&1 | grep error

# No clobber (fail if exists)
command >? file.txt

# Append without clobber
command >>? file.txt
```

### Input Redirection

```fish
# Read from file
command < file.txt

# Read from file, use /dev/null if missing
command <? maybe.txt
```

### Pipes

```fish
# Pipe stdout
command1 | command2

# Pipe stderr
command1 2>| command2

# Pipe both stdout and stderr
command1 &| command2
```

### Combining

```fish
# Redirect stdout, pipe stderr
command > out.txt 2>| grep error

# Complex pipeline
cat file.txt | grep pattern | sort | uniq > result.txt
```

### File Descriptors

```fish
# Close file descriptor
command 2>&-

# Redirect to specific FD
command >&3
```

---

## Here Documents (Alternatives)

Fish does NOT support `<<EOF` heredocs. Use alternatives:

### printf/echo

```fish
# Multi-line with printf
printf '%s\n' \
    "Line 1" \
    "Line 2" \
    "Line 3"

# Multi-line echo
echo "Line 1
Line 2
Line 3"
```

### String with newlines

```fish
set content "Line 1
Line 2
Line 3"
echo $content
```

### Cat with echo

```fish
# Write multi-line to file
begin
    echo "Line 1"
    echo "Line 2"
    echo "Line 3"
end > file.txt
```

---

## Process Substitution

Fish uses `(command | psub)` instead of `<(command)`:

```fish
# Compare two command outputs
diff (sort file1.txt | psub) (sort file2.txt | psub)

# Use command output as file
source (generate_config | psub)
```

---

## read (Quick Reference)

See `commands/variables.md` for complete reference.

```fish
# Basic read
read varname

# With prompt
read -P "Enter name: " name

# Silent (for passwords)
read -s -P "Password: " pass

# Split on delimiter
echo "a,b,c" | read -d ',' first second third

# Read into array
echo "a b c" | read -a items

# Line by line
while read -l line
    echo $line
end < file.txt
```

---

## Common Patterns

### Prompt for Input

```fish
read -P "Continue? [y/N] " response
if test "$response" = y -o "$response" = Y
    echo "Continuing..."
end
```

### Progress Indicator

```fish
for i in (seq 1 100)
    printf "\rProgress: %3d%%" $i
    sleep 0.1
end
echo
```

### Inline Password

```fish
mysql -u user -p(read -s -P "Password: ")
```

### Capture and Check Output

```fish
if set output (command)
    echo "Success: $output"
else
    echo "Command failed"
end
```

---

## Common Mistakes (Bash Users)

| Bash | Fish |
|------|------|
| `echo -e` | `echo -e` (same, but fish escapes work without it) |
| `echo $'text\n'` | `echo -e "text\n"` or `printf "text\n"` |
| `cat << EOF` | Use printf/echo (no heredocs) |
| `<(cmd)` | `(cmd \| psub)` |
| `>(cmd)` | (not supported) |
| `2>&1` | `2>&1` (same) |
| `&>` | `&>` (same) |
| `\|&` | `&\|` (different order!) |

### Key Differences

1. **No heredocs** - Use printf, echo, or begin/end blocks
2. **No `$'...'`** - Use echo -e or escape in unquoted strings
3. **psub for process substitution** - `(cmd | psub)` instead of `<(cmd)`
4. **Pipe order** - It's `&|` not `|&`
