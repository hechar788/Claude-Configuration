## Testing with ember-qunit

Ember tests use `ember-qunit` as the test runner adapter, `qunit-dom` for DOM assertions, and `@ember/test-helpers` for async interactions. `ember-exam` parallelises the suite. Tests live in `tests/` split across unit, integration (rendering), and acceptance.

---

### Test Types and Setup Helpers

| Helper | Boots | Use for |
|---|---|---|
| `setupTest(hooks)` | Owner/container only | Services, models, utils, pure logic |
| `setupRenderingTest(hooks)` | Renderer + owner | Components, helpers, modifiers, templates |
| `setupApplicationTest(hooks)` | Full app + router | Route hooks, multi-route flows, URL transitions |

### `setupTest` — Unit Tests

```javascript
import { module, test } from 'qunit'
import { setupTest } from 'ember-qunit'

module('Unit | Service | session', function (hooks) {
  setupTest(hooks)

  test('isAuthenticated returns false when no token', function (assert) {
    const service = this.owner.lookup('service:session')
    assert.false(service.isAuthenticated)
  })

  test('can register a mock dependency', function (assert) {
    this.owner.register('service:api', class {
      get baseUrl() { return 'https://test.example.com' }
    })
    const service = this.owner.lookup('service:my-service')
    assert.strictEqual(service.api.baseUrl, 'https://test.example.com')
  })
})
```

### `setupRenderingTest` — Component Tests

```javascript
import { module, test } from 'qunit'
import { setupRenderingTest } from 'ember-qunit'
import { render, click } from '@ember/test-helpers'
import { hbs } from 'ember-cli-htmlbars'

module('Integration | Component | drill-hole-card', function (hooks) {
  setupRenderingTest(hooks)

  test('renders the hole name', async function (assert) {
    this.set('hole', { name: 'BH-001', depth: 42 })
    await render(hbs`<DrillHoleCard @hole={{this.hole}} />`)
    assert.dom('[data-test-hole-name]').hasText('BH-001')
    assert.dom('[data-test-hole-depth]').hasText('42 m')
  })

  test('calls onSelect when clicked', async function (assert) {
    assert.expect(1)
    this.set('hole', { name: 'BH-001', depth: 42 })
    this.set('onSelect', (hole) => assert.strictEqual(hole.name, 'BH-001'))
    await render(hbs`<DrillHoleCard @hole={{this.hole}} @onSelect={{this.onSelect}} />`)
    await click('[data-test-hole-card]')
  })
})
```

### `setupApplicationTest` — Acceptance Tests

```javascript
import { module, test } from 'qunit'
import { setupApplicationTest } from 'ember-qunit'
import { visit, currentURL, click } from '@ember/test-helpers'

module('Acceptance | collections', function (hooks) {
  setupApplicationTest(hooks)

  test('navigates to collection detail', async function (assert) {
    await visit('/collections')
    assert.strictEqual(currentURL(), '/collections')
    await click('[data-test-collection="alpha"]')
    assert.strictEqual(currentURL(), '/collections/alpha')
    assert.dom('[data-test-collection-title]').hasText('Alpha')
  })
})
```

---

### Rendering Components

`render()` takes a tagged template literal from `hbs`. Arguments map to `this.*` on the test context.

```javascript
this.set('isLoading', false)
this.set('items', [{ id: 1, label: 'Core sample A' }])
this.set('onToggle', (id) => {})

await render(hbs`
  <ItemList
    @items={{this.items}}
    @isLoading={{this.isLoading}}
    @onToggle={{this.onToggle}}
  />
`)
```

**Updating args after render:**
```javascript
await render(hbs`<StatusBadge @status={{this.status}} />`)
this.set('status', 'error')
await settled()
assert.dom('[data-test-badge]').hasClass('badge--error')
```

---

### Setting Up Test Context

**`this.set()` — passing data to templates:**
```javascript
this.set('workspace', { id: 'ws-1', name: 'Project Alpha' })
this.set('onSave', () => {})
```

**`this.owner.register()` — injecting fakes:**
```javascript
this.owner.register('service:feature-flags', class {
  isEnabled(flag) { return flag === 'new-upload-ui' }
})
await render(hbs`<UploadButton />`)
```

---

### DOM Queries

```javascript
// find() / findAll() — native DOM elements
const input = find('[data-test-search-input]')
assert.strictEqual(input.placeholder, 'Search holes…')

const rows = findAll('[data-test-table-row]')
assert.strictEqual(rows.length, 5)
```

**`assert.dom()` — qunit-dom matchers (preferred):**
```javascript
assert.dom('[data-test-modal]').exists()
assert.dom('[data-test-spinner]').doesNotExist()
assert.dom('[data-test-title]').hasText('Borehole Log')
assert.dom('[data-test-subtitle]').containsText('42 m')
assert.dom('[data-test-save-btn]').hasAttribute('disabled')
assert.dom('[data-test-card]').hasClass('card--selected')
assert.dom('[data-test-depth-input]').hasValue('42')
assert.dom('[data-test-row]').exists({ count: 3 })
assert.dom('[data-test-error]').isVisible()
assert.dom('[data-test-hint]').isNotVisible()
```

**Convention:** Always use `data-test-*` selectors. Never couple tests to CSS classes or element tags.

---

### Mocking Services

**Pattern 1 — Inline class (stateless):**
```javascript
this.owner.register('service:notifications', class {
  success() {}
  error() {}
})
```

**Pattern 2 — Named class with state tracking:**
```javascript
hooks.beforeEach(function () {
  class MockNotifications {
    messages = []
    success(msg) { this.messages.push({ type: 'success', msg }) }
    error(msg)   { this.messages.push({ type: 'error',   msg }) }
  }
  this.notifications = new MockNotifications()
  this.owner.register('service:notifications', this.notifications, { instantiate: false })
})

test('shows success notification on save', async function (assert) {
  await render(hbs`<SaveButton @onSave={{this.onSave}} />`)
  await click('[data-test-save]')
  assert.strictEqual(this.notifications.messages[0]?.type, 'success')
})
```

`{ instantiate: false }` tells the container to use the provided instance directly rather than calling `new` on it.

**Pattern 3 — Patch a live service:**
```javascript
const session = this.owner.lookup('service:session')
session.set('currentUser', { id: 'u-1', name: 'Ada Lovelace' })
```

---

### Mocking ember-data Store

**Push fixtures directly:**
```javascript
hooks.beforeEach(function () {
  const store = this.owner.lookup('service:store')
  store.push({
    data: [
      { id: '1', type: 'collection', attributes: { name: 'Alpha', status: 'active' } },
      { id: '2', type: 'collection', attributes: { name: 'Beta',  status: 'archived' } },
    ],
  })
})
```

**Replace the adapter:**
```javascript
class StubAdapter extends JSONAPIAdapter {
  findAll() {
    return Promise.resolve({ data: [
      { id: '1', type: 'workspace', attributes: { name: 'Test WS' } },
    ]})
  }
}
this.owner.register('adapter:workspace', StubAdapter)
```

---

### Testing Route Hooks

```javascript
module('Acceptance | borehole detail', function (hooks) {
  setupApplicationTest(hooks)

  hooks.beforeEach(function () {
    const store = this.owner.lookup('service:store')
    store.push({
      data: { id: 'bh-1', type: 'borehole', attributes: { name: 'BH-001', depth: 120 } },
    })
  })

  test('model hook loads the borehole', async function (assert) {
    await visit('/boreholes/bh-1')
    assert.dom('[data-test-borehole-name]').hasText('BH-001')
    assert.dom('[data-test-depth]').hasText('120 m')
  })

  test('redirects to 404 for unknown id', async function (assert) {
    await visit('/boreholes/does-not-exist')
    assert.strictEqual(currentURL(), '/not-found')
  })

  test('beforeModel redirects when not authenticated', async function (assert) {
    const session = this.owner.lookup('service:session')
    session.set('isAuthenticated', false)
    await visit('/collections')
    assert.strictEqual(currentURL(), '/login')
  })
})
```

---

### Async Helpers

Always `await` async helpers — they call `settled()` internally before resolving.

| Helper | What it does |
|---|---|
| `await click(selector)` | Fires mousedown/mouseup/click + settles |
| `await fillIn(selector, value)` | Sets value, fires input/change + settles |
| `await select(selector, value)` | Selects `<option>` by text or value + settles |
| `await triggerEvent(selector, event)` | Fires arbitrary DOM event + settles |
| `await triggerKeyEvent(selector, type, key)` | Fires keyboard event + settles |
| `await settled()` | Waits for all timers, promises, and runloop queue flushes |

**When to use explicit `settled()`** — after mutating `this` state post-render, or after debounced logic:

```javascript
this.set('query', 'borehole')
await settled()
assert.dom('[data-test-result]').exists({ count: 2 })
```

**Realistic form test:**
```javascript
test('creates a new workspace', async function (assert) {
  await visit('/workspaces/new')
  await fillIn('[data-test-name-input]', 'Site 7 Survey')
  await select('[data-test-region-select]', 'Australia')
  await click('[data-test-submit-btn]')
  assert.strictEqual(currentURL(), '/workspaces')
  assert.dom('[data-test-workspace-name]').containsText('Site 7 Survey')
})
```

---

### ember-exam

```bash
ember exam                           # full suite
ember exam --split=4 --parallel      # parallel CI — run all partitions
ember exam --split=4 --partition=2   # run specific partition
ember exam --random                  # randomise order (finds order-dependent failures)
ember exam --random=<seed>           # replay a specific random order
ember test --filter="Integration | Component | drill-hole"  # filter during development
```

---

### Ember ↔ React/RTL Migration Reference

| Concern | Ember (ember-qunit) | React (RTL / Jest) |
|---|---|---|
| Render | `await render(hbs\`<MyComp @arg={{this.val}} />\`)` | `render(<MyComp arg={val} />)` |
| Pass args | `this.set('value', 42)` | Props in JSX |
| Update args | `this.set('value', 99); await settled()` | `rerender(<MyComp arg={99} />)` |
| Click | `await click('[data-test-btn]')` | `await userEvent.click(screen.getByTestId('btn'))` |
| Type | `await fillIn('[data-test-input]', 'hello')` | `await userEvent.type(screen.getByRole('textbox'), 'hello')` |
| Select | `await select('[data-test-sel]', 'Option A')` | `await userEvent.selectOptions(screen.getByRole('combobox'), 'Option A')` |
| Wait for async | `await settled()` | `await waitFor(...)` or implicit in userEvent v14 |
| Assert text | `assert.dom('[data-test-title]').hasText('Hello')` | `expect(screen.getByText('Hello')).toBeInTheDocument()` |
| Assert absent | `assert.dom('[data-test-err]').doesNotExist()` | `expect(screen.queryByTestId('err')).not.toBeInTheDocument()` |
| Assert class | `assert.dom('[data-test-card]').hasClass('selected')` | `expect(el).toHaveClass('selected')` |
| Mock service | `this.owner.register('service:foo', MockFoo)` | `jest.mock('../services/foo')` or context provider |
| Mock store/API | Stub adapter or `store.push()` fixtures | MSW request handlers |
| Route navigation | `await visit('/path')` + `currentURL()` | `MemoryRouter` initialEntries |
| Selector convention | `data-test-*` | `automation-id` (this project) |

**Key conceptual differences:**
- **No `this` context in RTL.** Props go directly in JSX. Use `rerender()` to update.
- **No `settled()` needed in RTL.** `userEvent` v14 is async throughout — use `waitFor()` only for external side effects.
- **Services become context or hooks.** `this.owner.register()` → React context provider or `jest.mock()`.
- **Adapter stubs become MSW handlers.** Ember adapter interception → `msw` request handlers.

---

### Anti-Patterns

```javascript
// DON'T: forget await on async helpers — assertions race and pass vacuously
click('[data-test-submit]')
assert.dom('[data-test-confirmation]').exists()

// DO:
await click('[data-test-submit]')
assert.dom('[data-test-confirmation]').exists()

// DON'T: use setupRenderingTest for pure logic — use setupTest (faster)

// DON'T: use setupApplicationTest for component tests — much slower than setupRenderingTest

// DON'T: couple selectors to CSS classes or element types

// DON'T: mutate this after render without await settled()
// Glimmer hasn't re-rendered yet when the assertion runs

// DON'T: register an instance without { instantiate: false }
// Ember calls new on your already-constructed object — double-instantiation error

// DON'T: share mutable mock state between tests
// Create fresh instances in beforeEach
```
