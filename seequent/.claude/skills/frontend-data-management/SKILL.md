---
name: frontend-data-management
description: Data fetching, caching, state management, and form conventions. Use when working with RTK Query, Redux Toolkit slices, or React Hook Form.
---

# Frontend Data Management Guide

This skill defines how data fetching, caching, state management, and forms work in this application.

## Technology Stack

| Purpose      | Technology                    | Usage                                  |
| ------------ | ----------------------------- | -------------------------------------- |
| Server State | RTK Query (`createApi`)       | Data fetching, caching, mutations      |
| Client State | Redux Toolkit (`createSlice`) | Cross-component UI and app state       |
| Forms        | React Hook Form 7 + Zod 4     | Form validation and submission (imago) |

## When to Use What

| Data Type                    | Use             | Example                                 |
| ---------------------------- | --------------- | --------------------------------------- |
| Server/remote data           | RTK Query       | API calls with caching and invalidation |
| Client-only, cross-component | Redux slice     | Selected item, drawer open/closed state |
| Component-local              | `useState`      | Uncontrolled inputs, local toggle state |
| Form state                   | React Hook Form | Controlled form inputs with validation  |

**Never duplicate:** If RTK Query is managing data, don't copy it into a Redux slice or `useState`.

---

## RTK Query

### Core Principles

1. **No raw `fetch` in components** — always use RTK Query hooks for data fetching
2. **API slice owns the lifecycle** — caching, deduplication, background refresh, tag invalidation
3. **Colocate API slices with domain** — slices live in `src/features/<domain>/`
4. **Tag-based cache invalidation** — use `providesTags` / `invalidatesTags` for consistency
5. **Small, focused endpoints** — each endpoint fetches exactly what that UI surface needs

### API Slice Pattern

```typescript
// src/features/<domain>/<domain>Api.ts
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react'

export const <domain>Api = createApi({
  reducerPath: '<domain>Api',
  baseQuery: fetchBaseQuery({ baseUrl: '/api' }),
  tagTypes: ['<Domain>'],
  endpoints: (builder) => ({
    get<Domain>s: builder.query<<Domain>[], <Domain>Filters | void>({
      query: (filters) => ({ url: '/<domain>s', params: filters }),
      providesTags: (result) =>
        result
          ? [
              ...result.map(({ id }) => ({ type: '<Domain>' as const, id })),
              { type: '<Domain>', id: 'LIST' },
            ]
          : [{ type: '<Domain>', id: 'LIST' }],
    }),
    get<Domain>ById: builder.query<<Domain>, string>({
      query: (id) => `/<domain>s/${id}`,
      providesTags: (result, error, id) => [{ type: '<Domain>', id }],
    }),
    create<Domain>: builder.mutation<<Domain>, Create<Domain>Input>({
      query: (body) => ({ url: '/<domain>s', method: 'POST', body }),
      invalidatesTags: [{ type: '<Domain>', id: 'LIST' }],
    }),
    update<Domain>: builder.mutation<<Domain>, Update<Domain>Input>({
      query: ({ id, ...body }) => ({ url: `/<domain>s/${id}`, method: 'PUT', body }),
      invalidatesTags: (result, error, { id }) => [{ type: '<Domain>', id }],
    }),
    delete<Domain>: builder.mutation<void, string>({
      query: (id) => ({ url: `/<domain>s/${id}`, method: 'DELETE' }),
      invalidatesTags: (result, error, id) => [
        { type: '<Domain>', id },
        { type: '<Domain>', id: 'LIST' },
      ],
    }),
  }),
})

export const {
  useGet<Domain>sQuery,
  useGet<Domain>ByIdQuery,
  useCreate<Domain>Mutation,
  useUpdate<Domain>Mutation,
  useDelete<Domain>Mutation,
} = <domain>Api
```

### Using RTK Query Hooks in Components

```typescript
function <Domain>List() {
  const { data, isLoading, isError } = useGet<Domain>sQuery()
  const [create<Domain>, { isLoading: isCreating }] = useCreate<Domain>Mutation()

  if (isLoading) return <CircularProgress />
  if (isError) return <Alert severity="error">Failed to load</Alert>

  return <>{data?.map(item => <<Domain>Card key={item.id} item={item} />)}</>
}
```

### Optimistic Updates

```typescript
update<Domain>: builder.mutation<<Domain>, Update<Domain>Input>({
  query: ({ id, ...body }) => ({ url: `/<domain>s/${id}`, method: 'PUT', body }),
  async onQueryStarted({ id, ...patch }, { dispatch, queryFulfilled }) {
    const patchResult = dispatch(
      <domain>Api.util.updateQueryData('get<Domain>ById', id, (draft) => {
        Object.assign(draft, patch)
      })
    )
    try {
      await queryFulfilled
    } catch {
      patchResult.undo()
    }
  },
}),
```

---

## Redux Toolkit — Client State

### When to Use a Slice

Use a Redux slice for state that is:

- **Client-only** — not derived from server data
- **Cross-component** — shared between unrelated components
- **Not in RTK Query** — never duplicate API-managed data

Examples: currently selected item ID, sidebar open state, active view mode.

### Slice Pattern

```typescript
// src/features/<domain>/<domain>Slice.ts
import { createSlice, PayloadAction } from '@reduxjs/toolkit'

interface <Domain>UiState {
  selectedId: string | null
  isDrawerOpen: boolean
}

const initialState: <Domain>UiState = {
  selectedId: null,
  isDrawerOpen: false,
}

export const <domain>Slice = createSlice({
  name: '<domain>',
  initialState,
  reducers: {
    setSelectedId(state, action: PayloadAction<string | null>) {
      state.selectedId = action.payload
    },
    toggleDrawer(state) {
      state.isDrawerOpen = !state.isDrawerOpen
    },
  },
})

export const { setSelectedId, toggleDrawer } = <domain>Slice.actions
```

### Using Slices in Components

```typescript
import { useSelector, useDispatch } from 'react-redux'
import { setSelectedId } from '@/features/<domain>/<domain>Slice'
import type { RootState } from '@/store'

function <Domain>Panel() {
  const dispatch = useDispatch()
  const selectedId = useSelector((state: RootState) => state.<domain>.selectedId)

  return <Button onClick={() => dispatch(setSelectedId(item.id))}>Select</Button>
}
```

---

## Forms — React Hook Form + Zod (imago)

```typescript
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const schema = z.object({
  name: z.string().min(1, 'Name is required'),
  value: z.number({ invalid_type_error: 'Must be a number' }).positive(),
})

type FormValues = z.infer<typeof schema>

function <Domain>Form({ onSubmit }: { onSubmit: (data: FormValues) => void }) {
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<FormValues>({
    resolver: zodResolver(schema),
  })
  // Wire up to MUI inputs — see frontend-ui skill for TextField integration
}
```

---

## Directory Organization

```
src/
├── features/
│   ├── <domain>/
│   │   ├── <domain>Api.ts           # RTK Query API slice
│   │   ├── <domain>Slice.ts         # Redux UI state slice (if needed)
│   │   ├── components/
│   │   └── hooks/
│   │       └── use<Domain>Form.ts   # React Hook Form wrapper (if complex)
│   └── ...
└── store/
    ├── index.ts                     # configureStore, RootState, AppDispatch
    └── middleware.ts
```

## Quick Reference

| Need                         | Use                                  |
| ---------------------------- | ------------------------------------ |
| Fetch server data            | RTK Query `useXxxQuery`              |
| Mutate server data           | RTK Query `useXxxMutation`           |
| Invalidate after mutation    | `invalidatesTags` on mutation        |
| Cross-component client state | Redux slice + `useSelector/Dispatch` |
| Component-local state        | `useState`                           |
| Form with validation         | React Hook Form + Zod                |

## Anti-Patterns to Avoid

```typescript
// DON'T: Copy RTK Query data into local state
const { data } = useGet<Domain>sQuery()
const [items, setItems] = useState(data) // Wrong!

// DO: Use RTK Query data directly
const { data: items } = useGet<Domain>sQuery()

// DON'T: Fetch in useEffect
useEffect(() => {
  fetch('/api/<domain>').then(setItems) // Wrong!
}, [])

// DON'T: Store server data in a Redux slice
dispatch(set<Domain>s(apiData)) // Wrong if RTK Query owns this data
```
