---
description: Rebase current branch onto a target branch
argument-hint: [target-branch]
allowed-tools: Bash(git *)
---

# Rebase

## Current State

!`git branch --show-current`

!`git log --oneline -10`

## Target Branch

$ARGUMENTS (default: `main`)

## Step 1: Preview

Show commits that will be rebased:

```bash
git log <target>..HEAD --oneline
```

Show diff from target:

```bash
git diff <target>...HEAD --stat
```

## Step 2: Rebase

```bash
git rebase <target>
```

## Step 3: Handle Conflicts

If conflicts arise:

1. Resolve each conflicted file
2. Stage resolved files: `git add <file>`
3. Continue: `git rebase --continue`
4. Or abort and return to original state: `git rebase --abort`

## Step 4: Push

If the branch was already pushed, a force push is required after rebase:

```bash
git push --force-with-lease
```

`--force-with-lease` is safer than `--force` — it will fail if the remote has commits you haven't seen.
