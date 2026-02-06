---
name: fix-types
description: Fix TypeScript errors
user-invocable: true
allowed-tools: Bash(npx tsc *), Read, Edit
---

# Fix TypeScript Errors

## Check for Errors

`npx tsc --noEmit`

## Instructions

Review the TypeScript errors above and fix each one:

1. **Identify the root cause** - Understand why the type error is occurring
2. **Fix with minimal changes** - Don't over-engineer; make the smallest change that correctly resolves the issue
3. **Verify the fix compiles** - After fixing, re-run the type check

## Guidelines

- Prefer fixing the actual type issue over using `any` or `@ts-ignore`
- If a type assertion is needed, use `as` with a specific type rather than `as any`
- Consider whether the error reveals a real bug vs. a type definition gap
- Update interfaces/types if the shape has legitimately changed

## Verification

After fixing all errors, run the type check again to confirm:

```bash
npx tsc --noEmit
```

Continue until there are no type errors remaining.
