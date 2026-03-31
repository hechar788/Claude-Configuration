---
description: Stash, list, pop, or drop work in progress
argument-hint: [save <message> | pop | list | drop <index>]
allowed-tools: Bash(git *)
---

# Stash

## Current Stash

!`git stash list`

## Current Status

!`git status`

## Arguments

$ARGUMENTS

## Operations

### Save current changes

```bash
git stash push -m "<message>"
```

Include untracked files:

```bash
git stash push -u -m "<message>"
```

### List stashes

```bash
git stash list
```

### Apply and remove the latest stash

```bash
git stash pop
```

### Apply a specific stash without removing it

```bash
git stash apply stash@{<index>}
```

### Drop a specific stash

```bash
git stash drop stash@{<index>}
```

### Clear all stashes

```bash
git stash clear
```

## Notes

- Always add a descriptive message when stashing — `stash@{0}` becomes ambiguous quickly
- `pop` = `apply` + `drop`; prefer `pop` unless you want to keep the stash
