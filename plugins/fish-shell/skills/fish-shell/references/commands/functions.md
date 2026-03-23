# Functions Command Reference

Complete reference for function-related commands: `function`, `functions`, `funced`, `funcsave`, `return`.

---

## function - Create a Function

```fish
function NAME [OPTIONS]; BODY; end
```

### Options

| Option | Description |
|--------|-------------|
| `-a, --argument-names NAMES` | Assign arguments to named variables (must be last option) |
| `-d, --description DESC` | Description for completions |
| `-w, --wraps CMD` | Inherit completions from CMD |
| `-S, --no-scope-shadowing` | Access variables from calling scope |
| `-V, --inherit-variable NAME` | Snapshot variable value at definition time |

### Event Handler Options

| Option | Description |
|--------|-------------|
| `-e, --on-event NAME` | Run on named event |
| `-v, --on-variable NAME` | Run when variable changes |
| `-j, --on-job-exit PID` | Run when job exits |
| `-p, --on-process-exit PID` | Run when process exits |
| `-s, --on-signal SIGSPEC` | Run on signal |

### Basic Functions

```fish
# Simple function
function greet
    echo "Hello, $argv!"
end

# With description
function greet --description 'Greet someone'
    echo "Hello, $argv!"
end

# With named arguments
function greet --argument-names name
    echo "Hello, $name!"
end

# Multiple named arguments
function add --argument-names a b
    math $a + $b
end

# Arguments still available in $argv
function debug --argument-names level
    echo "Level: $level"
    echo "All args: $argv"
end
```

### Wrapping Commands

```fish
# Wrap ls with color
function ls --wraps ls --description 'ls with color'
    command ls --color=auto $argv
end

# Wrap git
function g --wraps git
    git $argv
end
```

### Event Handlers

```fish
# Run on fish exit
function on_exit --on-event fish_exit
    echo "Goodbye!"
end

# Run when variable changes
function on_pwd_change --on-variable PWD
    echo "Changed to $PWD"
end

# Run when job exits
function notify_job --on-job-exit %1
    echo "Job finished!"
end

# Run on signal
function on_sigint --on-signal SIGINT
    echo "Interrupted!"
end

# Custom event
function on_deploy --on-event deploy_complete
    echo "Deployment finished!"
end
# Fire with: emit deploy_complete
```

### Scope Control

```fish
# Normal: local scope shadows caller
function normal
    set x 'local'  # doesn't affect caller's x
end

# No scope shadowing: shares caller's scope
function transparent --no-scope-shadowing
    set x 'modified'  # modifies caller's x!
end

# Inherit variable: snapshot at definition
function closure --inherit-variable counter
    echo "Counter was: $counter"
end
set counter 5
closure  # prints 5
set counter 10
closure  # still prints 5
```

### Reserved Words (Cannot Be Function Names)

These are reserved: `[`, `_`, `and`, `argparse`, `begin`, `break`, `builtin`, `case`, `command`, `continue`, `else`, `end`, `eval`, `exec`, `for`, `function`, `if`, `not`, `or`, `read`, `return`, `set`, `status`, `string`, `switch`, `test`, `time`, `while`

---

## functions - List and Manage Functions

```fish
functions [OPTIONS] [FUNCTION ...]
```

### Options

| Option | Description |
|--------|-------------|
| `-n, --names` | List all function names |
| `-a, --all` | Include underscore-prefixed functions |
| `-c, --copy OLD NEW` | Copy function |
| `-d, --description DESC FUNC` | Set description |
| `-e, --erase FUNC` | Delete function |
| `-q, --query FUNC` | Test if function exists |
| `-D, --details FUNC` | Show where function is defined |
| `-H, --handlers` | Show event handlers |

### Examples

```fish
# List all function names
functions -n

# Show function definition
functions my_function

# Check if function exists
if functions -q my_function
    echo "exists"
end

# Copy a function
functions -c original copy

# Delete a function
functions -e my_function

# Show where function is defined
functions -D my_function
```

---

## funced - Edit a Function

```fish
funced [OPTIONS] FUNCTION
```

Opens the function in your `$EDITOR`.

### Options

| Option | Description |
|--------|-------------|
| `-e, --editor CMD` | Use specific editor |
| `-i, --interactive` | Edit interactively (default) |
| `-s, --save` | Save after editing |

```fish
# Edit function (opens in $EDITOR)
funced my_function

# Edit and save
funced -s my_function

# Use specific editor
funced -e nano my_function
```

---

## funcsave - Save a Function

```fish
funcsave FUNCTION
```

Saves the function to `~/.config/fish/functions/FUNCTION.fish`.

```fish
# Define and save a function
function greet
    echo "Hello!"
end
funcsave greet
# Creates ~/.config/fish/functions/greet.fish
```

---

## return - Return from Function

```fish
return [STATUS]
```

Returns from the current function with optional exit status.

```fish
function check_file
    if not test -f $argv[1]
        return 1  # failure
    end
    return 0  # success
end

# Use in conditional
if check_file myfile.txt
    echo "File exists"
end
```

---

## Function Autoloading

Functions in `~/.config/fish/functions/NAME.fish` are automatically loaded when called.

```fish
# ~/.config/fish/functions/greet.fish
function greet
    echo "Hello, $argv!"
end
```

The file MUST contain a function with the same name as the filename.

---

## Alias vs Function

```fish
# alias is just a wrapper around function
alias ll 'ls -la'

# Equivalent to:
function ll --wraps ls --description 'alias ll=ls -la'
    ls -la $argv
end

# Save alias as function
alias --save ll 'ls -la'
```

---

## Complete Example: Wrapping a Command

```fish
# Wrap git with useful defaults
function git --wraps git --description 'git with color'
    # Use command to call the real git
    command git -c color.ui=always $argv
end

# More complex wrapper
function rm --wraps rm --description 'rm with confirmation'
    if isatty stdin
        command rm -i $argv
    else
        command rm $argv
    end
end
```

---

## Common Mistakes (Bash Users)

| Bash | Fish |
|------|------|
| `function f() { ... }` | `function f; ... end` |
| `f() { ... }` | `function f; ... end` |
| `local var=val` | `set -l var val` |
| `return` (no value) | `return` (same) |
| `$1`, `$2`, etc. | `$argv[1]`, `$argv[2]` |
| `$@` | `$argv` |
| `$#` | `count $argv` |
| `shift` | `set -e argv[1]` or use argument names |

### Argument Handling

```fish
# Bash style (using $argv)
function greet
    echo "Hello, $argv[1]!"
end

# Fish style (named arguments)
function greet --argument-names name
    echo "Hello, $name!"
end

# Both are available
function both --argument-names first second
    echo "First: $first"
    echo "Second: $second"
    echo "All: $argv"
end
```

### Using `command` to Call External

```fish
# Inside a wrapper, use 'command' to avoid recursion
function ls --wraps ls
    command ls --color=auto $argv
end

# 'command' calls the external command, not your function
```
