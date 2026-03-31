## Async Patterns & Mocking

---

### `waitFor`

Use `waitFor` when you need to assert that something **eventually becomes true** after an asynchronous side-effect — for example after an API call resolves, a Redux action dispatches, or a state update re-renders.

```tsx
import { render, screen, waitFor } from '@testing-library/react'

it('shows the workspace name after fetch resolves', async () => {
  render(<WorkspaceHeader workspaceId="ws-1" />)
  await waitFor(() => {
    expect(screen.getByText('Drill Site Alpha')).toBeInTheDocument()
  })
})
```

**Rules:**
- Do NOT put multiple unrelated assertions in one `waitFor` — RTL retries the whole callback, producing confusing failures. Wait for the async thing, then assert the rest synchronously.
- Do NOT use `waitFor(() => getBy*(...))` when `findBy*` exists.
- Do NOT put side-effects inside `waitFor` — the callback may be called many times.

---

### `findBy*` Queries

`findBy*` combines `waitFor` + `getBy*` into one call. Prefer it over `waitFor` for simple "wait until element appears" cases.

```tsx
// Preferred
const heading = await screen.findByRole('heading', { name: /workspace settings/i })

// Equivalent but more verbose — avoid
await waitFor(() => {
  expect(screen.getByRole('heading', { name: /workspace settings/i })).toBeInTheDocument()
})
```

---

### `act()`

RTL wraps all its utilities in `act()` automatically — `render`, `userEvent`, `fireEvent`, `waitFor`, `findBy*` all handle it. You almost never need to call `act()` directly.

The one legitimate case is **manually advancing fake timers**:

```tsx
jest.useFakeTimers()
render(<HeartbeatMonitor />)

act(() => {
  jest.advanceTimersByTime(1000) // trigger first ping
})

expect(mockSendMessage).toHaveBeenCalledWith({ type: 'ping' })
```

When you get `"not wrapped in act(...)"` warnings from `setInterval`, `postMessage`, or iframe bridge handlers, fix with `waitFor` for the DOM outcome — do not silence with manual `act()`.

---

### Mocking Modules

**Internal modules:**
```tsx
jest.mock('../utils/get-imago-ember-origin', () => ({
  getImagoEmberOrigin: jest.fn(() => 'https://imago-local.dev-sqnt.com:4201'),
}))
```

**`@local/*` shared libraries:**
```tsx
jest.mock('@local/error-logging', () => ({
  ErrorBoundary: ({ children }: { children: React.ReactNode }) => <>{children}</>,
  logError: jest.fn(),
}))

jest.mock('@local/app-config', () => ({
  getApiConfig: jest.fn(() => ({ apiHost: 'https://imago-ci.api.dev-sqnt.com' })),
}))
```

Place `jest.mock()` at the top of each test file — Jest hoists them regardless, but explicit placement avoids confusion.

---

### Mocking `getCombinedToken()` from `@local/login`

`getCombinedToken()` is called across every React app to obtain the bearer token. Always mock it — never hit real SQID OAuth in unit tests.

```tsx
jest.mock('@local/login', () => ({
  getCombinedToken: jest.fn(),
}))

import { getCombinedToken } from '@local/login'

beforeEach(() => {
  (getCombinedToken as jest.Mock).mockResolvedValue({
    access_token: 'test-access-token-abc123',
    token_type: 'Bearer',
  })
})
```

Unauthenticated / session-expired path:
```tsx
(getCombinedToken as jest.Mock).mockRejectedValue(new Error('Session expired'))
```

Testing the `setAccessToken` PostMessage sequence via `EmberContext`:
```tsx
it('sends the token to Ember on port receipt', async () => {
  (getCombinedToken as jest.Mock).mockResolvedValue({
    access_token: 'my-token',
    token_type: 'Bearer',
  })

  render(<EmberContextProvider>{/* ... */}</EmberContextProvider>)

  const channel = new MessageChannel()
  act(() => {
    window.dispatchEvent(
      new MessageEvent('message', {
        data: { type: 'port' },
        ports: [channel.port2],
        origin: 'https://imago-local.dev-sqnt.com:4201',
      })
    )
  })

  await waitFor(() => {
    expect(mockPortPostMessage).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'setAccessToken', accessToken: 'my-token' })
    )
  })
})
```

---

### Mocking LaunchDarkly Feature Flags

Mock `useFlags` — do not initialise a real LD client in Jest.

```tsx
jest.mock('@launchdarkly/react-client-sdk', () => ({
  useFlags: jest.fn(),
  useLDClient: jest.fn(),
  withLDProvider: (config: unknown) => (Component: React.ComponentType) => Component,
  LDProvider: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}))

import { useFlags } from '@launchdarkly/react-client-sdk'

beforeEach(() => {
  (useFlags as jest.Mock).mockReturnValue({
    'imagoui-disable-legacy-signin': true,
    'imagoui-auto-logout': false,
    'imagoui-new-upload-flow': true,
  })
})
```

Scope flag values per test when covering both branches:
```tsx
it('hides legacy signin when flag is on', () => {
  (useFlags as jest.Mock).mockReturnValue({ 'imagoui-disable-legacy-signin': true })
  render(<LoginPage />)
  expect(screen.queryByText('Sign in with Imago ID')).not.toBeInTheDocument()
})

it('shows legacy signin when flag is off', () => {
  (useFlags as jest.Mock).mockReturnValue({ 'imagoui-disable-legacy-signin': false })
  render(<LoginPage />)
  expect(screen.getByText('Sign in with Imago ID')).toBeInTheDocument()
})
```

---

### Faking Timers

Use `jest.useFakeTimers()` for debounced inputs, polling intervals, the 1000ms Ember heartbeat ping, and timeout-based UI.

```tsx
describe('Ember heartbeat', () => {
  beforeEach(() => jest.useFakeTimers())
  afterEach(() => jest.useRealTimers())

  it('sends a ping every 1000ms after the MessagePort is established', () => {
    render(<EmberContextProvider>{/* ... */}</EmberContextProvider>)
    // ... establish the port ...

    act(() => { jest.advanceTimersByTime(1000) })
    expect(mockPortPostMessage).toHaveBeenCalledTimes(1)
    expect(mockPortPostMessage).toHaveBeenCalledWith({ type: 'ping' }, [])

    act(() => { jest.advanceTimersByTime(1000) })
    expect(mockPortPostMessage).toHaveBeenCalledTimes(2)
  })
})
```

Always restore real timers in `afterEach`. Fake timers left active break `waitFor` (which uses `setTimeout` internally) and cause cascading timeout failures in subsequent tests.

---

### Testing Loading and Error States

Always test all three RTK Query states — never only the happy path.

**Loading state:**
```tsx
it('shows a loading spinner while fetching', () => {
  server.use(
    http.get('/api/1/workspaces', () => new Promise(() => {})) // never resolves
  )
  render(<WorkspaceList />)
  expect(screen.getByRole('progressbar')).toBeInTheDocument()
})
```

**Error state:**
```tsx
it('shows an error message when the fetch fails', async () => {
  server.use(
    http.get('/api/1/workspaces', () =>
      HttpResponse.json({ message: 'Unauthorised' }, { status: 401 })
    )
  )
  render(<WorkspaceList />)
  await screen.findByText(/failed to load workspaces/i)
  expect(screen.queryByRole('progressbar')).not.toBeInTheDocument()
})
```

**Token failure:**
```tsx
it('shows session-expired UI when token fetch throws', async () => {
  (getCombinedToken as jest.Mock).mockRejectedValue(new Error('Token expired'))
  render(<AppShell />)
  await screen.findByText(/your session has expired/i)
})
```

---

### Cleanup

```tsx
afterEach(() => {
  jest.clearAllMocks()  // clears call counts, keeps implementations
  jest.useRealTimers()  // restore if any test used fake timers
})
```

| Method | What it does |
|---|---|
| `jest.clearAllMocks()` | Clears `mock.calls/instances/results`, keeps implementation |
| `jest.resetAllMocks()` | Same as clear + removes `mockReturnValue`/`mockImplementation` |
| `jest.restoreAllMocks()` | Same as reset + restores originals for `jest.spyOn` |

Use `clearAllMocks()` in most `afterEach` blocks. Use `restoreAllMocks()` when using `jest.spyOn`.

**MSW reset:**
```tsx
// jest.setup.ts
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }))
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

---

### Anti-Patterns

```tsx
// DON'T: assert synchronous things inside waitFor
await waitFor(() => expect(screen.getByText('Title')).toBeInTheDocument()) // unnecessary

// DO: assert synchronously if render is immediate
expect(screen.getByText('Title')).toBeInTheDocument()

// DON'T: use getBy* immediately after async-triggering event
fireEvent.click(loadButton)
expect(screen.getByText('Data')).toBeInTheDocument() // not there yet

// DO: wait for it
await userEvent.click(loadButton)
expect(await screen.findByText('Data')).toBeInTheDocument()

// DON'T: leave useFlags returning {}
// All flag checks evaluate falsy — silently covers only the flag-off path

// DON'T: only test the happy path
// RTK Query exposes isError — components that render null on error are a real bug

// DON'T: use act() to silence console warnings — fix with waitFor instead
```
