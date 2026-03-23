# Fish for Bash Users

This document gives you a quick overview if you come from bash and want to know how fish differs.

**URL:** https://fishshell.com/docs/current/fish_for_bash_users.html

---

## Command Substitutions

Fish spells command substitutions as `$(command)` or `(command)`, but NOT backticks.

Fish only splits on newlines instead of `$IFS`. Use `string split` for other splits:

```fish
for i in (find . -print0 | string split0)
    echo $i
end
```

## Variables

Fish sets and erases variables with `set` instead of `VAR=VAL`:

```fish
# Global and exported (like export PAGER=less)
set -gx PAGER less

# Local variable (like local alocalvariable=foo)
set -l alocalvariable foo

# Erase a variable
set -e PAGER
```

`VAR=VAL` statements are available as environment overrides:

```fish
PAGER=cat git log
```

**No word splitting!** Once a variable has a value, that value stays as-is:

```fish
> set foo "bar baz"
> printf '"%s"\n' $foo
"bar baz"
# In bash this would print two lines!
```

All variables are lists (arrays):

```fish
> set var "foo bar" banana
> printf %s\n $var
foo bar
banana

# Access specific elements
echo $list[5..7]
```

## Wildcards (Globs)

Fish only supports `*` and `**` globs:

```fish
# Recursive glob
ls **/*.txt

# If glob doesn't match, command fails (like bash failglob)
```

Globbing doesn't happen on expanded variables:

```fish
set foo "*"
echo $foo  # prints literal *, not files
```

## Quoting

Fish has two quoting styles: `""` and `''`.

- Variables expand in double-quotes
- Nothing expands in single-quotes
- No `$''` syntax; escape sequences work when unquoted

```fish
> echo a\nb
a
b
```

## String Manipulation

Fish does NOT have `${foo%bar}`, `${foo#bar}`, or `${foo/bar/baz}`. Use `string` instead:

```fish
# Replace
> string replace bar baz "bar luhrmann"
baz luhrmann

# Split
> string split "," "foo,bar"
foo
bar

# Regex match
> echo bababa | string match -r 'aba$'
aba

# Pad
> string pad -c x -w 20 "foo"
xxxxxxxxxxxxxxxxxfoo

# Case
> string lower Foo
foo
> string upper Foo
FOO
```

## Special Variables

| Bash | Fish |
|------|------|
| `$*`, `$@`, `$1`... | `$argv` |
| `$?` | `$status` |
| `$$` | `$fish_pid` |
| `$#` | `count $argv` |
| `$!` | `$last_pid` |
| `$0` | `status filename` |
| `$-` | `status is-interactive` / `status is-login` |

## Process Substitution

Instead of `<(command)` fish uses `(command | psub)`:

```fish
diff (sort a.txt | psub) (sort b.txt | psub)
```

Or just use pipes:

```fish
command | source  # Instead of: source (command | psub)
```

## Heredocs

Fish does NOT have `<<EOF` heredocs. Use printf or echo:

```fish
printf %s\n "some string" "some more string"

# Or multiline echo
echo "some string
some more string"
```

## Test

Fish has POSIX-compatible `test` or `[`. No `[[`. No `==` (use `=`).

```fish
# Check variable exists
set -q foo

# Check element count
set -q foo[2]
```

## Arithmetic

Fish does NOT have `$((i+1))`. Use `math`:

```fish
> math $i + 1
> math 5 / 2
2.5
> math cos 2 x pi
1
> math '(5 + 2) * 4'
28
```

## Prompts

Fish does NOT use `$PS1`. The prompt is the output of `fish_prompt` function:

```fish
function fish_prompt
    set -l prompt_symbol '$'
    fish_is_root_user; and set prompt_symbol '#'

    echo -s (prompt_hostname) \
    (set_color blue) (prompt_pwd) \
    (set_color yellow) $prompt_symbol (set_color normal)
end
```

## Blocks and Loops

```fish
# Bash                          # Fish
for i in 1 2 3; do              for i in 1 2 3
   echo $i                          echo $i
done                            end

while true; do                  while true
   echo Weeee                       echo Weeeeeee
done                            end

if true; then                   if true
   echo Yes                         echo Yes
else                            else
   echo No                          echo No
fi                              end

foo() {                         function foo
   echo foo                         echo foo
}                               end
```

No `until` in fish. Use `while not` or `while !`.

## Subshells

Fish does NOT have `(...)` subshells. Use `begin; ...; end` for grouping:

```fish
begin
    set -lx foo bar
    command
end
# foo is no longer exported
```

For true subshells, use `fish -c`:

```fish
fish -c 'set foo bar'
# foo is not set here
```

## Builtins and Other Commands

| Bash | Fish |
|------|------|
| `alias x=y` | `alias x y` or `abbr -a x y` |
| `export VAR=val` | `set -gx VAR val` |
| `eval` | `eval` (same, but rarely needed) |
| `source` | `source` (same) |
| `type -t` | `type` |
| `command` | `command` (same) |

## Configuration Files

| Bash | Fish |
|------|------|
| `~/.bashrc` | `~/.config/fish/config.fish` |
| `~/.bash_profile` | `~/.config/fish/config.fish` (with `status is-login`) |
| `~/.inputrc` | `~/.config/fish/functions/fish_user_key_bindings.fish` |
