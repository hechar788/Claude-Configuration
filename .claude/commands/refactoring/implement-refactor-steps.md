# Run Refactor Implementation Steps

Execute all refactoring implementation plans in parallel batches, organized by step folders.

## Instructions

You will orchestrate the execution of `plan-implementer` subagents for each implementation plan, processing steps sequentially but plans within each step in parallel.

### Directory Structure

Implementation plans are organized in:

```
.claude/data/refactoring/implementation/
├── step-1/
│   ├── plan-a-impl.md
│   └── plan-b-impl.md
├── step-2/
│   └── plan-c-impl.md
└── step-N/
    └── ...
```

### Execution Protocol

1. **List all step folders** in `.claude/data/refactoring/implementation/` (step-1, step-2, etc.)
   - Sort them numerically (step-1 before step-2, etc.)

2. **For each step folder in order:**

   a. **Announce the step:**

   ```
   ## Starting Step N
   Plans to execute:
   - plan-a-impl.md
   - plan-b-impl.md
   ```

   b. **Spawn plan-implementer subagents in parallel** - one for each `-impl.md` file in that step folder:
   - Use the Task tool with `subagent_type: plan-implementer`
   - Pass the full path to the implementation plan file
   - Run ALL agents for this step in a SINGLE message (parallel execution)

   c. **Wait for all agents in this step to complete**

   d. **Verify the build passes:**

   ```bash
   npm run build
   ```

   e. **Report step completion:**

   ```
   ## Step N Complete
   ✓ plan-a-impl.md - 3 commits
   ✓ plan-b-impl.md - 2 commits
   Build: passing
   ```

   f. **Proceed to next step** only after current step fully completes

3. **Final Summary:**

   ```
   ## All Steps Complete

   | Step | Plans | Commits | Status |
   |------|-------|---------|--------|
   | step-1 | 3 | 8 | ✓ |
   | step-2 | 2 | 5 | ✓ |
   | step-3 | 4 | 11 | ✓ |

   Total commits: 24
   Final build: passing
   ```

### Important Rules

- **Sequential steps, parallel plans:** Steps must run in order, but all plans within a step run simultaneously
- **Build verification:** Run `npm run build` after each step completes before moving to the next
- **Stop on failure:** If any agent fails or the build breaks, STOP and report before continuing
- **No skipping:** Execute ALL plans in each step, don't skip any

### Example Task Tool Usage

For step-1 with 3 plans, send a SINGLE message with 3 Task tool calls:

```
<Task subagent_type="plan-implementer">
Implement the plan at .claude/data/refactoring/implementation/step-1/extract-friend-list-card-impl.md
</Task>

<Task subagent_type="plan-implementer">
Implement the plan at .claude/data/refactoring/implementation/step-1/consolidate-auth-hooks-impl.md
</Task>

<Task subagent_type="plan-implementer">
Implement the plan at .claude/data/refactoring/implementation/step-1/extract-merchant-card-impl.md
</Task>
```

### Error Handling

If a plan-implementer agent reports failure:

1. Note which plan failed and why
2. Continue with other plans in the same step (they're independent)
3. After step completes, report all failures
4. Ask user whether to continue to next step or stop

If build fails after a step:

1. Report which step caused the failure
2. Show build error output
3. STOP and wait for user guidance
