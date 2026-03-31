---
description: Ralph spec planning - interview to identify JTBD, break into topics, create specs
argument-hint: <feature description e.g. "menu management for merchants">
allowed-tools: AskUserQuestion, Read, Glob, Grep, Write, Task, Bash(mkdir *), Bash(cp *), Bash(chmod *), Bash(sed *), WebFetch
---

## Feature/Domain Request

$ARGUMENTS

## Instructions

You are conducting a **Ralph Phase 1: Define Requirements** session. Your goal is to study the codebase, propose Jobs to Be Done (JTBD), clarify with the user, then create specification files ready for `PROMPT_build`.

---

## Step 1: Setup Workspace

**FIRST**, create the workspace:

1. Extract the domain name from the request:
   - "menu management for merchants" → `menu`
   - "order processing system" → `orders`
   - "delivery zone configuration" → `delivery`

2. Create the folder and copy templates:

   ```bash
   mkdir -p .ralph/todo/<domain>/specs
   cp .ralph/template/IMPLEMENTATION_PLAN.md .ralph/todo/<domain>/
   cp .ralph/template/PROMPT_plan_claude.md .ralph/todo/<domain>/
   cp .ralph/template/PROMPT_plan_opencode.md .ralph/todo/<domain>/
   cp .ralph/template/PROMPT_build_claude.md .ralph/todo/<domain>/
   cp .ralph/template/PROMPT_build_opencode.md .ralph/todo/<domain>/
   cp .ralph/template/loop.sh .ralph/todo/<domain>/
   cp .ralph/template/AGENTS.md .ralph/todo/<domain>/
   cp .ralph/template/specs/_index.md .ralph/todo/<domain>/specs/
   ```

3. Configure the domain-specific files (replace `{{DOMAIN}}` placeholders):

   ```bash
   sed -i 's/{{DOMAIN}}/<domain>/g' .ralph/todo/<domain>/loop.sh
   sed -i 's/{{DOMAIN}}/<domain>/g' .ralph/todo/<domain>/AGENTS.md
   sed -i 's/{{DOMAIN}}/<domain>/g' .ralph/todo/<domain>/PROMPT_plan_claude.md
   sed -i 's/{{DOMAIN}}/<domain>/g' .ralph/todo/<domain>/PROMPT_plan_opencode.md
   sed -i 's/{{DOMAIN}}/<domain>/g' .ralph/todo/<domain>/PROMPT_build_claude.md
   sed -i 's/{{DOMAIN}}/<domain>/g' .ralph/todo/<domain>/PROMPT_build_opencode.md
   chmod +x .ralph/todo/<domain>/loop.sh
   ```

4. Confirm to user: "Created `.ralph/todo/<domain>/` with templates."

If the domain name is unclear, ask: "What should I name this folder? (e.g., `menu`, `orders`, `delivery`)"

---

## Step 2: Study Ralph Methodology

Fetch and study the Ralph playbook:

- URL: `https://raw.githubusercontent.com/ghuntley/how-to-ralph-wiggum/main/README.md`
- Focus on Phase 1 (Define Requirements) and spec creation workflow

### Core Concepts to Apply

**JTBD (Jobs to Be Done):** High-level user needs or desired outcomes

**Topics of Concern → Activities:** Break each JTBD into activities (verbs/journey-oriented)

- Bad (capability): "menu item system", "category management"
- Good (activity): "add menu item", "organize categories", "set pricing"

**Topic Scope Test:** "One sentence without 'and'"

- ✓ "Add menu item captures item details and saves to database"
- ✗ "Menu system handles items, categories, and modifiers" → three topics

---

## Step 3: Initial Codebase Discovery

**BEFORE asking questions**, thoroughly explore the codebase to understand what exists:

Use `Glob` and `Grep` to investigate:

1. **Related database schemas:**

   ```
   Glob: src/db/schemas/*.schema.ts
   Grep: <domain-related terms>
   ```

2. **Existing server functions:**

   ```
   Glob: src/server/**/*.ts
   Grep: <domain-related terms>
   ```

3. **Related UI components:**

   ```
   Glob: src/components/**/*.tsx
   Grep: <domain-related terms>
   ```

4. **Existing hooks:**

   ```
   Glob: src/hooks/**/*.ts
   Grep: <domain-related terms>
   ```

5. **Routes that might be relevant:**

   ```
   Glob: src/routes/**/*.tsx
   ```

6. **Any existing specs or plans:**
   ```
   Glob: .ralph/**/*.md
   ```

### Synthesize Findings

Based on codebase exploration, **propose** to the user:

1. **Existing foundation:** "I found these related components/schemas/functions..."
2. **Proposed JTBD:** "Based on the codebase, I think the jobs to be done are..."
3. **Proposed activities:** "The user journey might include these activities..."
4. **Gaps identified:** "These areas don't exist yet and would need to be built..."

---

## Step 4: Clarifying Interview

Now use `AskUserQuestion` to **confirm and refine** your findings. You already have context, so ask targeted questions:

**Round 1: Validate JTBD**

- "I identified these JTBD - are these correct? Any missing?"
- "Who is the primary user for this feature?"
- "What triggers this need?"

**Round 2: Refine Activities**

- "Here's the user journey I mapped - does this match your vision?"
- "What's the happy path? Any edge cases I missed?"
- "Any activities I should add or remove?"

**Round 3: Confirm Scope & Priorities**

- "Which activities are must-have vs nice-to-have?"
- "Any constraints or requirements I should know about?"
- "What does 'done' look like for each activity?"

**Round 4: Confirm Spec List**

- Present the final JTBD → Activities → Topics breakdown
- Confirm the list of spec files to create
- Ask about priority order for implementation

---

## Step 5: Deep Codebase Analysis

With confirmed understanding, do a **deeper dive** to inform the specs:

1. **Patterns to follow:** Find similar features and note their patterns
2. **Reusable code:** Identify hooks, components, utilities to reuse
3. **Schema extensions:** What tables need new columns or relations?
4. **Validation patterns:** How does similar validation work?
5. **UI conventions:** What existing components match the needed UI?

Document findings for each topic - these go into the specs.

---

## Step 6: Create Specs with Sub-Agents

**Use parallel sub-agents** to write each spec file:

Launch one `general-purpose` Task agent per spec file. Each agent should:

- Write to `.ralph/todo/<domain>/specs/XX-topic-name.md`
- Include: Overview, Requirements, Technical Design, Implementation Checklist, Files to Create
- Reference the codebase findings (patterns, reusables, schemas)
- Follow the spec format from `.ralph/template/specs/00-example-spec.md`

### Spec Naming Convention

```
01-jtbd1-overview.md       # JTBD 1 overview
01a-activity-name.md       # First activity for JTBD 1
01b-activity-name.md       # Second activity for JTBD 1
02-jtbd2-overview.md       # JTBD 2 overview
02a-activity-name.md       # etc.
```

---

## Step 7: Finalize

1. Update `.ralph/todo/<domain>/specs/_index.md` with the full spec list
2. Update `.ralph/todo/<domain>/PROMPT_plan_claude.md` and `.ralph/todo/<domain>/PROMPT_plan_opencode.md` - fill in the ULTIMATE GOAL with feature list
3. Update `.ralph/todo/<domain>/AGENTS.md` - fill in `{{DOMAIN_DESCRIPTION}}` with a brief scope description and add any key existing files discovered
4. Provide summary: JTBD count, activity count, spec count

Tell user:

"Specs created at `.ralph/todo/<domain>/specs/`. To run the planning loop:"

```bash
cd .ralph/todo/<domain>
./loop.sh plan
```

"Or to run build mode after planning is complete:"

```bash
cd .ralph/todo/<domain>
./loop.sh build
```

"Review the specs at `.ralph/todo/<domain>/specs/_index.md` first if needed."
