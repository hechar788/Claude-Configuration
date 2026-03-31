## Testing Migrated Components (Ember → React)

Every component migrated from Ember to React must have a test suite that covers its behavioral contract — the observable outcomes a user or parent component depends on. Tests are not optional for migrated components.

---

### What Must Be Tested

When migrating an Ember component, derive the test checklist from the Ember component's responsibilities:

| Ember source | What to test in React |
|---|---|
| Template output (`hbs`) | Component renders correct markup given props |
| `@tracked` state | State changes in response to user interaction |
| Computed properties / getters | Derived values appear correctly in the UI |
| `@action` handlers | Callbacks are called with correct arguments |
| `{{if}}` / `{{unless}}` blocks | Conditional rendering based on props |
| `{{each}}` blocks | List rendering, empty state |
| `@service` dependencies | Mocked via context or `jest.mock()` |
| Route-driven `@model` | Data passed as props; test with preloaded Redux state or props directly |
| Ember events (`{{on "submit"}}`) | `userEvent` interactions trigger correct handlers |

---

### Mapping Ember Patterns to RTL

**Rendering a component:**
```javascript
// Ember (ember-qunit)
this.set('name', 'BH-001')
this.set('depth', 42)
await render(hbs`<DrillHoleCard @name={{this.name}} @depth={{this.depth}} />`)

// React (RTL)
render(<DrillHoleCard name="BH-001" depth={42} />)
```

**Passing and updating args:**
```javascript
// Ember — mutate this.* then settled()
this.set('isSelected', true)
await settled()
assert.dom('[data-test-card]').hasClass('selected')

// React — use rerender()
const { rerender } = render(<DrillHoleCard name="BH-001" isSelected={false} />)
expect(screen.queryByTestId('selected-indicator')).not.toBeInTheDocument()
rerender(<DrillHoleCard name="BH-001" isSelected={true} />)
expect(screen.getByTestId('selected-indicator')).toBeInTheDocument()
```

**DOM queries:**
```javascript
// Ember — CSS selectors + qunit-dom
assert.dom('[data-test-hole-name]').hasText('BH-001')
assert.dom('[data-test-depth]').containsText('42')
assert.dom('[data-test-badge]').doesNotExist()

// React — RTL queries + jest-dom
expect(screen.getByTestId('hole-name')).toHaveTextContent('BH-001')
expect(screen.getByTestId('depth')).toHaveTextContent('42')
expect(screen.queryByTestId('badge')).not.toBeInTheDocument()
```

**User interactions:**
```javascript
// Ember
await click('[data-test-select-btn]')
assert.ok(this.onSelect.calledOnce)

// React
const onSelect = jest.fn()
render(<DrillHoleCard name="BH-001" onSelect={onSelect} />)
await userEvent.click(screen.getByRole('button', { name: /select/i }))
expect(onSelect).toHaveBeenCalledWith('BH-001')
```

**Mocking a service:**
```javascript
// Ember
this.owner.register('service:feature-flags', class {
  isEnabled(flag) { return flag === 'new-imagery-panel'; }
})

// React — mock the hook or @local/* import
jest.mock('@launchdarkly/react-client-sdk', () => ({
  useFlags: jest.fn(() => ({ 'new-imagery-panel': true })),
}))
```

---

### Testing Components That Use the Ember Iframe Bridge

Components that interact with the React↔Ember iframe layer depend on Redux `ember-slice` state (`isLoaded`, `isEmberRouteReady`). Provide this via `preloadedState`.

```tsx
// Testing a component that renders only after Ember is ready
it('shows content when Ember iframe is loaded', () => {
  renderWithProviders(<ImagingWorkspace />, {
    preloadedState: {
      ember: {
        isLoaded: true,
        isEmberRouteReady: true,
        currentRoute: '/main/desk/imagery',
      },
    },
  })
  expect(screen.getByRole('main')).toBeInTheDocument()
  expect(screen.queryByRole('progressbar')).not.toBeInTheDocument()
})

it('shows a loading state while waiting for Ember', () => {
  renderWithProviders(<ImagingWorkspace />, {
    preloadedState: {
      ember: { isLoaded: false, isEmberRouteReady: false, currentRoute: null },
    },
  })
  expect(screen.getByRole('progressbar')).toBeInTheDocument()
})
```

For components that send PostMessage commands to Ember, mock `window.postMessage` or the message port:

```tsx
it('sends a navigate command to Ember when tab is clicked', async () => {
  const mockPostMessage = jest.fn()
  // Inject via context or spy on window
  jest.spyOn(window, 'postMessage').mockImplementation(mockPostMessage)

  renderWithProviders(<NavigationTabs />, {
    preloadedState: { ember: { isLoaded: true, isEmberRouteReady: true } },
  })

  await userEvent.click(screen.getByRole('tab', { name: /collections/i }))

  expect(mockPostMessage).toHaveBeenCalledWith(
    expect.objectContaining({ type: 'navigate', route: '/main/desk/collections' }),
    expect.any(String)
  )
})
```

---

### Testing Auth-Dependent Components

Components that call `getCombinedToken()` from `@local/login` must mock it. Never let tests hit real SQID OAuth.

```tsx
jest.mock('@local/login', () => ({
  getCombinedToken: jest.fn(),
}))
import { getCombinedToken } from '@local/login'

beforeEach(() => {
  (getCombinedToken as jest.Mock).mockResolvedValue({
    access_token: 'test-token',
    token_type: 'Bearer',
  })
})

it('bootstraps the Ember iframe with the access token', async () => {
  renderWithProviders(<AppBootstrap />)
  await waitFor(() => {
    expect(getCombinedToken).toHaveBeenCalled()
  })
  // Assert that the token was passed to the iframe setup
})
```

---

### Coverage Requirements for Migrated Components

Every migrated component must have tests covering:

- **Happy path render** — correct output given normal props
- **Empty/null props** — component handles missing optional data gracefully
- **Each significant conditional branch** — every `if`/`else` that changes visible UI
- **Each user interaction** — clicks, form submissions, keyboard interactions
- **Each callback prop** — called with correct arguments
- **Loading and error states** — if the component fetches data via RTK Query

Components that previously had Ember integration tests (`setupApplicationTest`) must have RTL tests that cover the same scenarios, plus explicit coverage of the iframe bridge if relevant.

---

### Red Flags: What Migrated Tests Commonly Miss

**Ember `@action` → React callback:** Ember actions were implicitly bound — they just worked when called from a template. In React, callbacks must be explicitly passed as props and tested explicitly.

**Computed property-derived values:** If an Ember getter computed a display string from multiple properties, the React equivalent (a `useMemo` or inline expression) must be tested with multiple input combinations.

**Route-driven `@model`:** In Ember, a component often received data via the route's model hook — this was "free" from the component's perspective. In React, this data comes from RTK Query hooks or Redux state. Test the component with different data states (loading, error, empty, populated).

**Implicit Ember service state:** If an Ember component read from a service (e.g. `session.currentUser`, `featureFlags.isEnabled('x')`), the React equivalent reads from Redux or a hook — ensure these are mocked in tests, not left as undefined.

**`{{each}}` empty state:** Ember templates with `{{else}}` blocks on `{{each}}` had explicit empty states. Ensure RTL tests cover the empty array case for any list component.

---

### Anti-Patterns

```tsx
// DON'T: only write the happy path
render(<WorkspaceCard workspace={mockWorkspace} />)
expect(screen.getByText(mockWorkspace.name)).toBeInTheDocument()
// Missing: loading, error, empty, conditional branches

// DON'T: leave ember-slice state at default (undefined)
renderWithProviders(<ImagingWorkspace />)
// Ember bridge components behave differently when isLoaded=false vs true

// DON'T: test implementation details from the Ember layer
// (e.g., asserting that a specific Redux action was dispatched)
// Test the user-visible outcome instead

// DON'T: skip tests because "it's a simple migration"
// Simple components still need at least a smoke test + interaction test

// DON'T: forget to mock getCombinedToken in any component that touches auth
// The test will hang waiting for a network request that never completes
```
