## Glimmer Components & Octane Patterns

This section covers the Glimmer component model used in **imago-portal** (Ember 5.12 Octane) and — to a lesser extent — **imago-admin** (Ember 3.28 LTS).

---

### Component Structure: Class + Template

```
app/components/my-widget/
  index.ts     ← component class
  index.hbs    ← template
```

The class extends `@glimmer/component` and receives a typed `Args` interface:

```typescript
// app/components/project-card/index.ts
import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { action } from '@ember/object'

interface Args {
  projectId: string
  projectName: string
  isArchived?: boolean
  onSelect: (id: string) => void
}

export default class ProjectCardComponent extends Component<Args> {}
```

The `Args` type parameter is the single source of truth for accepted arguments. **imago-portal** uses TypeScript throughout. **imago-admin** uses plain JavaScript — no `Args` typing.

---

### `@tracked` — Reactive State

`@tracked` marks a property as reactive. When it changes, any template or getter that read it re-renders.

```typescript
import { tracked } from '@glimmer/tracking'

export default class FilterPanelComponent extends Component<Args> {
  @tracked isExpanded = false
  @tracked searchQuery = ''
  @tracked selectedDepth: number | null = null
}
```

| Rule | Detail |
|---|---|
| Primitives | `@tracked` on the property is sufficient |
| Arrays/objects | Track the **reference** — reassign, never mutate in place |
| Derived values | Use a getter, not `@tracked` |

```typescript
// CORRECT — reassign to trigger reactivity
@tracked selectedIds: string[] = []

addId(id: string) {
  this.selectedIds = [...this.selectedIds, id]
}

// WRONG — mutation is not tracked
addId(id: string) {
  this.selectedIds.push(id) // template will NOT update
}
```

| Scenario | Solution |
|---|---|
| Value set by user interaction or async work | `@tracked` property |
| Value derived from tracked state or args | Getter |
| Value set once in constructor, never changes | Plain property |

---

### `@action` — Event Handlers

`@action` binds a method to the component instance, giving a stable reference for use in `{{on}}` and child components.

```typescript
import { action } from '@ember/object'

export default class ProjectCardComponent extends Component<Args> {
  @tracked isSelected = false

  @action
  handleClick() {
    this.isSelected = !this.isSelected
    this.args.onSelect(this.args.projectId)
  }

  @action
  handleKeyDown(event: KeyboardEvent) {
    if (event.key === 'Enter') this.handleClick()
  }
}
```

```handlebars
<div
  role="button"
  tabindex="0"
  {{on "click" this.handleClick}}
  {{on "keydown" this.handleKeyDown}}
>
  <h3>{{@projectName}}</h3>
</div>
```

**Never use `.bind()` in templates.** Without `@action`, each render creates a new function reference, causing unnecessary child re-renders.

---

### Template Syntax

| Syntax | Meaning |
|---|---|
| `{{this.propertyName}}` | Component class property or getter |
| `@argName` | Argument from parent (read-only) |
| `{{someLocal}}` | Block param or `{{#let}}` binding |

**`{{on}}` modifier** — wires DOM events to actions:
```handlebars
<button {{on "click" this.save}}>Save</button>
<form {{on "submit" this.handleSubmit}}>...</form>
```

**`{{fn}}` helper** — partially applies arguments to an action:
```handlebars
{{#each @items as |item|}}
  <button {{on "click" (fn this.selectItem item)}}>{{item.name}}</button>
{{/each}}
```

```typescript
@action
selectItem(item: ProjectItem) {
  this.selectedItem = item
}
```

---

### Component Args: `this.args.xxx`

Args are **read-only** — Glimmer enforces strict one-way data flow. A component cannot modify its own args.

```typescript
// CORRECT — call a callback, let the parent own the data
@action
resetFilter() {
  this.args.onChange(0)
}

// WRONG — mutating an arg
@action
resetFilter() {
  this.args.minDepth = 0 // TypeScript error + runtime warning
}
```

This replaces Ember Classic's two-way binding (`{{mut}}`, `{{input value=model.field}}`).

---

### Getters as Derived State

Getters replace `@computed`. They re-evaluate automatically when `@tracked` values or args they read change.

```typescript
export default class BoreholeListComponent extends Component<Args> {
  @tracked filterText = ''

  get filteredBoreholes() {
    const query = this.filterText.toLowerCase()
    return this.args.boreholes.filter(b => b.name.toLowerCase().includes(query))
  }

  get hasResults(): boolean {
    return this.filteredBoreholes.length > 0
  }

  get resultCount(): string {
    const n = this.filteredBoreholes.length
    return `${n} ${n === 1 ? 'borehole' : 'boreholes'}`
  }
}
```

**Memoization caveat:** Unlike `@computed`, plain getters are not memoized — they run on every access. For expensive getters, use `@cached` from `@glimmer/tracking`:

```typescript
import { cached } from '@glimmer/tracking'

@cached
get processedImages() {
  return this.args.images
    .filter(img => this.activeFilter === 'all' || img.type === this.activeFilter)
    .map(img => ({ ...img, thumbnailUrl: buildThumbnailUrl(img) }))
}
```

Use `@cached` deliberately — it has memory overhead. Cheap getters (booleans, string concatenation) don't need it.

---

### Named Blocks and `{{yield}}`

**Default block:**
```handlebars
{{! app/components/card-container/index.hbs }}
<div class="card">{{yield}}</div>
```

**Named blocks:**
```handlebars
{{! app/components/modal-dialog/index.hbs }}
<div class="modal">
  <header>{{yield to="header"}}</header>
  <div class="modal__body">{{yield to="body"}}</div>
  <footer>{{yield to="footer"}}</footer>
</div>
```

```handlebars
<ModalDialog>
  <:header><h2>Confirm Delete</h2></:header>
  <:body><p>This cannot be undone.</p></:body>
  <:footer>
    <button {{on "click" this.cancel}}>Cancel</button>
    <button {{on "click" this.confirm}}>Delete</button>
  </:footer>
</ModalDialog>
```

**Yielding values back to the caller (render-prop pattern):**
```handlebars
{{yield this.data this.isLoading this.error}}
```

```handlebars
<DataLoader @resourceId={{@id}} as |data isLoading error|>
  {{#if isLoading}}<LoadingSpinner />
  {{else if error}}<ErrorMessage @message={{error.message}} />
  {{else}}<ResourceDetail @data={{data}} />
  {{/if}}
</DataLoader>
```

---

### Modifiers

**Built-in `{{did-insert}}` / `{{will-destroy}}`** (from `@ember/render-modifiers`):

```handlebars
<canvas {{did-insert this.initChart}} {{will-destroy this.teardownChart}}></canvas>
```

```typescript
@action
initChart(element: HTMLCanvasElement) {
  this.chartInstance = new ChartJS(element, { type: 'line', data: this.args.chartData })
}

@action
teardownChart() {
  this.chartInstance?.destroy()
  this.chartInstance = null
}
```

**Custom modifier pattern** (using `ember-modifier`):

```typescript
// app/modifiers/auto-focus.ts
import Modifier from 'ember-modifier'

export default class AutoFocusModifier extends Modifier {
  modify(element: HTMLElement, _pos: [], named: { delay?: number }) {
    setTimeout(() => element.focus(), named.delay ?? 0)
  }
}
```

```handlebars
<input type="text" {{auto-focus delay=100}} />
```

---

### Classic vs Octane — imago-admin (3.28) vs imago-portal (5.12)

| Feature | imago-admin (Ember 3.28) | imago-portal (Ember 5.12) |
|---|---|---|
| Language | JavaScript | TypeScript with `Args` interface |
| Component base | Mix of Classic + Glimmer | `@glimmer/component` exclusively |
| Reactivity | `@tracked` available; `@computed` still present | `@tracked` + getters only |
| Two-way binding | `{{mut}}` still present | Removed — use callbacks |
| `this.set()` / `this.get()` | Present in Classic components | Not present |
| Template imports | Not available | Available in `.gts`/`.gjs` files |
| Styling | Bootstrap 4 + plain CSS | ember-css-modules + SCSS |

When editing imago-admin, you will encounter Classic components that use `this.set('property', value)`. New components written for imago-admin should use Glimmer style (`@tracked`, `@action`, getters) but cannot use template imports or strict mode.

---

### Anti-Patterns

```handlebars
{{! WRONG — mutating an arg with {{mut}} }}
<button {{on "click" (fn (mut @isOpen) true)}}>Open</button>

{{! CORRECT — use a callback action }}
<button {{on "click" this.open}}>Open</button>
```

```typescript
// WRONG — @tracked on a getter (does nothing)
@tracked get totalCost() { return this.args.items.reduce(...) }

// CORRECT — plain getter, auto-tracks its dependencies
get totalCost() { return this.args.items.reduce(...) }

// WRONG — mutating a tracked array in place
this.filters.push(f) // no reactivity

// CORRECT — reassign the reference
this.filters = [...this.filters, f]

// WRONG — using .bind() in a template
<button {{on "click" (fn this.save.bind this "draft")}}>

// CORRECT — use {{fn}} with an @action method
<button {{on "click" (fn this.save "draft")}}>

// WRONG — accessing DOM in the constructor
constructor(owner, args) {
  super(owner, args)
  this.canvas = document.querySelector('#canvas') // null — DOM not yet rendered
}

// CORRECT — use {{did-insert}}
@action setupCanvas(element: HTMLCanvasElement) { this.canvas = element }
```
