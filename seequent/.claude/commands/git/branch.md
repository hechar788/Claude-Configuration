---
description: Create, switch, list, or delete branches
argument-hint: [create <name> [base] | switch <name> | delete <name> | list]
allowed-tools: Bash(git *)
---

# Branch Management

## Current State

!`git branch -a`

!`git branch --show-current`

## Arguments

$ARGUMENTS

## Operations

### Create a new branch

```bash
git checkout -b <name> [base]
```

If no base is specified, branch from current HEAD. Use `main` as base for feature branches.

### Switch to an existing branch

```bash
git checkout <name>
```

### List branches

```bash
git branch -a
```

### Delete a branch

Local:
```bash
git branch -d <name>
```

Use `-D` only if the branch is unmerged and you're sure you want to discard it.

Remote:
```bash
git push origin --delete <name>
```

## Notes

- Branch names should be kebab-case (e.g., `feat/add-login`, `fix/token-refresh`)
- Always confirm current branch before creating or switching
