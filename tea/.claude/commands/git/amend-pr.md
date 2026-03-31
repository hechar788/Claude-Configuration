---
description: Update an existing PR description with commits made after it was opened
allowed-tools: Bash(git *), Bash(tea *)
---

# Amend Pull Request Description

Update the PR description to include any commits pushed after the PR was created.

## Current Branch

!`git branch --show-current`

## Step 1: Check for Open PR

Check if a PR exists for the current branch:

```bash
tea pr list --state open
```

Find the PR for the current branch. If no PR exists, inform the user and stop.

## Step 2: Get PR Details and Commits

1. View the existing PR:
   ```bash
   tea pr view <number>
   ```

2. Get all commits on this branch compared to the base branch:
   ```bash
   git log <base>..HEAD --oneline
   ```

3. Get the full diff stat:
   ```bash
   git diff <base>..HEAD --stat
   ```

## Step 3: Generate Updated Description

Create an updated PR description that:

1. Keeps the existing Summary section (or creates one if missing)
2. Updates the Changes section to reflect ALL commits in the PR
3. Uses this format:

```
## Summary

<existing summary or brief overview based on all changes>

## Changes

- First significant change
- Second significant change
- Third significant change
```

**Important:**

- Do NOT take attribution
- Do NOT add "Generated with Claude Code" or similar footers
- Consolidate related commits into logical change descriptions
- Each significant change should be on its own line prefixed with `-`

## Step 4: Update the PR

```bash
tea pr edit <number> --description "<updated description>"
```

## Step 5: Confirm

Output:

- The PR URL
- Summary of what was updated
- The new description
