0a. Study all files in `.ralph/todo/{{DOMAIN}}/specs/` to learn the application specifications. Read each spec file thoroughly.
0b. Study `.ralph/todo/{{DOMAIN}}/IMPLEMENTATION_PLAN.md`.
0c. For reference, the application source code is in `apps/web/src/*`.

1. SCOPE RULE — ONE PHASE PER LOOP ITERATION:
   Read `.ralph/todo/{{DOMAIN}}/IMPLEMENTATION_PLAN.md` and identify the FIRST phase that has PENDING tasks. Implement ONLY that phase's tasks in this iteration. Do NOT move on to the next phase even if you finish early.

   If the IMPLEMENTATION_PLAN specifies a phase order, follow it exactly. Otherwise process phases in numerical order.

   If a phase has sub-sections (e.g., 1.1, 1.2, 1.3), implement ALL sub-sections within that phase but STOP at the phase boundary. Each loop iteration = one phase = one commit.

   Before making changes, search the codebase thoroughly (don't assume not implemented). Use careful reasoning for complex decisions (debugging, architectural choices).

   ALL PHASES DONE — VERIFICATION MODE:
   If ALL phases in the IMPLEMENTATION_PLAN are marked DONE, switch to verification mode:
   a. Run the full test suite (`npm run test`), the build (`npm run build`), and lint (`npm run lint`).
   b. Fix any failing tests, type errors, lint errors, or broken functionality related to this domain's feature.
   c. Review each spec in `.ralph/todo/{{DOMAIN}}/specs/*` against the implemented code — check for missing edge cases, incorrect logic, or gaps between spec and implementation.
   d. If you find issues, fix them. If you find nothing, commit any fixes and STOP — do not invent work.
   e. Each verification loop = one commit (if there were fixes) or no commit (if everything passes clean).
   f. If a verification loop produces no fixes and all checks pass, output "VERIFICATION COMPLETE — all phases implemented, tests passing, build clean." and STOP.

2. After implementing the phase's functionality, run the relevant tests. Write tests for the code you implemented as specified in the phase's test tasks. If functionality is missing then it's your job to add it as per the application specifications. Think step by step.

3. When you discover issues, immediately update `.ralph/todo/{{DOMAIN}}/IMPLEMENTATION_PLAN.md` with your findings. When resolved, update and remove the item.

4. When the tests pass, mark all completed tasks in `.ralph/todo/{{DOMAIN}}/IMPLEMENTATION_PLAN.md` as DONE, then `git add -A` then `git commit` with a message describing the phase completed. After the commit, `git push`.

5. STOP after the commit. Do NOT start the next phase. The next loop iteration will pick it up.

6. Important: When authoring documentation, capture the why — tests and implementation importance.
7. Important: Single sources of truth, no migrations/adapters. If tests unrelated to your work fail, resolve them as part of the increment.
8. As soon as there are no build or test errors create a git tag. If there are no git tags start at 0.0.0 and increment patch by 1 for example 0.0.1 if 0.0.0 does not exist.
9. You may add extra logging if required to debug issues.
10. Keep `.ralph/todo/{{DOMAIN}}/IMPLEMENTATION_PLAN.md` current with learnings — future work depends on this to avoid duplicating efforts. Update especially after finishing your turn.
11. When you learn something new about how to run the application, update `.ralph/todo/{{DOMAIN}}/AGENTS.md` but keep it brief. For example if you run commands multiple times before learning the correct command then that file should be updated.
12. For any bugs you notice, resolve them or document them in `.ralph/todo/{{DOMAIN}}/IMPLEMENTATION_PLAN.md` even if it is unrelated to the current piece of work.
13. Implement functionality completely. Placeholders and stubs waste efforts and time redoing the same work.
14. When `.ralph/todo/{{DOMAIN}}/IMPLEMENTATION_PLAN.md` becomes large periodically clean out the items that are completed from the file.
15. If you find inconsistencies in the `.ralph/todo/{{DOMAIN}}/specs/*` then reason carefully and update the specs.
16. IMPORTANT: Keep `.ralph/todo/{{DOMAIN}}/AGENTS.md` operational only — status updates and progress notes belong in `.ralph/todo/{{DOMAIN}}/IMPLEMENTATION_PLAN.md`. A bloated AGENTS.md pollutes every future loop's context.
