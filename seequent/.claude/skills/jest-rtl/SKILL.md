---
name: jest-rtl
description: Jest and React Testing Library conventions. Use when writing or reviewing tests for React components, Redux slices, RTK Query endpoints, or Ember-migrated components in imago or imago-mp.
---

# Jest + React Testing Library Guide

## Quick Reference

| Task | Reference file |
|---|---|
| Test setup, file structure, renderWithProviders, automation-id | references/1-setup.md |
| Component queries, userEvent, MUI v7 gotchas, conditional rendering | references/2-components.md |
| Redux slice testing, RTK Query, MSW, optimistic updates | references/3-redux-rtk.md |
| waitFor, findBy*, mocking @local/login, LaunchDarkly, fake timers | references/4-async-mocking.md |
| Testing components migrated from Ember to React | references/5-migration-testing.md |

---

## Core Rules

- **Never use raw render()** — always renderWithProviders from src/utils/test-utils.tsx
- **Test ID attribute is automation-id**, not data-testid (configured globally in testUtils/test.setup.tsx)
- **Always prefer userEvent over fireEvent** — it simulates realistic browser events
- **Always test loading, error, and success states** — not just the happy path
- **Every migrated Ember component must have RTL tests** covering its full behavioral contract
- **Co-locate tests**: Component.test.tsx lives next to Component.tsx — no __tests__/ folders

---

## When to Read Reference Files

Read the relevant reference file before writing or reviewing tests:

- **New component test** → read references/2-components.md
- **Testing Redux slices or RTK Query hooks** → read references/3-redux-rtk.md
- **Mocking @local/login, LaunchDarkly, timers, or async patterns** → read references/4-async-mocking.md
- **Migrating an Ember component to React** → read references/5-migration-testing.md
- **Setting up a new test file or configuring test infrastructure** → read references/1-setup.md
- **Unsure which query to use or how to interact with MUI** → read references/2-components.md

---

## Stack at a Glance

| Package | Version | Purpose |
|---|---|---|
| jest | 30.2.0 | Test runner |
| @testing-library/react | 16.3.0 | Rendering + queries |
| @testing-library/user-event | 14.6.1 | User interactions |
| @testing-library/jest-dom | 6.9.1 | DOM matchers |
| msw | — | API mocking |
| @local/jest-config-base | — | Shared Jest config |
| @local/test-utils | — | Shared render wrapper + store setup |
