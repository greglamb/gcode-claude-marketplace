# Frequently Asked Questions

Common questions and gotchas when using fish shell.

---

## Variables

### How do I set an environment variable?

```fish
# Export a variable
set -gx EDITOR vim
set -gx PATH $PATH ~/bin

# For one command only
EDITOR=nano git commit
```

### How do I check if a variable is defined?

```fish
if set -q var
    echo "var is defined"
end
```

### How do I check if a variable is not empty?

```fish
# Method 1: string length
if string length -q -- $var
    echo "not empty"
end

# Method 2: test (must quote!)
if test -n "$var"
    echo "not empty"
end
```

### Why doesn't `set -Ux` work for EDITOR/PATH/etc?

A global variable of the same name already exists (from login scripts). The global takes precedence over universal. Add to config.fish instead:

```fish
set -gx EDITOR vim
```

---

## Configuration

### Where is fish's config file?

`~/.config/fish/config.fish`

Unlike bash, this file is read for ALL shells (interactive, login, scripts). Use guards:

```fish
if status is-interactive
    # Interactive-only config
end

if status is-login
    # Login-only config
end
```

### How do I change my prompt?

```fish
# Method 1: fish_config (web UI)
fish_config

# Method 2: Command line
fish_config prompt show
fish_config prompt choose disco
fish_config prompt save

# Method 3: Edit directly
funced fish_prompt
funcsave fish_prompt
```

### How do I change the greeting?

```fish
# Disable greeting
set -U fish_greeting

# Or set custom
set -U fish_greeting "Hello!"
```

### How do I customize colors?

```fish
fish_config theme show
fish_config theme choose coolbeans
fish_config theme save
```

---

## Syntax Differences

### Command substitution doesn't work!

Fish uses parentheses, not backticks:

```fish
# Wrong (backticks don't work)
set files `ls`

# Right
set files (ls)

# Also works (even in quotes)
echo "Today is $(date)"
```

### Why does `!!` not work?

Fish doesn't have history substitution. Instead:

- **Up arrow** - Recall last command
- **Alt+Up** - Recall last argument
- **Alt+S** - Prefix with sudo

Or create an abbreviation:

```fish
function last_history_item
    echo $history[1]
end
abbr -a !! --position anywhere --function last_history_item
```

### My command prints "No matches for wildcard"

Fish expands wildcards, and errors if no match. Quote or escape:

```fish
# Wrong
scp user@host:/dir/file-*

# Right
scp user@host:/dir/"file-*"
scp user@host:/dir/file-\*
```

### Output is one long string instead of words

Fish only splits command substitutions on newlines, not spaces:

```fish
# This gives 1 element with "a b c"
count (printf '%s ' a b c)

# This gives 3 elements
count (printf '%s\n' a b c)

# To split on spaces:
pkg-config --libs gtk+-2.0 | string split -n " "
```

---

## Exit Status

### How do I get exit status?

Use `$status` (not `$?`):

```fish
somecommand
echo $status

# Or check directly
if somecommand
    echo "succeeded"
else
    echo "failed"
end
```

### How do I check pipeline status?

```fish
# $pipestatus is a list of all exit statuses
cat file | grep pattern | wc
echo $pipestatus  # e.g., 0 1 0
```

---

## History

### How do I search history?

- **Ctrl+R** - Open searchable history pager
- **Up/Down** - Cycle through history
- Type partial command, then Up - Filter history

### How do I run a command from history?

1. Type part of the command
2. Press Up until you find it
3. Press Enter

Or use Ctrl+R to search.

---

## SSH/SCP Issues

### SSH gives "Received message too long" or similar

Your config.fish is outputting text in non-interactive shells. Guard it:

```fish
if status is-interactive
    # Your interactive stuff here
    fortune
    neofetch
end
```

---

## Common Gotchas

### test uses `=` not `==`

```fish
# Wrong
test "$a" == "$b"

# Right
test "$a" = "$b"
```

### `>` in test is redirection!

```fish
# Wrong (creates file named $b)
test $a > $b

# Right
test $a -gt $b
```

### Variables don't split on spaces

```fish
set foo "hello world"
mkdir $foo  # Creates ONE directory "hello world"

# To split:
for word in (string split ' ' $foo)
    echo $word
end
```

### No arithmetic expansion

```fish
# Wrong
echo $((1 + 1))

# Right
math 1 + 1
```

### No heredocs

```fish
# Wrong
cat << EOF
content
EOF

# Right
echo "content" | cat

# Or
printf '%s\n' "line 1" "line 2"
```

### No `[[` double brackets

```fish
# Wrong
[[ $a == $b ]]

# Right
test $a = $b
```

### Different process substitution

```fish
# Bash: <(command)
# Fish: (command | psub)

diff (sort a.txt | psub) (sort b.txt | psub)
```

---

## Display Issues

### Staircase effect / cursor issues

Terminal and fish disagree on character widths. Possible fixes:

```fish
# For emoji width issues
set -g fish_emoji_width 2

# For ambiguous width characters
set -g fish_ambiguous_width 1  # or 2
```

Also ensure terminal supports Unicode properly.

### Why does my prompt show `[I]`?

You have vi mode enabled. To change:

```fish
funced fish_mode_prompt
# Edit to your liking
funcsave fish_mode_prompt
```

---

## Uninstalling Fish

1. Change shell: `chsh -s /bin/bash`
2. Remove files:
   ```bash
   rm -rf ~/.config/fish
   # If installed via package manager, use that to uninstall
   ```

---

## Quick Reference: Bash to Fish

| Bash | Fish |
|------|------|
| `export VAR=val` | `set -gx VAR val` |
| `VAR=val` | `set VAR val` |
| `` `cmd` `` | `(cmd)` |
| `$?` | `$status` |
| `$@` | `$argv` |
| `$((1+1))` | `math 1+1` |
| `${var:-default}` | `set -q var; or set var default` |
| `if [ ]; then fi` | `if test; end` |
| `[[ ]]` | `test` (no double brackets) |
| `~/.bashrc` | `~/.config/fish/config.fish` |
| `!!` | Up arrow, or Alt+Up for last arg |
| `$!` | `$last_pid` |
| `$$` | `$fish_pid` |
