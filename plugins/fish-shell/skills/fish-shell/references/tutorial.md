# Fish Shell Tutorial

A beginner-friendly introduction to fish shell.

**URL:** https://fishshell.com/docs/current/tutorial.html

---

## Getting Started

Once installed, type `fish` to start:

```fish
> fish
Welcome to fish, the friendly interactive shell
Type help for instructions on how to use fish
you@hostname ~>
```

## Running Commands

Fish runs commands like other shells:

```fish
> echo hello world
hello world
```

Spaces with quotes or escapes:

```fish
> mkdir My\ Files
> cp ~/Some\ File 'My Files'
> ls "My Files"
```

## Getting Help

```fish
> help            # Open in browser
> man set         # Man page for 'set'
> help set        # Help for 'set' in browser
```

## Syntax Highlighting

Fish highlights as you type:
- **Red** = Invalid command
- **Normal color** = Valid command
- **Underlined** = Valid file path

Configure colors with `fish_config` or `fish_config theme choose none`.

## Autosuggestions

Fish suggests commands in gray to the right of cursor.

- Press **Right Arrow** or **Ctrl+F** to accept full suggestion
- Press **Alt+Right Arrow** to accept one word
- Just keep typing to ignore

Disable with:

```fish
set -g fish_autosuggestion_enabled 0
```

## Tab Completions

Press **Tab** to complete commands, arguments, or paths:

```fish
> /pri<Tab>              -> /private/
> git checkout b<Tab>    -> Shows branches
```

Fish has completions for many commands built-in.

## Variables

```fish
> echo My home directory is $HOME
My home directory is /home/tutorial

# In double quotes (expanded)
> echo "My current directory is $PWD"
My current directory is /home/tutorial

# In single quotes (literal)
> echo 'My current directory is $PWD'
My current directory is $PWD
```

### Setting Variables

```fish
> set name 'Mister Noodle'
> echo $name
Mister Noodle
```

**Important:** Variables are NOT split on spaces (unlike bash):

```fish
> mkdir $name
# Creates ONE directory "Mister Noodle", not two
```

Erase variables:

```fish
> set -e MyVariable
```

## Exports (Environment Variables)

To make variables available to external commands, export them:

```fish
> set -x MyVariable SomeValue
> env | grep MyVariable
MyVariable=SomeValue
```

Commonly:

```fish
set -gx EDITOR vim
set -gx PATH $PATH ~/bin
```

## Lists (Arrays)

All fish variables are lists:

```fish
> echo $PATH
/usr/bin /bin /usr/sbin /sbin /usr/local/bin

> count $PATH
5

# Append
> set PATH $PATH /new/path

# Access elements (1-indexed)
> echo $PATH[1]
/usr/bin

> echo $PATH[-1]
/usr/local/bin

# Slices
> echo $PATH[1..3]
/usr/bin /bin /usr/sbin
```

Iterate with for:

```fish
for val in $PATH
    echo "entry: $val"
end
```

## Wildcards

```fish
> ls *.jpg
lena.jpg meena.jpg

> ls /var/**.log     # Recursive
/var/log/system.log
/var/run/sntp.log
```

## Pipes and Redirections

```fish
> echo hello world | wc
      1       2      12

> grep fish < /etc/shells > ~/output.txt 2> ~/errors.txt

# Both stdout and stderr
> make &> make_output.txt
```

## Command Substitutions

Use `()` or `$()` (NOT backticks):

```fish
> echo In (pwd), running $(uname)
In /home/tutorial, running FreeBSD

> set os (uname)
> echo $os
Linux
```

## Separating Commands

Semicolons or newlines:

```fish
> echo hello; echo world
hello
world
```

## Exit Status

`$status` holds the exit status of the last command:

```fish
> false
> echo $status
1

> true
> echo $status
0
```

## Combiners

```fish
> ./configure && make && make install
# Runs each only if previous succeeded

> cat file.txt || echo "File not found"
# Runs second only if first failed
```

Or use `and`/`or`:

```fish
> cp file.txt backup.txt; and echo "Success"; or echo "Failed"
```

## Conditionals

```fish
if grep fish /etc/shells
    echo "Fish is available"
else
    echo "Fish is not installed"
end
```

Test with `test` command:

```fish
if test -d ~/.config/fish
    echo "Directory exists"
end

if test "$EDITOR" = vim
    echo "Using vim"
end
```

Combine conditions:

```fish
if test -f file.txt; and test -r file.txt
    echo "File exists and is readable"
end
```

## Functions

```fish
function say_hello
    echo Hello $argv
end

> say_hello World
Hello World
```

Functions are saved in `~/.config/fish/functions/`. Use `funcsave` to persist:

```fish
> funcsave say_hello
```

## Loops

### For Loop

```fish
for file in *.txt
    echo "File: $file"
end
```

### While Loop

```fish
while true
    echo "Still running"
    sleep 1
end
```

## Prompt

The prompt is a function called `fish_prompt`:

```fish
function fish_prompt
    echo (set_color green)(prompt_pwd)(set_color normal) '> '
end
```

To customize, run `fish_config` or edit `~/.config/fish/functions/fish_prompt.fish`.

## Startup Configuration

Configuration goes in `~/.config/fish/config.fish`:

```fish
# Set environment variables
set -gx EDITOR vim

# Add to PATH
fish_add_path ~/bin

# Abbreviations
abbr -a gst git status
```

Files in `~/.config/fish/conf.d/*.fish` are also sourced.

## Universal Variables

Universal variables persist and are shared across all fish sessions:

```fish
set -U fish_greeting "Welcome back!"
```

These are stored in `~/.config/fish/fish_variables`.
