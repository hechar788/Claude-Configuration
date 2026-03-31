---
description: Review a pull request — inspect diff, run checks, submit review
argument-hint: <pr-number>
allowed-tools: Bash(git *), Bash(gh *)
---

# Review PR

## PR Number

$ARGUMENTS

## Step 1: Fetch PR details

```bash
gh pr view <pr-number>
```

## Step 2: Check out the branch

```bash
gh pr checkout <pr-number>
```

## Step 3: Inspect the diff

```bash
gh pr diff <pr-number>
```

Or view changed files:

```bash
git diff main...HEAD --stat
```

## Step 4: Check CI status

```bash
gh pr checks <pr-number>
```

## Step 5: Submit review

Approve:
```bash
gh pr review <pr-number> --approve --body "<comment>"
```

Request changes:
```bash
gh pr review <pr-number> --request-changes --body "<feedback>"
```

Comment only:
```bash
gh pr review <pr-number> --comment --body "<comment>"
```

## Step 6: Return to previous branch

```bash
git checkout -
```

## Notes

- Do NOT approve without reading the full diff
- Flag security-sensitive changes (auth, token handling, PostMessage origins) explicitly in the review body
