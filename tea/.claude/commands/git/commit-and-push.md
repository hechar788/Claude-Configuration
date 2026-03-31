---
description: Create feature-focused commits and push them
allowed-tools: Bash(git *)
---

# Commit and Push

## Current Changes

!`git status`

!`git diff`

## Instructions

Review the changes above and create logically-grouped commits following these guidelines.

## Commit Grouping

- **Combine small related changes** into a single commit when they are part of the same logical change or fix
- **Multiple small changes of the same type** (e.g., applying a pattern across several files, fixing similar issues in multiple locations) should be a single commit, even if they span multiple files
- **Only create separate commits** when changes are truly independent features or fixes that could reasonably be reverted separately
- **Prefer fewer, well-organized commits** over many tiny commits

## Commit Protocol

1. **Stage only related files** for each commit
2. **Use conventional commit prefixes:** `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`
3. **Use the git author already configured** - do NOT use `--author` flag
4. **No attribution** - do NOT add Co-Authored-By or any other attribution
5. **Format commit messages** with body lines prefixed by `-`

## Message Format

```
<type>: <short description>

- <Specific change 1>
- <Specific change 2>
- <Specific change 3>
```

## Examples

Good - logically grouped:

```
refactor: consolidate friend request server functions

- Add shared validation utility for friend operations
- Migrate sendFriendRequest, acceptFriendRequest, and declineFriendRequest
- Migrate getFriendRequests and getFriends queries
- Update exports in index.ts
```

Bad - too granular (don't do this):

```
refactor: add friend validation utility
```

```
refactor: migrate sendFriendRequest function
```

## Push After Committing

After creating all commits, push them to the remote:

```bash
git push
```

If the branch doesn't have an upstream, set it:

```bash
git push -u origin <branch-name>
```

Do NOT create a pull request - only commit and push.
