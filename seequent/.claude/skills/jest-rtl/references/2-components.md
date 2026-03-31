## Component Testing

---

### Query Priority

Use the most semantic query available. Fall back down the list only when necessary.

| Priority | Query | When to use |
|---|---|---|
| 1 | `getByRole` | Buttons, inputs, headings, links, checkboxes — anything with an ARIA role |
| 2 | `getByLabelText` | Form inputs associated with a `<label>` |
| 3 | `getByPlaceholderText` | Inputs with a placeholder (last resort for unlabelled inputs) |
| 4 | `getByText` | Non-interactive text content |
| 5 | `getByDisplayValue` | Selected value in a form control |
| 6 | `getByTestId` | `automation-id` attribute — only when nothing semantic works |

---

### Query Variants: `getBy` vs `queryBy` vs `findBy`

| Variant | Returns | Throws if missing | Async |
|---|---|---|---|
| `getBy*` | Element | Yes — use when element must be present | No |
| `queryBy*` | Element or `null` | No — use to assert absence | No |
| `findBy*` | Promise\<Element\> | Yes (after timeout) — use when element appears asynchronously | Yes |
| `getAllBy*` / `queryAllBy*` / `findAllBy*` | Array variants | — | — |

```tsx
// Assert presence (synchronous)
expect(screen.getByRole('button', { name: /save/i })).toBeInTheDocument()

// Assert absence
expect(screen.queryByText('Error loading data')).not.toBeInTheDocument()

// Assert async appearance
const heading = await screen.findByRole('heading', { name: 'Workspace Settings' })
expect(heading).toBeInTheDocument()
```

---

### `userEvent` vs `fireEvent`

Always use `userEvent` — it simulates realistic browser events (mousedown, focus, input, change, mouseup, click in sequence). `fireEvent` dispatches a single synthetic event.

```tsx
// Setup userEvent once per test (or in beforeEach)
const user = userEvent.setup()

it('submits the form', async () => {
  renderWithProviders(<WorkspaceForm onSubmit={mockSubmit} />)
  const user = userEvent.setup()

  await user.type(screen.getByRole('textbox', { name: /name/i }), 'Drill Site A')
  await user.click(screen.getByRole('button', { name: /save/i }))

  expect(mockSubmit).toHaveBeenCalledWith({ name: 'Drill Site A' })
})
```

Use `fireEvent` only when testing raw DOM events that `userEvent` doesn't model (custom drag-drop, file drops).

---

### Common Interactions

**Click:**
```tsx
await user.click(screen.getByRole('button', { name: /delete/i }))
```

**Type:**
```tsx
await user.type(screen.getByRole('textbox', { name: /search/i }), 'borehole')
// To clear first: await user.clear(input); await user.type(input, 'new value')
```

**Keyboard:**
```tsx
await user.keyboard('{Enter}')
await user.keyboard('{Escape}')
await user.tab() // move focus to next focusable element
```

**Select from a native `<select>`:**
```tsx
await user.selectOptions(screen.getByRole('combobox'), 'Australia')
```

---

### MUI v7 Gotchas

MUI components render into portals or use non-standard DOM structures. Key patterns:

**MUI Select (renders in a Portal):**
```tsx
// Open the dropdown first
await user.click(screen.getByRole('combobox', { name: /region/i }))
// The listbox appears in a portal — use findByRole to wait for it
const option = await screen.findByRole('option', { name: 'Australia' })
await user.click(option)
```

**MUI Dialog (renders in a Portal):**
```tsx
// Dialog content is in a portal outside the render container
// Use screen queries — they search the full document
await user.click(screen.getByRole('button', { name: /confirm/i }))
expect(await screen.findByRole('dialog')).toBeInTheDocument()
// Assert inside the dialog with `within`
const dialog = screen.getByRole('dialog')
expect(within(dialog).getByText('Are you sure?')).toBeInTheDocument()
```

**MUI Autocomplete:**
```tsx
const input = screen.getByRole('combobox', { name: /project/i })
await user.click(input)
await user.type(input, 'Alpha')
const option = await screen.findByRole('option', { name: 'Project Alpha' })
await user.click(option)
expect(input).toHaveValue('Project Alpha')
```

**MUI TextField (label association):**
```tsx
// MUI TextField renders a <label> — use getByLabelText
const input = screen.getByLabelText('Workspace Name')
await user.type(input, 'Site 7')
```

---

### `automation-id` Policy

Use `automation-id` attributes only when no semantic query works. Add them to components at authoring time — retrofitting is expensive.

```tsx
// Component
<IconButton automation-id="delete-workspace-btn" aria-label="Delete workspace">
  <DeleteIcon />
</IconButton>

// Test — prefer getByRole if the aria-label is meaningful
screen.getByRole('button', { name: /delete workspace/i })

// Use getByTestId only when role/label queries are ambiguous (e.g. multiple delete buttons)
screen.getByTestId('delete-workspace-btn')
```

---

### Testing Conditional Rendering

```tsx
it('shows the archived badge when workspace is archived', () => {
  renderWithProviders(<WorkspaceCard name="Alpha" isArchived={true} />)
  expect(screen.getByText('Archived')).toBeInTheDocument()
})

it('does not show the archived badge for active workspaces', () => {
  renderWithProviders(<WorkspaceCard name="Alpha" isArchived={false} />)
  expect(screen.queryByText('Archived')).not.toBeInTheDocument()
})

it('shows empty state when list has no items', () => {
  renderWithProviders(<WorkspaceList workspaces={[]} />)
  expect(screen.getByText('No workspaces found')).toBeInTheDocument()
  expect(screen.queryByRole('list')).not.toBeInTheDocument()
})
```

---

### Testing with Preloaded Redux State

Pass `preloadedState` to `renderWithProviders` to test components that depend on Redux state:

```tsx
it('shows the current user name from Redux state', () => {
  renderWithProviders(<UserMenu />, {
    preloadedState: {
      user: { id: 'u-1', name: 'Ada Lovelace', isAuthenticated: true },
    },
  })
  expect(screen.getByText('Ada Lovelace')).toBeInTheDocument()
})
```

---

### Anti-Patterns

```tsx
// DON'T: query by CSS class — breaks on renames
screen.getByClassName('workspace-card__title')

// DO: query by role or text
screen.getByRole('heading', { name: 'Project Alpha' })

// DON'T: use automation-id for everything
screen.getByTestId('save-btn')

// DO: use accessible queries first
screen.getByRole('button', { name: /save/i })

// DON'T: use fireEvent for user interactions
fireEvent.click(button)

// DO: use userEvent
await user.click(button)

// DON'T: assert with toHaveBeenCalledTimes(1) on every callback test
// — too brittle; assert the actual outcome instead

// DON'T: forget to await findBy* in async tests
const el = screen.findByText('Loaded') // returns a Promise, not an element
expect(el).toBeInTheDocument() // always passes — el is a Promise object

// DO:
const el = await screen.findByText('Loaded')
expect(el).toBeInTheDocument()
```
