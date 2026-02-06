# Ralph Template

Templates for starting new feature implementation plans using the Ralph workflow.

## Quick Start

1. **Copy template files to `.ralph/`:**

   ```bash
   # Copy the template files (don't overwrite existing)
   cp -n .ralph/template/IMPLEMENTATION_PLAN.md .ralph/
   cp -n .ralph/template/PROMPT_plan.md .ralph/
   cp -n .ralph/template/PROMPT_build.md .ralph/
   cp -rn .ralph/template/specs .ralph/
   ```

2. **Update `PROMPT_plan.md`:**
   - Fill in the `ULTIMATE GOAL` section with your feature description
   - List the key features/capabilities

3. **Create specs:**
   - Use `specs/00-example-spec.md` as a reference
   - Create one spec per JTBD topic of concern
   - Update `specs/_index.md` to list all specs

4. **Run the planning loop:**

   ```bash
   cat .ralph/PROMPT_plan.md | claude -p --dangerously-skip-permissions
   ```

5. **Run the build loop:**
   ```bash
   while :; do cat .ralph/PROMPT_build.md | claude -p --dangerously-skip-permissions; done
   ```

## File Structure

```
.ralph/template/
├── README.md                 # This file
├── IMPLEMENTATION_PLAN.md    # Task tracking template
├── PROMPT_plan.md           # Planning mode prompt
├── PROMPT_build.md          # Building mode prompt
└── specs/
    ├── _index.md            # Specs navigation index
    └── 00-example-spec.md   # Example spec format
```

## Workflow

```
Phase 1: Requirements
├── Human-LLM conversation → identify JTBD
├── Break JTBD into topics of concern
└── Write specs/*.md for each topic

Phase 2: Planning
├── Run PROMPT_plan.md
├── LLM studies specs + existing code
└── LLM creates/updates IMPLEMENTATION_PLAN.md

Phase 3: Building
├── Run PROMPT_build.md in loop
├── LLM picks highest priority task
├── Implement, test, commit, push
└── Loop continues until plan complete
```

## Naming Conventions

### Specs

- `01-overview.md` - Overview spec for JTBD 1
- `01a-subtopic.md` - First subtopic for JTBD 1
- `01b-subtopic.md` - Second subtopic for JTBD 1
- `02-overview.md` - Overview spec for JTBD 2

### Spec Content

Each spec should cover ONE topic and pass the "one sentence without 'and'" test:

- ✓ "Queue management handles application listing and filtering"
- ✗ "User system handles authentication, profiles, and billing" → three specs
