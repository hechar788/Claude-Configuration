---
description: Reset branch to a previous commit or undo staged changes
argument-hint: [soft|mixed|hard] [ref]
allowed-tools: Bash(git *)
---

# Reset

## Current State

!`git log --oneline -10`

!`git status`

## Arguments

$ARGUMENTS (mode: `soft` | `mixed` | `hard`, ref: commit hash or `HEAD~N`)

## Modes

| Mode | Staged changes | Working tree | Use when |
|------|---------------|--------------|----------|
| `--soft` | Kept staged | Unchanged | Undo commit, keep changes ready to re-commit |
| `--mixed` _(default)_ | Unstaged | Unchanged | Undo commit and unstage, keep file changes |
| `--hard` | Discarded | **Discarded** | Throw away commits and all changes |

## Step 1: Confirm ref

```bash
git log --oneline -5
```

Identify the commit to reset to.

## Step 2: Reset

```bash
git reset --<mode> <ref>
```

Examples:
```bash
git reset --soft HEAD~1      # undo last commit, keep staged
git reset --mixed HEAD~2     # undo 2 commits, unstage changes
git reset --hard origin/main # match remote exactly
```

## ⚠️ Hard Reset Warning

`--hard` permanently discards uncommitted changes. Confirm there is nothing in the working tree worth keeping before running.

If the branch was already pushed, you'll need:

```bash
git push --force-with-lease
```
