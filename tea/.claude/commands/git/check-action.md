---
description: Check the latest (or a specific) Gitea Actions workflow run
allowed-tools: Bash(tea *), Bash(git *)
---

# Check Workflow

## Arguments

- `$ARGUMENTS` - Optional workflow run ID to check a specific run

## Instructions

Check the status and logs of a Gitea Actions workflow run.

### Step 1: Get the workflow runs

List recent workflow runs:

```bash
tea ci ls
```

If `$ARGUMENTS` is provided and is a number, view that specific run:

```bash
tea ci view $ARGUMENTS
```

### Step 2: Check the result

- If the run **succeeded**, report the status, duration, and which branch/commit triggered it.
- If the run **failed**, fetch the logs:

```bash
tea ci logs <run-id>
```

Analyze the logs and report:
1. Which step failed
2. The error message
3. A brief explanation of what went wrong
4. A suggested fix if the cause is clear

### Step 3: Summary

Provide a concise summary including:
- **Status**: success/failure/running/pending
- **Branch**: which branch triggered it
- **Commit**: the commit that triggered it
- **Duration**: how long it took
- **Failure details** (if applicable): step name, error, and suggested fix
