# Clear Refactoring Plans

Reset the refactoring plans directory to its default empty state.

## Instructions

Execute the following steps to clear all refactoring plans:

### Step 1: Clear the opportunities folder

Remove all `.md` files from `.claude/data/refactoring/opportunities/` (except keep the folder itself).

```bash
rm -f .claude/data/refactoring/opportunities/*.md
```

### Step 2: Clear the implementation folder

Remove all step folders and files from `.claude/data/refactoring/implementation/`.

```bash
rm -rf .claude/data/refactoring/implementation/step-*
rm -f .claude/data/refactoring/implementation/*.md
rm -f .claude/data/refactoring/implementation/*.json
```

### Step 3: Reset the index file

Write the default `_index.md` content to `.claude/data/refactoring/_index.md`:

```markdown
# Refactoring Plans Index

Track status of all agent-generated plans. Update status as plans are reviewed and implemented.

## Status Legend

- `pending` - Plan created, awaiting review
- `approved` - Reviewed and approved for implementation
- `in-progress` - Currently being implemented
- `completed` - Successfully implemented
- `rejected` - Reviewed and rejected (add reason in notes)

## Opportunity Plans

| Plan | Agent | Priority | Status | Notes |
| ---- | ----- | -------- | ------ | ----- |

<!-- New plans will be added above this line -->
```

### Step 4: Confirm reset

Report completion:

```
## Refactoring Plans Cleared

- Removed opportunity plans: <count>
- Removed implementation plans: <count>
- Reset _index.md to defaults

Ready for a fresh `/identify-and-plan-refactoring` run.
```
