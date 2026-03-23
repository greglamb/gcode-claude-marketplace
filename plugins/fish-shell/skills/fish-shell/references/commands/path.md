# Path Command Reference

Complete reference for the `path` command (fish 3.4+) for path manipulation.

---

## Overview

```fish
path SUBCOMMAND [OPTIONS] [PATH ...]
```

Paths are read from command line or stdin (one per line).

### Common Options

| Option | Description |
|--------|-------------|
| `-q, --quiet` | Suppress output, exit status only |
| `-z, --null-in` | Read NUL-delimited input |
| `-Z, --null-out` | Output NUL-delimited |

---

## path basename

Get the filename part of a path.

```fish
path basename [-E | --no-extension] [PATH ...]
```

**Options:**
- `-E, --no-extension` - Also remove extension

```fish
path basename /usr/bin/fish
# Output: fish

path basename ./foo.txt
# Output: foo.txt

path basename -E ./foo.txt
# Output: foo

path basename /usr/bin/
# Output: bin

# Process multiple files
path basename /usr/bin/*
# Output: all filenames in /usr/bin
```

---

## path dirname

Get the directory part of a path.

```fish
path dirname [PATH ...]
```

```fish
path dirname /usr/bin/fish
# Output: /usr/bin

path dirname ./foo.txt
# Output: .

path dirname ../banana
# Output: ..
```

---

## path extension

Get the file extension (including dot).

```fish
path extension [PATH ...]
```

```fish
path extension ./foo.mp4
# Output: .mp4

path extension README
# Output: (empty, status 1)

path extension .gitignore
# Output: (empty - hidden file, not extension)

path extension foo.tar.gz
# Output: .gz
```

---

## path change-extension

Change or remove file extension.

```fish
path change-extension EXTENSION [PATH ...]
```

```fish
path change-extension mp4 video.wmv
# Output: video.mp4

path change-extension .mp4 video.wmv
# Output: video.mp4

# Remove extension
path change-extension '' video.mp4
# Output: video

# Add extension
path change-extension txt README
# Output: README.txt
```

---

## path filter

Filter paths by type and permissions. **Paths must exist.**

```fish
path filter [-v | --invert] [TYPE_OPTIONS] [PERM_OPTIONS] [PATH ...]
```

### Type Options

| Option | Description |
|--------|-------------|
| `-d` or `--type=dir` | Directory |
| `-f` or `--type=file` | Regular file |
| `-l` or `--type=link` | Symbolic link |
| `--type=block` | Block device |
| `--type=char` | Character device |
| `--type=fifo` | Named pipe |
| `--type=socket` | Socket |

### Permission Options

| Option | Description |
|--------|-------------|
| `-r` or `--perm=read` | Readable |
| `-w` or `--perm=write` | Writable |
| `-x` or `--perm=exec` | Executable |
| `--perm=suid` | Set-user-ID |
| `--perm=sgid` | Set-group-ID |
| `--perm=user` | Owned by current user |
| `--perm=group` | Owned by current group |

### Logic

- Types are OR'd (any matching type passes)
- Permissions are AND'd (all must match)
- Nonexistent paths are always filtered out

```fish
# Only directories
path filter -d /usr /usr/bin /usr/bin/fish
# Output: /usr /usr/bin

# Executable files
path filter -fx /usr/bin/*
# Output: all executable files

# Writable directories
path filter -dw ~/projects/*

# Invert (non-matching)
path filter -v -f *
# Output: all non-files (directories, etc.)

# Multiple types (comma or multiple options)
path filter -t dir,file /path/to/things
path filter --type dir --type file /path/to/things
```

---

## path is

Check if paths match criteria (like `path filter -q`).

```fish
path is [TYPE_OPTIONS] [PERM_OPTIONS] [PATH ...]
```

Returns 0 if any path matches, no output.

```fish
# Check if file exists and is executable
if path is -fx /usr/bin/fish
    echo "fish is executable"
end

# Check if directory exists
if path is -d ~/projects
    echo "projects directory exists"
end

# Check readable
path is -r /etc/passwd
echo $status  # 0 if readable
```

---

## path normalize

Normalize path (collapse `.` and `..`, remove duplicate `/`).

Does NOT resolve symlinks or make paths absolute.

```fish
path normalize [PATH ...]
```

```fish
path normalize /usr/bin//../../etc/fish
# Output: /etc/fish

path normalize ./foo/../bar
# Output: bar

path normalize /bin//bash
# Output: /bin/bash (doesn't resolve symlinks)

path normalize ./my/subdirs/../sub2
# Output: my/sub2
```

---

## path resolve

Resolve to absolute, canonical path (resolves symlinks).

```fish
path resolve [PATH ...]
```

```fish
path resolve .
# Output: /home/user/current_dir

path resolve /bin/sh
# Output: /usr/bin/bash (if /bin is symlink and sh is bash)

path resolve ./relative/path
# Output: /absolute/path/to/relative/path

# Resolves as far as possible for non-existent paths
path resolve /bin/nonexistent/path
# Output: /usr/bin/nonexistent/path
```

---

## path mtime

Get modification time (seconds since epoch).

```fish
path mtime [-R | --relative] [PATH ...]
```

**Options:**
- `-R, --relative` - Print seconds since modification

```fish
path mtime /etc/passwd
# Output: 1657213796

path mtime -R /etc/passwd
# Output: 4078 (seconds ago)

# Compare files
if test (path mtime a.txt) -gt (path mtime b.txt)
    echo "a.txt is newer"
end

# Or use test -nt directly
if test a.txt -nt b.txt
    echo "a.txt is newer"
end
```

---

## path sort

Sort paths (natural sort like globs).

```fish
path sort [-r | --reverse] [-u | --unique] [--key=KEY] [PATH ...]
```

**Options:**
- `-r, --reverse` - Reverse order
- `-u, --unique` - Remove duplicates
- `--key=path|basename|dirname` - Sort by this component

```fish
# Natural sort
echo file1.txt file10.txt file2.txt | path sort
# Output:
# file1.txt
# file2.txt
# file10.txt

# Sort by basename only
path sort --key=basename /a/foo.txt /b/bar.txt
# Output sorted by foo.txt, bar.txt not full paths

# Unique by basename
path sort --key=basename -u /dir1/foo /dir2/foo /dir3/bar
# Output: first foo and first bar only

# Reverse
path sort -r *.txt
```

---

## Combining with Other Commands

```fish
# Find all Python files and get basenames
path basename **/*.py

# Get extensions of all files
path extension *

# Filter to only existing files in a list
path filter $files

# Resolve paths in PATH
for p in $PATH
    path resolve $p
end

# Safe iteration (handles all filenames)
find . -print0 | path filter -z -f | while read -z file
    echo "File: $file"
end
```

---

## vs basename/dirname/realpath

| `path` subcommand | External command |
|-------------------|-----------------|
| `path basename` | `basename` |
| `path dirname` | `dirname` |
| `path resolve` | `realpath` |
| `path normalize` | (no direct equivalent) |
| `path filter` | `test` + loop |
| `path extension` | (no direct equivalent) |

Benefits of `path`:
- Handles multiple paths
- Works with pipes
- Fish-native (faster)
- NUL-safe input/output
