## Redux Slice & RTK Query Testing

---

### Quick Reference

| Test scenario | Tool |
|---|---|
| Reducer logic | Import reducer, call directly, assert state |
| Selectors | Build minimal state object, call selector |
| Component using `useQuery` | `renderWithProviders` + MSW handler |
| Component using `useMutation` | `renderWithProviders` + MSW handler + user interaction |
| Loading state | MSW handler that never resolves |
| Error state | MSW handler returning 4xx/5xx |
| Optimistic update | Assert before server responds, assert rollback on error |

---

### Testing Slice Reducers Directly

Import the reducer and call it with an action. No store or component needed.

```tsx
import workspaceReducer, {
  setSelectedId,
  toggleDrawer,
  WorkspaceUiState,
} from './workspaceSlice'

const initial: WorkspaceUiState = { selectedId: null, isDrawerOpen: false }

describe('workspaceSlice', () => {
  it('sets selectedId', () => {
    const state = workspaceReducer(initial, setSelectedId('ws-1'))
    expect(state.selectedId).toBe('ws-1')
  })

  it('clears selectedId when null is passed', () => {
    const state = workspaceReducer({ ...initial, selectedId: 'ws-1' }, setSelectedId(null))
    expect(state.selectedId).toBeNull()
  })

  it('toggles isDrawerOpen', () => {
    const opened = workspaceReducer(initial, toggleDrawer())
    expect(opened.isDrawerOpen).toBe(true)
    const closed = workspaceReducer(opened, toggleDrawer())
    expect(closed.isDrawerOpen).toBe(false)
  })
})
```

---

### Testing Selectors

Build the minimal shaped state your selector reads. Don't construct a full store.

```tsx
import { selectFilteredWorkspaces, selectSelectedWorkspace } from './workspaceSelectors'
import type { RootState } from '@/store'

const state = {
  workspace: {
    selectedId: 'ws-2',
    filterText: 'drill',
  },
  workspaceApi: {
    queries: {
      'getWorkspaces(undefined)': {
        status: 'fulfilled',
        data: [
          { id: 'ws-1', name: 'Alpha Borehole' },
          { id: 'ws-2', name: 'Drill Site B' },
          { id: 'ws-3', name: 'Survey Grid' },
        ],
      },
    },
  },
} as unknown as RootState

it('filters workspaces by filterText', () => {
  const result = selectFilteredWorkspaces(state)
  expect(result).toHaveLength(1)
  expect(result[0].name).toBe('Drill Site B')
})

it('returns the selected workspace', () => {
  const result = selectSelectedWorkspace(state)
  expect(result?.id).toBe('ws-2')
})
```

---

### MSW Server Setup

```tsx
// testUtils/server.ts
import { setupServer } from 'msw/node'
import { http, HttpResponse } from 'msw'

export const defaultHandlers = [
  http.get('/api/1/workspaces', () =>
    HttpResponse.json([
      { id: 'ws-1', name: 'Alpha', status: 'active' },
      { id: 'ws-2', name: 'Beta', status: 'active' },
    ])
  ),
  http.get('/api/1/workspaces/:id', ({ params }) =>
    HttpResponse.json({ id: params.id, name: 'Alpha', status: 'active' })
  ),
]

export const server = setupServer(...defaultHandlers)
```

```tsx
// jest.setup.ts  (or inside describe if localised)
import { server } from './testUtils/server'

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }))
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

`onUnhandledRequest: 'error'` ensures unmocked API calls fail loudly in tests.

---

### Testing `useQuery` Components

**Success state (default handler):**
```tsx
it('renders the workspace list', async () => {
  renderWithProviders(<WorkspaceList />)
  expect(await screen.findByText('Alpha')).toBeInTheDocument()
  expect(screen.getByText('Beta')).toBeInTheDocument()
})
```

**Loading state (handler that never resolves):**
```tsx
it('shows a spinner while loading', () => {
  server.use(
    http.get('/api/1/workspaces', () => new Promise(() => {})) // hangs forever
  )
  renderWithProviders(<WorkspaceList />)
  expect(screen.getByRole('progressbar')).toBeInTheDocument()
  expect(screen.queryByText('Alpha')).not.toBeInTheDocument()
})
```

**Error state:**
```tsx
it('shows an error alert when the request fails', async () => {
  server.use(
    http.get('/api/1/workspaces', () =>
      HttpResponse.json({ message: 'Forbidden' }, { status: 403 })
    )
  )
  renderWithProviders(<WorkspaceList />)
  expect(await screen.findByRole('alert')).toBeInTheDocument()
  expect(screen.queryByRole('progressbar')).not.toBeInTheDocument()
})
```

---

### Testing `useMutation` Components

```tsx
it('calls the create mutation and shows a success notification', async () => {
  server.use(
    http.post('/api/1/workspaces', () =>
      HttpResponse.json({ id: 'ws-new', name: 'New Site' }, { status: 201 })
    )
  )
  const user = userEvent.setup()
  renderWithProviders(<CreateWorkspaceForm />)

  await user.type(screen.getByLabelText(/name/i), 'New Site')
  await user.click(screen.getByRole('button', { name: /create/i }))

  expect(await screen.findByText(/workspace created/i)).toBeInTheDocument()
})

it('shows an error notification when the mutation fails', async () => {
  server.use(
    http.post('/api/1/workspaces', () =>
      HttpResponse.json({ message: 'Validation error' }, { status: 422 })
    )
  )
  const user = userEvent.setup()
  renderWithProviders(<CreateWorkspaceForm />)

  await user.type(screen.getByLabelText(/name/i), 'Bad Input')
  await user.click(screen.getByRole('button', { name: /create/i }))

  expect(await screen.findByText(/failed to create workspace/i)).toBeInTheDocument()
})

it('disables the submit button while the mutation is in flight', async () => {
  server.use(
    http.post('/api/1/workspaces', () => new Promise(() => {})) // hangs
  )
  const user = userEvent.setup()
  renderWithProviders(<CreateWorkspaceForm />)

  await user.type(screen.getByLabelText(/name/i), 'New Site')
  await user.click(screen.getByRole('button', { name: /create/i }))

  expect(screen.getByRole('button', { name: /create/i })).toBeDisabled()
})
```

---

### Testing Optimistic Updates

Test both the optimistic render and the rollback.

```tsx
it('shows the updated name immediately before server responds', async () => {
  // Server responds slowly
  server.use(
    http.put('/api/1/workspaces/:id', async () => {
      await delay(500)
      return HttpResponse.json({ id: 'ws-1', name: 'Updated Name' })
    })
  )
  const user = userEvent.setup()
  renderWithProviders(<WorkspaceEditor workspaceId="ws-1" />)

  await screen.findByDisplayValue('Alpha') // wait for initial load
  await user.clear(screen.getByRole('textbox', { name: /name/i }))
  await user.type(screen.getByRole('textbox', { name: /name/i }), 'Updated Name')
  await user.click(screen.getByRole('button', { name: /save/i }))

  // Optimistic update visible immediately
  expect(screen.getByDisplayValue('Updated Name')).toBeInTheDocument()
})

it('rolls back on mutation error', async () => {
  server.use(
    http.put('/api/1/workspaces/:id', () =>
      HttpResponse.json({ message: 'Server error' }, { status: 500 })
    )
  )
  const user = userEvent.setup()
  renderWithProviders(<WorkspaceEditor workspaceId="ws-1" />)

  await screen.findByDisplayValue('Alpha')
  await user.clear(screen.getByRole('textbox', { name: /name/i }))
  await user.type(screen.getByRole('textbox', { name: /name/i }), 'Updated Name')
  await user.click(screen.getByRole('button', { name: /save/i }))

  // Should roll back to original
  await waitFor(() => {
    expect(screen.getByDisplayValue('Alpha')).toBeInTheDocument()
  })
})
```

---

### Anti-Patterns

```tsx
// DON'T: use raw render — components need Redux, Router, IntlProvider
render(<WorkspaceList />)

// DO: use renderWithProviders
renderWithProviders(<WorkspaceList />)

// DON'T: mock RTK Query hooks directly — this bypasses the real caching/loading logic
jest.mock('./workspaceApi', () => ({ useGetWorkspacesQuery: jest.fn(() => ({ data: [] })) }))

// DO: use MSW to intercept at the network level

// DON'T: assert dispatch calls — test the resulting UI state instead
expect(mockDispatch).toHaveBeenCalledWith(setSelectedId('ws-1'))

// DO: assert what the user sees
expect(screen.getByText('Workspace selected')).toBeInTheDocument()

// DON'T: forget to await findBy* after mutations
await user.click(saveButton)
expect(screen.getByText('Saved!')).toBeInTheDocument() // not there yet

// DO:
await user.click(saveButton)
expect(await screen.findByText('Saved!')).toBeInTheDocument()

// DON'T: omit server.resetHandlers() — per-test overrides bleed into subsequent tests
```
