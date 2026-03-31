## Setup & Conventions

---

### Technology Stack

| Package | Version | Purpose |
|---|---|---|
| `jest` | 30.2.0 | Test runner |
| `@testing-library/react` | 16.3.0 | Component rendering and queries |
| `@testing-library/user-event` | 14.6.1 | Realistic user interactions |
| `@testing-library/jest-dom` | 6.9.1 | DOM assertion matchers |
| `ts-jest` | 29.4.6 | TypeScript support |
| `jest-fixed-jsdom` | — | Test environment (replaces plain jsdom) |
| `msw` | — | API mocking via service worker |
| `@local/jest-config-base` | — | Shared Jest config across monorepo apps |
| `@local/test-utils` | — | Shared render wrapper, store setup, MSW helpers |

---

### Test File Co-location

Test files live **next to the source file** they test. No `__tests__/` folders.

```
src/features/workspaces/
  WorkspaceCard.tsx
  WorkspaceCard.test.tsx       ← co-located
  WorkspaceList.tsx
  WorkspaceList.test.tsx
  workspaceApi.ts
  workspaceApi.test.ts
```

File naming: `<ComponentName>.test.tsx` for components, `<module>.test.ts` for non-JSX.

---

### Setup File

The global test setup file is `testUtils/test.setup.tsx` (not `src/setupTests.ts`).

```tsx
// testUtils/test.setup.tsx
import '@testing-library/jest-dom'
import { configure } from '@testing-library/react'
import fetchMock from 'jest-fetch-mock'

// Use automation-id as the test ID attribute (NOT data-testid)
configure({ testIdAttribute: 'automation-id' })

fetchMock.enableMocks()

// Mock window.matchMedia (not in jsdom)
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: jest.fn().mockImplementation((query) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: jest.fn(),
    removeListener: jest.fn(),
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  })),
})

// Mock ResizeObserver (not in jsdom)
global.ResizeObserver = jest.fn().mockImplementation(() => ({
  observe: jest.fn(),
  unobserve: jest.fn(),
  disconnect: jest.fn(),
}))

// DataDog packages mocked virtually (no real SDK in tests)
jest.mock('@datadog/browser-rum', () => ({ datadogRum: { init: jest.fn() } }))
jest.mock('@datadog/browser-logs', () => ({ datadogLogs: { init: jest.fn() } }))
```

---

### Test ID Attribute

**This project uses `automation-id`, not `data-testid`.**

This is configured globally in `test.setup.tsx`. All `getByTestId` / `findByTestId` / `queryByTestId` queries resolve against `automation-id`.

```tsx
// In component
<button automation-id="save-button">Save</button>

// In test
screen.getByTestId('save-button') // resolves automation-id="save-button"
```

---

### `renderWithProviders` — Standard Render Wrapper

Never use raw RTL `render()` for component tests. Use `renderWithProviders` from `src/utils/test-utils.tsx`, which wraps with all required providers:

```tsx
// src/utils/test-utils.tsx
import { render, RenderOptions } from '@testing-library/react'
import { Provider } from 'react-redux'
import { MemoryRouter } from 'react-router-dom'
import { IntlProvider } from 'react-intl'
import { ThemeProvider } from '@mui/material/styles'
import { configureStore } from '@reduxjs/toolkit'
import { EmberContextProvider } from '@/features/ember/EmberContext'
import { PanelManagerProvider } from '@/features/panels/PanelManager'
import { rootReducer } from '@/store'
import { api } from '@/store/api'

interface Options extends Omit<RenderOptions, 'wrapper'> {
  preloadedState?: Partial<RootState>
  route?: string
}

export function renderWithProviders(
  ui: React.ReactElement,
  { preloadedState = {}, route = '/', ...options }: Options = {}
) {
  const store = configureStore({
    reducer: rootReducer,
    middleware: (getDefault) => getDefault().concat(api.middleware),
    preloadedState,
  })

  function Wrapper({ children }: { children: React.ReactNode }) {
    return (
      <Provider store={store}>
        <MemoryRouter initialEntries={[route]}>
          <IntlProvider locale="en">
            <ThemeProvider theme={theme}>
              <EmberContextProvider>
                <PanelManagerProvider>
                  {children}
                </PanelManagerProvider>
              </EmberContextProvider>
            </ThemeProvider>
          </IntlProvider>
        </MemoryRouter>
      </Provider>
    )
  }

  return { store, ...render(ui, { wrapper: Wrapper, ...options }) }
}
```

`@local/test-utils` also exports a `render` wrapper (with `IntlProvider`) and `setupTestReduxStore` — use `renderWithProviders` for full component tests, `@local/test-utils` helpers for isolated unit tests.

---

### `@local/test-utils` Exports

| Export | Use |
|---|---|
| `render` | Render with `IntlProvider` only (no Redux/Router) |
| `setupTestReduxStore` | Create a configured store for slice/selector tests |
| `setupMswNodeServerForTesting` | Bootstrap MSW server with correct lifecycle hooks |
| `setupCesiumMocks` | Mock Cesium 3D engine (for geo-visualisation tests) |
| Test data constants | Shared fixture objects for common entity types |

---

### Test Naming Conventions

```tsx
describe('WorkspaceCard', () => {
  it('renders the workspace name', () => { ... })
  it('calls onSelect when clicked', async () => { ... })
  it('shows archived badge when workspace is archived', () => { ... })
  it('does not show archived badge for active workspaces', () => { ... })
})
```

- `describe` uses the component or module name
- `it` uses a plain English sentence, verb-first, lowercase
- No "should" — just state what happens: `'renders the name'` not `'should render the name'`
- Nested `describe` blocks for distinct states: `describe('when loading', () => { ... })`

---

### `screen` vs Destructured `render`

Both patterns are used. Prefer `screen` — it is consistent and works across multiple renders.

```tsx
// Preferred — screen
render(<WorkspaceCard name="Alpha" />)
expect(screen.getByRole('heading', { name: 'Alpha' })).toBeInTheDocument()

// Also acceptable — destructured (more common in older test files)
const { getByRole } = render(<WorkspaceCard name="Alpha" />)
expect(getByRole('heading', { name: 'Alpha' })).toBeInTheDocument()
```

Use `screen` for new tests. Don't refactor existing tests just to switch style.

---

### Import Conventions

```tsx
import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { renderWithProviders } from '@/utils/test-utils'
import { setupServer } from 'msw/node'
import { http, HttpResponse } from 'msw'
```

Do not import from `@testing-library/dom` directly — everything is re-exported from `@testing-library/react`.
