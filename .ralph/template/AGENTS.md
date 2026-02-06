# Ralph Operational Guide - {{DOMAIN}} Domain

This file is loaded each iteration. Keep it brief and operational only.
Status updates and progress notes belong in `IMPLEMENTATION_PLAN.md`.

## Domain Scope

{{DOMAIN_DESCRIPTION}}

## Specs Location

All specs are in `.ralph/todo/{{DOMAIN}}/specs/` - read `_index.md` for the full list.

## Build & Run

```bash
npm run dev          # Dev server on port 3000
npm run build        # Production build
npm run serve        # Preview production build
```

## Validation

Run these after implementing to get immediate feedback:

```bash
npm run test         # Vitest in CI mode
npm run lint         # ESLint
npm run format       # Prettier check
npm run check        # ESLint + Prettier auto-fix
npm run db:generate  # Generate Drizzle migrations
npm run db:migrate   # Apply migrations
```

## Project Structure

- **Source code**: `src/`
- **Specs**: `.ralph/todo/{{DOMAIN}}/specs/`
- **Implementation plan**: `.ralph/todo/{{DOMAIN}}/IMPLEMENTATION_PLAN.md`
- **Components**: `src/components/` (domain-organized)
- **Server functions**: `src/server/` (domain-organized)
- **Database schemas**: `src/db/schemas/` (one file per table)
- **Hooks**: `src/hooks/` (domain-organized)
- **Routes**: `src/routes/`

## Technology Stack

| Layer      | Technology                    |
| ---------- | ----------------------------- |
| Framework  | TanStack React Start          |
| Database   | Drizzle ORM + Neon PostgreSQL |
| Auth       | Firebase Auth                 |
| Real-time  | Ably WebSockets               |
| UI         | ShadCN/UI + Tailwind CSS v4   |
| Deployment | Cloudflare Workers            |

## Codebase Patterns

- Server functions use `createServerFn` from TanStack React Start
- Drizzle schemas: one file per table, barrel-exported from `index.ts`
- Query key factories for TanStack Query cache management
- Two-tier Firebase auth (client + Admin SDK server verification)
- JSDoc all exported functions with `@param`, `@returns`, `@example`

## Key Existing Files

<!-- Add relevant existing files discovered during codebase exploration -->

## Operational Notes

<!-- Ralph will add learnings here as it discovers them -->
