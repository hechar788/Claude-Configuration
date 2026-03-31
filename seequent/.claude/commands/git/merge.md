---
description: Merge a branch into the current branch
argument-hint: <source-branch>
allowed-tools: Bash(git *)
---

# Merge

## Current State

!`git branch --show-current`

!`git status`

## Source Branch

$ARGUMENTS

## Step 1: Preview

Show what will be merged:

```bash
git log HEAD..<source> --oneline
git diff HEAD..<source> --stat
```

## Step 2: Merge

For feature branches, use `--no-ff` to preserve merge history:

```bash
git merge --no-ff <source>
```

For integration/hotfix merges where a fast-forward is acceptable:

```bash
git merge <source>
```

## Step 3: Handle Conflicts

If conflicts arise:

1. Resolve each conflicted file
2. Stage resolved files: `git add <file>`
3. Complete the merge: `git merge --continue`
4. Or abort: `git merge --abort`

## Step 4: Push

```bash
git push
```
