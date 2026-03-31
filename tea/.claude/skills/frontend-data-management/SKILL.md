---
name: frontend-data-management
description: Data fetching, caching, and state management conventions. Use when working with TanStack Query, TanStack Store, server functions, or mutations.
---

# Frontend Data Management Guide

This skill defines how data fetching, caching, and state management work in this application.

## Technology Stack

| Purpose          | Technology           | Usage                              |
| ---------------- | -------------------- | ---------------------------------- |
| Server State     | TanStack Query       | Data fetching, caching, mutations  |
| Client State     | TanStack Store       | Cross-component client-only state  |
| Server Functions | TanStack React Start | `createServerFn` for backend logic |
| Forms            | TanStack Form + Zod  | Form validation and submission     |

## When to Use What

| Data Type                    | Use            | Example                            |
| ---------------------------- | -------------- | ---------------------------------- |
| Server/remote data           | TanStack Query | Data fetching with caching         |
| Client-only, cross-component | TanStack Store | Navigation history, UI preferences |
| Component-local              | `useState`     | Form inputs, toggle states         |

**Never duplicate:** If Query is managing data, don't store it in Store or `useState`.

---

## TanStack Query

### Core Principles

1. **No `fetch` in components** - Always use `useQuery` for data fetching
2. **Query owns the lifecycle** - caching, deduplication, background refresh, stale-while-revalidate
3. **Colocate hooks with domain** - Query hooks live in `src/hooks/<domain>/`
4. **Small, focused queries** - Each query fetches exactly what that UI surface needs
5. **Break into subdomains** - When a domain has distinct sub-concerns (e.g., requests within a domain), organize into `<domain>/<subdomain>/`

### Query Key Factories

All domains use standardized query key factories for consistent cache management:

```typescript
// src/hooks/<domain>/use<Domain>.ts
export const <domain>Keys = {
  all: ['<domain>'] as const,
  list: (filters?: <Domain>Filters) => [
    ...<domain>Keys.all,
    'list',
    filters ?? {},
  ],
  detail: (id: string) => [...<domain>Keys.all, 'detail', id],
}

export function use<Domain>s(filters?: <Domain>Filters) {
  return useQuery({
    queryKey: <domain>Keys.list(filters),
    queryFn: () => get<Domain>s({ data: filters }),
  })
}

export function use<Domain>(id: string) {
  return useQuery({
    queryKey: <domain>Keys.detail(id),
    queryFn: () => get<Domain>ById({ data: { id } }),
    enabled: !!id,
  })
}
```

### Nested Query Keys

For complex domains, use nested key factories. Break down into subdomains when a domain has distinct sub-concerns:

```typescript
// src/hooks/<domain>/<subdomain>/use<Subdomain>.ts
export const <subdomain>Keys = {
  all: ['<domain>', '<subdomain>'] as const,
  list: (userId: string) => [...<subdomain>Keys.all, 'list', userId],
  incoming: (userId: string) => [...<subdomain>Keys.all, 'incoming', userId],
  outgoing: (userId: string) => [...<subdomain>Keys.all, 'outgoing', userId],
  status: (currentUserId: string, targetUserId: string) => [
    ...<subdomain>Keys.all,
    'status',
    currentUserId,
    targetUserId,
  ],
}
```

### Mutations

Always invalidate or update relevant queries after mutations:

```typescript
export function use<Action><Domain>() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (data: <Action><Domain>Input) =>
      <action><Domain>({ data }),
    onSuccess: (_, variables) => {
      // Invalidate all related caches
      queryClient.invalidateQueries({
        queryKey: <domain>Keys.list(variables.userId),
      })
      queryClient.invalidateQueries({
        queryKey: <domain>Keys.detail(variables.id),
      })
      // Invalidate any related subdomain caches
      queryClient.invalidateQueries({
        queryKey: <subdomain>Keys.all,
      })
    },
  })
}
```

---

## Server Functions

Server functions are defined using `createServerFn`:

```typescript
// src/server/<domain>/get<Domain>s.ts
import { createServerFn } from '@tanstack/react-start'

export const get<Domain>s = createServerFn({ method: 'GET' })
  .inputValidator((input: unknown) => Get<Domain>sSchema.parse(input))
  .handler(async ({ data }: { data: Get<Domain>sInput }) => {
    const results = await db.select().from(<domain>Table).where(...)
    return results
  })
```

**Call from hooks:**

```typescript
queryFn: () => get<Domain>s({ data: { filter: 'value' } })
```

---

## TanStack Store

### When to Use Store

Use Store for state that is:

- **Client-only** - not derived from server data
- **Cross-component** - shared between unrelated components
- **Not in Query** - never duplicate Query-managed data

Examples:

- Navigation history for swipe-back previews
- UI preferences
- Temporary UI state shared across components

### Store Pattern

```typescript
// src/stores/navigationStore.ts
import { Store } from '@tanstack/store'

interface NavigationState {
  previousPath: string | null
  currentPath: string | null
}

export const navigationStore = new Store<NavigationState>({
  previousPath: null,
  currentPath: null,
})

export function updateNavigationHistory(newPath: string) {
  navigationStore.setState((state) => ({
    previousPath: state.currentPath,
    currentPath: newPath,
  }))
}
```

### Using Store in Components

```typescript
import { useStore } from '@tanstack/react-store'
import { navigationStore } from '@/stores/navigationStore'

function SwipeBackPreview() {
  const previousPath = useStore(navigationStore, (state) => state.previousPath)
  // ...
}
```

---

## Directory Organization

Organize by domain, and break into subdomains when complexity warrants:

```
src/
├── hooks/
│   ├── <domain>/                    # Simple domain - hooks at domain level
│   │   ├── use<Domain>.ts
│   │   └── use<Domain>Mutations.ts
│   ├── <domain>/                    # Complex domain - broken into subdomains
│   │   ├── <subdomain>/
│   │   │   ├── use<Subdomain>.ts
│   │   │   └── use<Subdomain>Mutations.ts
│   │   └── <subdomain>/
│   │       └── ...
│   └── ...
├── server/
│   ├── <domain>/                    # Mirror hooks structure
│   │   ├── get<Domain>s.ts
│   │   └── <subdomain>/
│   │       └── ...
│   └── ...
├── stores/                          # TanStack Store definitions
├── contexts/                        # React contexts
└── db/
    └── schemas/                     # Database schemas
```

## Quick Reference

| Need                         | Use                             |
| ---------------------------- | ------------------------------- |
| Fetch server data            | `useQuery` with server function |
| Paginated data               | `useInfiniteQuery`              |
| Mutate server data           | `useMutation` + invalidate      |
| Cross-component client state | TanStack Store                  |
| Component-local state        | `useState`                      |
| Query keys                   | Domain-specific key factories   |
| Server logic                 | `createServerFn`                |

## Anti-Patterns to Avoid

```typescript
// DON'T: Store Query data in local state
const { data } = useQuery({ queryKey, queryFn })
const [items, setItems] = useState(data) // Wrong!

// DO: Use Query data directly
const { data: items } = useQuery({ queryKey, queryFn })

// DON'T: Fetch in useEffect
useEffect(() => {
  fetch('/api/<domain>').then(setItems) // Wrong!
}, [])

// DO: Use useQuery with server function
const { data } = useQuery({
  queryKey: <domain>Keys.list(),
  queryFn: () => get<Domain>s({ data: {} }),
})

// DON'T: Forget to invalidate related caches
useMutation({
  mutationFn: create<Domain>,
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: ['<domain>'] }) // Incomplete!
  },
})

// DO: Invalidate all affected caches
useMutation({
  mutationFn: create<Domain>,
  onSuccess: (_, variables) => {
    queryClient.invalidateQueries({
      queryKey: <domain>Keys.list(),
    })
    queryClient.invalidateQueries({
      queryKey: <domain>Keys.detail(variables.id),
    })
    queryClient.invalidateQueries({
      queryKey: <subdomain>Keys.all,
    })
  },
})
```
