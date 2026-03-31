---
description: Apply specific commits from another branch to the current branch
argument-hint: <commit-hash> [commit-hash...]
allowed-tools: Bash(git *)
---

# Cherry Pick

## Current State

!`git branch --show-current`

!`git log --oneline -5`

## Commits to Apply

$ARGUMENTS (one or more commit hashes, or a range `A..B`)

## Step 1: Inspect the commits

```bash
git show <hash> --stat
```

Review what each commit does before applying.

## Step 2: Cherry pick

Single commit:
```bash
git cherry-pick <hash>
```

Multiple commits:
```bash
git cherry-pick <hash1> <hash2>
```

Range (applies A+1 through B):
```bash
git cherry-pick <A>..<B>
```

## Step 3: Handle Conflicts

If conflicts arise:

1. Resolve each conflicted file
2. Stage resolved files: `git add <file>`
3. Continue: `git cherry-pick --continue`
4. Or abort: `git cherry-pick --abort`

## Step 4: Push

```bash
git push
```

## Notes

- Cherry-picking creates new commits with different hashes — the original commits are not moved
- Prefer merging or rebasing when applying many commits; cherry-pick is best for surgical, isolated changes
