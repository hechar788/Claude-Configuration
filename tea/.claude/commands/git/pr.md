---
description: Create a Gitea PR for the current branch
argument-hint: [base-branch]
allowed-tools: Bash(git *), Bash(tea *)
---

# Gitea Pull Request Creation

## Current Branch

!`git branch --show-current`

## Base Branch

$ARGUMENTS (default to `main` if not specified)

## Step 1: Gather Context

Run these commands to understand the changes:

1. `git log <base>..HEAD --oneline` to see commits
2. `git diff <base>..HEAD --stat` to see changed files

## Step 2: Check for Existing PR

Check if a PR already exists for this branch:

```bash
tea pr list --state open
```

## Step 3: Create the PR

### Generate PR Title

Create a concise, descriptive title based on the commits.

### Write PR Description

Use this format:

```
## Summary

Brief overview of what this PR does.

## Changes

- First significant change
- Second significant change
- Third significant change
```

**Important:**

- Do NOT take attribution
- Do NOT add "Generated with Claude Code" or similar footers
- Each significant change should be on its own line prefixed with `-`

### Create the PR

```bash
tea pr create --base <base> --title "..." --description "..."
```

After creation, output the PR URL.
