---
name: pr
description: Create a Gitea PR from the current branch
user-invocable: false
allowed-tools: Bash(git *), Bash(tea *)
---

# Gitea Pull Request Creation

## Current Branch

!`git branch --show-current`

## Instructions

Create a pull request for the current branch.

**Base branch:** Will be provided as context or default to `main`.

## Gathering Context

First, gather context by running:

1. `git log <base>..HEAD --oneline` to see commits
2. `git diff <base>..HEAD --stat` to see changed files

## Creating the PR

1. **Check if a PR already exists** for this branch: `tea pr list --state open`
2. **Generate a concise, descriptive PR title** based on the commits
3. **Write a PR description** summarizing the changes

### PR Description Format

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

## Create the PR

```bash
tea pr create --base <base> --title "..." --description "..."
```

After creation, output the PR URL.
