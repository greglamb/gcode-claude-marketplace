# String Command Reference

Complete reference for the `string` command and all subcommands.

**URL:** https://fishshell.com/docs/current/cmds/string.html

---

## Overview

`string` performs operations on strings. Arguments are read from the command line or stdin (one STRING per line).

**Common options:**
- `-q, --quiet` - Suppress output, just set exit status
- Most subcommands return 0 on success, 1 on failure

---

## string collect

Join strings into one, preserving newlines.

```fish
string collect [-a | --allow-empty] [-N | --no-trim-newlines] [STRING ...]
```

**Options:**
- `-a, --allow-empty` - Print empty string if no input (prevents argument from disappearing)
- `-N, --no-trim-newlines` - Keep trailing newlines

**Use case:** Capture multiline command output into a single variable element.

```fish
# Collect multiline output (like "$(...)" in bash)
set contents (cat file.txt | string collect)

# Preserve trailing newlines
set contents (cat file.txt | string collect -N)

# Prevent empty argument from disappearing
echo foo(true | string collect --allow-empty)bar
# Output: foobar
```

---

## string escape / unescape

Escape or unescape special characters.

```fish
string escape [-n | --no-quoted] [--style=] [STRING ...]
string unescape [--style=] [STRING ...]
```

**Styles:**
- `--style=script` (default) - Escape for `eval`
- `--style=var` - Escape for use as variable name
- `--style=url` - URL encoding
- `--style=regex` - Escape for literal regex matching

```fish
# Escape for shell
string escape 'hello world'
# Output: 'hello world'

# URL encode
string escape --style=url 'hello world'
# Output: hello%20world

# Variable-safe name
string escape --style=var 'my-var'
# Output: my_2D_var

# Regex literal
string escape --style=regex 'a.b*c'
# Output: a\.b\*c
```

---

## string join / join0

Join strings with a delimiter.

```fish
string join [-q | --quiet] [-n | --no-empty] SEP [STRING ...]
string join0 [-q | --quiet] [STRING ...]
```

**Options:**
- `-n, --no-empty` - Exclude empty strings
- `string join0` uses NUL byte separator (for tools like `sort -z`)

```fish
# Join with delimiter
string join ',' a b c
# Output: a,b,c

# Join without separator
string join '' a b c
# Output: abc

# Skip empty strings
string join -n '+' a b '' c
# Output: a+b+c

# Join with newlines
seq 3 | string join '...'
# Output: 1...2...3

# NUL-delimited for external tools
string join0 file1 file2 file3 | xargs -0 rm
```

---

## string length

Print string lengths.

```fish
string length [-q | --quiet] [-V | --visible] [STRING ...]
```

**Options:**
- `-V, --visible` - Count visible width (ignores escape sequences, handles emoji)

```fish
# Basic length
string length 'hello'
# Output: 5

# Check if non-empty (like test -n)
if string length -q -- $var
    echo "var is not empty"
end

# Visible width (ignores color codes)
string length --visible (set_color red)hello
# Output: 5
```

---

## string lower / upper

Convert case.

```fish
string lower [-q | --quiet] [STRING ...]
string upper [-q | --quiet] [STRING ...]
```

```fish
string lower 'HELLO'
# Output: hello

string upper 'hello'
# Output: HELLO

# Piped input
echo 'Mixed Case' | string lower
# Output: mixed case
```

---

## string match

Match substrings using globs or regex.

```fish
string match [-a | --all] [-e | --entire] [-i | --ignore-case]
             [-g | --groups-only] [-r | --regex] [-n | --index]
             [-q | --quiet] [-v | --invert] [-m MAX] PATTERN [STRING ...]
```

**Options:**
- `-a, --all` - Report all matches (not just first)
- `-e, --entire` - Print entire string even if only part matches
- `-i, --ignore-case` - Case insensitive
- `-g, --groups-only` - Only print capture groups (requires -r)
- `-r, --regex` - Use PCRE2 regex instead of glob
- `-n, --index` - Print match position and length
- `-v, --invert` - Print non-matching strings
- `-m, --max-matches` - Stop after MAX matches

### Glob Matching (Default)

```fish
# Exact match
string match 'foo' 'foo'
# Output: foo

# Wildcard
string match 'f*' 'foo' 'bar'
# Output: foo

# Match options (use -- to separate)
string match -- '-*' '-h' '--version'
# Output: -h
# Output: --version

# Entire string with partial match
string match -e 'oo' 'foo' 'bar'
# Output: foo
```

### Regex Matching

```fish
# Basic regex
string match -r 'cat|dog|fish' 'nice dog'
# Output: dog

# Capture groups
string match -r '(\d+):(\d+)' '12:34'
# Output: 12:34
# Output: 12
# Output: 34

# Named capture groups (sets variables!)
string match -rq '(?<hour>\d+):(?<min>\d+)' '12:34'
echo $hour:$min
# Output: 12:34

# Case insensitive
string match -ri 'hello' 'HELLO world'
# Output: HELLO

# Match index and length
string match -rn 'at' 'ratatat'
# Output: 2 2

# All matches with index
string match -ran 'at' 'ratatat'
# Output: 2 2
# Output: 4 2
# Output: 6 2

# Groups only (no full match)
string match -rg '(\w+)@(\w+)' 'user@host'
# Output: user
# Output: host

# Invert (non-matching)
string match -rv 'error' 'info: ok' 'error: fail' 'info: done'
# Output: info: ok
# Output: info: done
```

---

## string pad

Pad strings to a fixed width.

```fish
string pad [-r | --right] [(-c | --char) CHAR] [(-w | --width) WIDTH] [STRING ...]
```

**Options:**
- `-r, --right` - Right-pad (left-align) instead of left-pad
- `-c, --char` - Padding character (default: space)
- `-w, --width` - Target width (default: widest input)

```fish
# Pad to width
string pad -w 10 'foo'
# Output:        foo

# Right pad (left align)
string pad -r -w 10 'foo'
# Output: foo

# Custom character
string pad -c '0' -w 5 '42'
# Output: 00042

# Align multiple strings
string pad 'a' 'bb' 'ccc'
# Output:   a
# Output:  bb
# Output: ccc
```

---

## string repeat

Repeat strings.

```fish
string repeat [(-n | --count) COUNT] [(-m | --max) MAX] [-N | --no-newline]
              [-q | --quiet] [STRING ...]
```

**Options:**
- `-n, --count` - Number of repetitions
- `-m, --max` - Maximum output characters
- `-N, --no-newline` - Don't add newline

```fish
# Repeat n times
string repeat -n 3 'ab'
# Output: ababab

# Limit total length
string repeat -n 100 -m 10 'ab'
# Output: ababababab

# Simpler form (count as first arg)
string repeat 3 'ab'
# Output: ababab
```

---

## string replace

Replace substrings.

```fish
string replace [-a | --all] [-f | --filter] [-i | --ignore-case]
               [-r | --regex] [-q | --quiet] PATTERN REPLACE [STRING ...]
```

**Options:**
- `-a, --all` - Replace all occurrences (not just first)
- `-f, --filter` - Only print strings that had replacements
- `-i, --ignore-case` - Case insensitive matching
- `-r, --regex` - Use PCRE2 regex

```fish
# Simple replace
string replace 'old' 'new' 'old text old'
# Output: new text old

# Replace all
string replace -a 'old' 'new' 'old text old'
# Output: new text new

# Regex replace
string replace -r '(\w+)@(\w+)' '$2/$1' 'user@host'
# Output: host/user

# Filter (only modified strings)
string replace -f 'error' 'ERROR' 'info: ok' 'error: bad'
# Output: ERROR: bad

# Case insensitive
string replace -i 'hello' 'hi' 'HELLO world'
# Output: hi world

# Regex with all
string replace -ra '\s+' ' ' 'too    many   spaces'
# Output: too many spaces

# Remove pattern (empty replacement)
string replace -a 'x' '' 'xaxbxcx'
# Output: abc
```

---

## string shorten

Shorten strings to a maximum width.

```fish
string shorten [(-c | --char) CHARS] [(-m | --max) WIDTH]
               [-N | --no-newline] [-l | --left] [-q | --quiet] [STRING ...]
```

**Options:**
- `-c, --char` - Ellipsis characters (default: `...`)
- `-m, --max` - Maximum width
- `-l, --left` - Shorten from left instead of right

```fish
# Shorten to width
string shorten -m 10 'This is a long string'
# Output: This is...

# Custom ellipsis
string shorten -m 10 -c '>' 'This is a long string'
# Output: This is a>

# Shorten from left
string shorten -m 10 -l 'This is a long string'
# Output: ...g string
```

---

## string split / split0

Split strings on a delimiter.

```fish
string split [(-f | --fields) FIELDS] [(-m | --max) MAX] [-n | --no-empty]
             [-q | --quiet] [-r | --right] SEP [STRING ...]
string split0 [(-f | --fields) FIELDS] [(-m | --max) MAX] [-n | --no-empty]
              [-q | --quiet] [-r | --right] [STRING ...]
```

**Options:**
- `-f, --fields` - Output specific fields (1-indexed, comma-separated)
- `-m, --max` - Maximum splits
- `-n, --no-empty` - Skip empty results
- `-r, --right` - Split from right

```fish
# Basic split
string split ',' 'a,b,c'
# Output: a
# Output: b
# Output: c

# Limit splits
string split -m 1 ',' 'a,b,c'
# Output: a
# Output: b,c

# Select fields
string split -f 1,3 ',' 'a,b,c'
# Output: a
# Output: c

# Split from right
string split -r -m 1 '/' '/path/to/file'
# Output: /path/to
# Output: file

# No empty strings
string split -n ':' 'a::b'
# Output: a
# Output: b

# Split on NUL (for find -print0 output)
find . -print0 | string split0 | head -5
```

---

## string sub

Extract substrings.

```fish
string sub [(-s | --start) START] [(-e | --end) END] [(-l | --length) LENGTH]
           [-q | --quiet] [STRING ...]
```

**Options:**
- `-s, --start` - Start position (1-indexed, negative from end)
- `-e, --end` - End position (1-indexed, negative from end)
- `-l, --length` - Number of characters

```fish
# From start with length
string sub -l 5 'hello world'
# Output: hello

# From position
string sub -s 7 'hello world'
# Output: world

# From position with length
string sub -s 7 -l 3 'hello world'
# Output: wor

# Negative index (from end)
string sub -s -5 'hello world'
# Output: world

# Range with end
string sub -s 1 -e 5 'hello world'
# Output: hello

# Negative end
string sub -s 1 -e -6 'hello world'
# Output: hello
```

---

## string trim

Remove leading/trailing characters.

```fish
string trim [-l | --left] [-r | --right] [(-c | --chars) CHARS]
            [-q | --quiet] [STRING ...]
```

**Options:**
- `-l, --left` - Trim left only
- `-r, --right` - Trim right only
- `-c, --chars` - Characters to trim (default: whitespace)

```fish
# Trim whitespace
string trim '  hello  '
# Output: hello

# Trim left only
string trim -l '  hello  '
# Output: hello

# Trim right only
string trim -r '  hello  '
# Output:   hello

# Trim specific characters
string trim -c 'xy' 'xxyhelloxyy'
# Output: hello
```

---

## Regular Expressions

Both `match` and `replace` support PCRE2 regex with `-r`.

### Pattern Syntax

**Repetition:**
- `*` - 0 or more
- `+` - 1 or more
- `?` - 0 or 1
- `{n}` - Exactly n
- `{n,m}` - n to m times
- `{n,}` - n or more

**Character classes:**
- `.` - Any character (except newline)
- `\d` - Digit, `\D` - Non-digit
- `\s` - Whitespace, `\S` - Non-whitespace
- `\w` - Word character, `\W` - Non-word
- `[abc]` - Character set
- `[^abc]` - Negated set
- `[a-z]` - Range
- `[[:alnum:]]` - POSIX class

**Groups:**
- `(...)` - Capturing group
- `(?:...)` - Non-capturing group
- `(?<name>...)` - Named capturing group
- `\1` - Backreference in pattern
- `$1` - Reference in replacement

**Anchors:**
- `^` - Start of string/line
- `$` - End of string/line
- `\b` - Word boundary
- `\B` - Non-word boundary

**Other:**
- `|` - Alternation (or)
- `\` - Escape special character

### Capture Group Examples

```fish
# Numbered groups in replacement
string replace -r '(\w+)@(\w+)\.(\w+)' 'User: $1, Domain: $2.$3' 'john@example.com'
# Output: User: john, Domain: example.com

# Named groups (sets variables)
string match -rq '(?<name>\w+)@(?<domain>\w+)' 'john@example'
echo "Name: $name, Domain: $domain"
# Output: Name: john, Domain: example

# Backreference in pattern
string match -r '(\w+) \1' 'hello hello'
# Output: hello hello
# Output: hello
```

---

## Common Mistakes (Bash Users)

| Bash | Fish |
|------|------|
| `${var#pattern}` | `string replace -r '^pattern' '' $var` |
| `${var%pattern}` | `string replace -r 'pattern$' '' $var` |
| `${var/old/new}` | `string replace 'old' 'new' $var` |
| `${var//old/new}` | `string replace -a 'old' 'new' $var` |
| `${var:0:5}` | `string sub -l 5 $var` |
| `${var:5}` | `string sub -s 6 $var` |
| `${#var}` | `string length $var` |
| `${var,,}` | `string lower $var` |
| `${var^^}` | `string upper $var` |
