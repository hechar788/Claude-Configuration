0a. Study `.ralph/todo/{{DOMAIN}}/specs/*` with up to 250 parallel Sonnet subagents to learn the application specifications.
0b. Study @.ralph/todo/{{DOMAIN}}/IMPLEMENTATION_PLAN.md (if present) to understand the plan so far.
0c. Study `src/lib/*` with up to 250 parallel Sonnet subagents to understand shared utilities & components.
0d. For reference, the application source code is in `src/*`.

1. Study @.ralph/todo/{{DOMAIN}}/IMPLEMENTATION_PLAN.md (if present; it may be incorrect) and use up to 500 Sonnet subagents to study existing source code in `src/*` and compare it against `.ralph/todo/{{DOMAIN}}/specs/*`. Use an Opus subagent to analyze findings, prioritize tasks, and create/update @.ralph/todo/{{DOMAIN}}/IMPLEMENTATION_PLAN.md as a bullet point list sorted in priority of items yet to be implemented. Ultrathink. Consider searching for TODO, minimal implementations, placeholders, skipped/flaky tests, and inconsistent patterns. Study @.ralph/todo/{{DOMAIN}}/IMPLEMENTATION_PLAN.md to determine starting point for research and keep it up to date with items considered complete/incomplete using subagents.

IMPORTANT: Plan only. Do NOT implement anything. Do NOT assume functionality is missing; confirm with code search first. Treat `src/lib` as the project's standard library for shared utilities and components. Prefer consolidated, idiomatic implementations there over ad-hoc copies.

ULTIMATE GOAL: We want to achieve [DESCRIBE YOUR GOAL HERE]. This includes:

- [Feature 1]
- [Feature 2]
- [Feature 3]

Consider missing elements and plan accordingly. If an element is missing, search first to confirm it doesn't exist, then if needed author the specification at `.ralph/todo/{{DOMAIN}}/specs/FILENAME.md`. If you create a new element then document the plan to implement it in @.ralph/todo/{{DOMAIN}}/IMPLEMENTATION_PLAN.md using a subagent.
