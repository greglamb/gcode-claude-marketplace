# Job Control Command Reference

Complete reference for job control commands: `jobs`, `fg`, `bg`, `disown`, `wait`.

---

## jobs - List Background Jobs

```fish
jobs [OPTIONS]
```

### Options

| Option | Description |
|--------|-------------|
| `-c, --command` | Print command name |
| `-g, --group` | Print group ID |
| `-l, --last` | Print last started job |
| `-p, --pid` | Print process ID |
| `-q, --query` | Check if jobs exist (no output) |

### Examples

```fish
# List all jobs
jobs

# Just PIDs
jobs -p

# Just group IDs
jobs -g

# Check if any jobs exist
if jobs -q
    echo "Jobs running"
end

# Last started job
jobs -l
```

---

## fg - Bring Job to Foreground

```fish
fg [JOB_ID]
```

Resume a stopped or backgrounded job in the foreground.

### Job IDs

- `%N` - Job number N
- `%+` or `%%` - Current job
- `%-` - Previous job
- `%string` - Job starting with string
- `%?string` - Job containing string

```fish
# Foreground last job
fg

# Foreground specific job
fg %1

# Foreground by command name
fg %sleep
```

---

## bg - Resume Job in Background

```fish
bg [JOB_ID]
```

Resume a stopped job in the background.

```fish
# Start command, suspend with Ctrl+Z
sleep 100
# ^Z
# [1]  + suspended  sleep 100

# Resume in background
bg
# [1]  + continued  sleep 100

# Or background specific job
bg %1
```

---

## disown - Remove Job from Job Table

```fish
disown [OPTIONS] [JOB_ID ...]
```

Removes job from fish's job table. The job continues running but fish won't track it.

### Options

| Option | Description |
|--------|-------------|
| (none) | Disown last job |
| PID | Disown specific PID |
| `%N` | Disown job number N |

```fish
# Start long-running command
./backup.sh &

# Disown it (won't be killed when shell exits)
disown

# Disown specific job
disown %1

# Disown by PID
disown $last_pid
```

---

## wait - Wait for Jobs to Finish

```fish
wait [OPTIONS] [JOB_ID ...]
```

Wait for background jobs to complete.

### Options

| Option | Description |
|--------|-------------|
| `-n, --any` | Wait for any job (returns first to finish) |

```fish
# Wait for all background jobs
sleep 5 &
sleep 3 &
wait
echo "All done"

# Wait for specific job
sleep 5 &
set pid $last_pid
# do other stuff
wait $pid
echo "Sleep finished"

# Wait for any job to finish
sleep 5 &
sleep 1 &
wait -n
echo "First one finished"
```

---

## Background Execution

### Starting in Background

```fish
# Add & to run in background
long_command &

# Get PID of last backgrounded job
echo $last_pid

# Background and disown in one step
long_command & disown
```

### Suspending Jobs

```fish
# While running, press Ctrl+Z to suspend
# Then use bg to resume in background or fg for foreground
```

---

## Workflow Examples

### Run Command and Continue Working

```fish
# Start build in background
make &

# Do other things...
vim src/file.c

# Check if build finished
jobs

# Wait for it
wait
echo "Build done: $status"
```

### Multiple Parallel Commands

```fish
# Run multiple commands in parallel
./task1.sh &
./task2.sh &
./task3.sh &

# Wait for all
wait
echo "All tasks complete"
```

### Long-Running Process After Logout

```fish
# Start process
./long_process &

# Disown it so it survives shell exit
disown

# Now you can close the terminal
```

### Capture Background Output

```fish
# Redirect output before backgrounding
./command > output.log 2>&1 &

# Check progress
tail -f output.log
```

---

## Special Variables

| Variable | Description |
|----------|-------------|
| `$last_pid` | PID of last backgrounded job |
| `$fish_pid` | Fish's own PID |

```fish
./command &
echo "Started job with PID: $last_pid"
```

---

## Job Events

```fish
# Run function when job exits
function notify_done --on-job-exit %1
    echo "Job 1 finished!"
end
```

---

## Common Mistakes (Bash Users)

| Bash | Fish |
|------|------|
| `$!` | `$last_pid` |
| `$$` | `$fish_pid` |
| `jobs -r` | `jobs` (fish shows all by default) |
| `nohup cmd &` | `cmd & disown` |
| `(cmd &)` | `fish -c 'cmd &'` (no subshells) |
