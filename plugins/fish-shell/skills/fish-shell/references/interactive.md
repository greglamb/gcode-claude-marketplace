# Fish Interactive Features

Features that make fish great for interactive use.

**URL:** https://fishshell.com/docs/current/interactive.html

---

## Autosuggestions

Fish suggests commands in gray based on history and completions.

- **Right Arrow / Ctrl+F** - Accept full suggestion
- **Alt+Right Arrow** - Accept one word
- **Alt+F** - Accept one word

Disable:

```fish
set -g fish_autosuggestion_enabled 0
```

## Tab Completion

Press **Tab** to complete commands, paths, options.

```fish
> git che<Tab>       # Completes to git checkout
> ls /us<Tab>        # Completes to /usr/
> ssh <Tab>          # Shows hosts from known_hosts
```

Fish has completions for 300+ commands built-in.

### Writing Completions

```fish
complete -c mycommand -s h -l help -d 'Show help'
complete -c mycommand -s f -l file -r -F -d 'Input file'
complete -c mycommand -a 'start stop restart' -d 'Action'
```

Save in `~/.config/fish/completions/mycommand.fish`.

## Syntax Highlighting

Fish highlights syntax in real-time:

- **Commands** - Valid commands colored, invalid in red
- **Paths** - Valid paths underlined
- **Options** - Different color for options
- **Strings** - Quoted text highlighted

Configure with `fish_config` or set variables:

```fish
set fish_color_command green
set fish_color_error red
set fish_color_param cyan
```

## Search Modes

### History Search

- **Up/Down Arrow** - Cycle through history
- **Ctrl+R** - Reverse history search (type to filter)
- **Ctrl+P / Ctrl+N** - Previous/next in history

### Pager Search

In completion pager:
- **Ctrl+S** - Search completions
- **Tab** - Cycle through matches
- **Shift+Tab** - Cycle backwards

## Key Bindings

Fish supports both Emacs (default) and Vi modes.

### Emacs Mode (Default)

| Key | Action |
|-----|--------|
| Ctrl+A | Move to beginning of line |
| Ctrl+E | Move to end of line |
| Ctrl+F | Move forward one character |
| Ctrl+B | Move backward one character |
| Alt+F | Move forward one word |
| Alt+B | Move backward one word |
| Ctrl+K | Kill (cut) to end of line |
| Ctrl+U | Kill entire line |
| Ctrl+W | Kill previous word |
| Ctrl+Y | Yank (paste) |
| Ctrl+C | Cancel current line |
| Ctrl+D | Delete character or exit if empty |
| Ctrl+L | Clear screen |
| Ctrl+R | Search history |
| Ctrl+Z | Suspend current job |
| Tab | Complete |
| Shift+Tab | Complete (reverse) |

### Vi Mode

Enable:

```fish
fish_vi_key_bindings
```

Or make default:

```fish
set -g fish_key_bindings fish_vi_key_bindings
```

Vi mode shows mode in prompt via `fish_mode_prompt`.

### Custom Bindings

```fish
# In ~/.config/fish/functions/fish_user_key_bindings.fish
function fish_user_key_bindings
    bind \cg 'git status'
    bind \e\[1\;5A 'history search --prefix'
end
```

List bindings: `bind`

## Abbreviations

Abbreviations expand as you type (before execution):

```fish
abbr -a gco git checkout
abbr -a gst git status
abbr -a ll ls -la
```

When you type `gco` and press **Space** or **Enter**, it expands to `git checkout`.

### Abbreviation Options

```fish
# Position anywhere (not just as command)
abbr -a --position anywhere -- -v --verbose

# Expand for specific command
abbr -a --command git co checkout

# With cursor positioning
abbr -a L --position anywhere --set-cursor "% | less"

# Using regex
abbr -a vim_edit_texts --regex ".+\.txt" --function vim_edit

# List
abbr --list

# Remove
abbr --erase gco
```

## Directory History

Fish remembers directories you've visited.

```fish
prevd                # Go to previous directory
nextd                # Go to next directory
dirh                 # Show directory history
cdh                  # Interactive directory picker
```

Or use `cd -` to go to the previous directory.

## Private Mode

Start fish without saving history:

```fish
fish --private
```

Or within fish:

```fish
fish_private_mode
```

## Colors and Themes

Configure via web interface:

```fish
fish_config
```

Or command line:

```fish
fish_config theme show
fish_config theme choose dracula
fish_config theme save
```

### Color Variables

```fish
set fish_color_normal normal
set fish_color_command green
set fish_color_keyword blue
set fish_color_quote yellow
set fish_color_redirection cyan
set fish_color_end green
set fish_color_error red
set fish_color_param cyan
set fish_color_comment brblack
set fish_color_selection --background=brblack
set fish_color_search_match --background=brblack
set fish_color_operator cyan
set fish_color_escape cyan
set fish_color_autosuggestion brblack
```

## Prompts

### Left Prompt

```fish
function fish_prompt
    set -l last_status $status
    set -l cwd (prompt_pwd)

    echo -n (set_color blue)$cwd(set_color normal)

    if test $last_status -ne 0
        echo -n (set_color red)' ✗'(set_color normal)
    end

    echo -n ' > '
end
```

### Right Prompt

```fish
function fish_right_prompt
    echo (set_color brblack)(date +%H:%M)(set_color normal)
end
```

### Git Prompt

Fish includes git support:

```fish
function fish_prompt
    echo (prompt_pwd) (fish_git_prompt) '> '
end
```

Configure with variables:

```fish
set __fish_git_prompt_showdirtystate yes
set __fish_git_prompt_showstashstate yes
set __fish_git_prompt_showuntrackedfiles yes
set __fish_git_prompt_showupstream auto
```

## Event Handlers

React to events:

```fish
function my_handler --on-event fish_exit
    echo "Goodbye!"
end

function my_cd_handler --on-variable PWD
    echo "Changed to $PWD"
end

function my_signal_handler --on-signal SIGINT
    echo "Interrupted"
end
```

## Job Control

```fish
> sleep 100 &        # Run in background
> jobs               # List jobs
> fg                 # Bring to foreground
> bg                 # Continue in background
> Ctrl+Z             # Suspend foreground job
> disown             # Detach job from shell
```

## Clipboard

```fish
fish_clipboard_copy     # Copy selection/commandline
fish_clipboard_paste    # Paste from clipboard
```

Default bindings:
- **Ctrl+X** then **Ctrl+C** - Copy
- **Ctrl+X** then **Ctrl+V** - Paste
