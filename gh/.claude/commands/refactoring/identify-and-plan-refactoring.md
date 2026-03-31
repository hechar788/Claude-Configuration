# Identify and Plan Refactoring

Orchestrate a multi-stage refactoring analysis workflow: discover opportunities, design implementations, and batch for parallel execution.

## Instructions

You will orchestrate three phases of refactoring analysis, spawning specialized subagents at each stage.

### Phase 1: Discover Refactoring Opportunities

Spawn **10 code-simplifier agents in parallel** to analyze the codebase for refactoring opportunities.

**Agent Configuration:**

- Use the Task tool with `subagent_type: code-simplifier`
- All 10 agents must be spawned in a SINGLE message (parallel execution)
- Each agent will independently explore and identify opportunities

**Prompt for All Agents:**

```
Explore the codebase under `src/` and identify refactoring opportunities.

Look for:
- Duplicated code that could be consolidated
- Complex conditional logic that could be simplified
- Verbose patterns that could use modern language features
- Poor separation of concerns
- Opportunities to extract reusable utilities or hooks

For each opportunity you identify, save a plan to:
`.claude/data/refactoring/opportunities/<plan-name>.md`

Use the format specified in your agent instructions. Focus on actionable improvements that would meaningfully improve code quality.

Before creating a plan, check if a similar opportunity already exists in the opportunity folder to avoid duplicates.

Do NOT implement any changes - only identify and document opportunities.
```

**After Phase 1 Completes:**

1. Report how many opportunity files were created
2. List the opportunities discovered by each agent
3. Proceed to Phase 2

---

### Phase 2: Design Implementation Strategies

After all code-simplifier agents complete, read the `.claude/data/refactoring/opportunities/` directory to find all created opportunity files.

**For each opportunity file:**

- Spawn a `refactor-architect` agent to design the implementation strategy
- Agents can run in parallel (spawn all in a SINGLE message if there are multiple)

**Prompt Template:**

```
Design an implementation strategy for the refactoring opportunity at:
.claude/data/refactoring/opportunities/<opportunity-file>.md

Read the opportunity file, then:
1. Explore the affected code areas to understand existing patterns
2. Evaluate 2-3 implementation approaches
3. Recommend the optimal approach
4. Create a detailed implementation plan

Save your implementation plan to:
`.claude/data/refactoring/implementation/<plan-name>-impl.md`

Use the format specified in your agent instructions. Ensure the plan includes:
- Clear migration steps
- Commit sequence
- Test strategy
```

**After Phase 2 Completes:**

1. Report how many implementation plans were created
2. Summarize the recommended approaches
3. Proceed to Phase 3

---

### Phase 3: Batch Plans for Parallel Execution

Spawn a **single refactor-plan-batcher agent** to organize all implementation plans into execution steps.

**Prompt:**

```
Analyze all implementation plans in `.claude/data/refactoring/implementation/` and organize them into parallel execution batches.

Follow your agent instructions to:
1. Discover all -impl.md files
2. Build a conflict map based on affected files
3. Organize plans into step-N/ folders
4. Create the execution manifest
5. Update the _index.md with the new structure

Output a summary of the batching results.
```

---

### Final Report

After all phases complete, provide a summary:

```
## Refactoring Analysis Complete

### Phase 1: Opportunity Discovery
- Agents spawned: 10
- Opportunities identified: <N>
- Areas with most opportunities: <list>

### Phase 2: Implementation Planning
- Plans created: <N>
- Complexity breakdown:
  - Trivial: <count>
  - Simple: <count>
  - Moderate: <count>
  - Complex: <count>

### Phase 3: Execution Batching
- Total steps: <N>
- Plans per step: <breakdown>

### Ready for Execution
Run `/run-refactor-steps` to execute all implementation plans.
```

---

## Important Rules

1. **Parallel Execution:** Always spawn agents in a SINGLE message when they can run in parallel
2. **Wait Between Phases:** Complete each phase fully before starting the next
3. **No Implementation:** This command only identifies and plans - it does NOT implement changes
4. **Error Handling:** If any agent fails, report the failure and continue with remaining agents
5. **Skip Empty Results:** If Phase 1 produces no opportunities, skip Phases 2-3 and report that the codebase is clean
