# Spec 00: Example Specification Template

## Overview

**Purpose:** _Describe what this specification covers and why it's needed._

**Scope:** _Define what is in scope and what is explicitly out of scope._

**Dependencies:**

- Spec 01a - [Dependency description]
- Existing component at `src/path/to/file.ts`

**Key Outputs:**

- `src/path/to/new/file.ts` - Description
- `src/path/to/another/file.ts` - Description

---

## Requirements

### Functional Requirements

1. **FR-1:** _Requirement description_
2. **FR-2:** _Requirement description_
3. **FR-3:** _Requirement description_

### Non-Functional Requirements

1. **NFR-1:** _Performance, security, or other constraint_

---

## Technical Design

### Data Model

```typescript
// Example type definition
interface ExampleType {
  id: string
  name: string
  createdAt: Date
}
```

### Server Functions

```typescript
// src/server/domain/exampleFunction.ts
import { createServerFn } from '@tanstack/start'
import { z } from 'zod'

const InputSchema = z.object({
  id: z.string().uuid(),
})

/**
 * Description of what this function does.
 *
 * @param data - Input parameters
 * @returns Description of return value
 */
export const exampleFunction = createServerFn({ method: 'GET' })
  .inputValidator((input: unknown) => InputSchema.parse(input))
  .handler(async ({ data }) => {
    // Implementation
    return { success: true }
  })
```

### React Hooks

```typescript
// src/hooks/domain/useExample.ts
import { useQuery } from '@tanstack/react-query'
import { exampleFunction } from '@/server/domain/exampleFunction'

/**
 * Hook description.
 *
 * @param id - Parameter description
 * @returns Query result with example data
 */
export function useExample(id: string) {
  return useQuery({
    queryKey: ['example', id],
    queryFn: () => exampleFunction({ data: { id } }),
    enabled: !!id,
  })
}
```

### UI Components

```typescript
// src/components/domain/ExampleComponent.tsx
interface ExampleComponentProps {
  /** Prop description */
  title: string
  /** Prop description */
  onAction: () => void
}

/**
 * Component description.
 */
export function ExampleComponent({ title, onAction }: ExampleComponentProps) {
  return (
    <div>
      <h1>{title}</h1>
      <button onClick={onAction}>Action</button>
    </div>
  )
}
```

---

## Implementation Checklist

### Phase 1: Foundation

- [ ] Define TypeScript types
- [ ] Create Zod validation schemas

### Phase 2: Server Functions

- [ ] Implement `exampleFunction`
- [ ] Add unit tests

### Phase 3: UI Components

- [ ] Create `ExampleComponent`
- [ ] Integrate with React hooks
- [ ] Add component tests

---

## Files to Create

| File                                         | Description      |
| -------------------------------------------- | ---------------- |
| `src/lib/domain/types.ts`                    | Type definitions |
| `src/server/domain/exampleFunction.ts`       | Server function  |
| `src/hooks/domain/useExample.ts`             | React hook       |
| `src/components/domain/ExampleComponent.tsx` | UI component     |

## Files to Modify

| File                         | Changes             |
| ---------------------------- | ------------------- |
| `src/server/domain/index.ts` | Export new function |
| `src/hooks/domain/index.ts`  | Export new hook     |

---

## Testing Strategy

### Unit Tests

- Test server function with valid/invalid inputs
- Test hook behavior with mocked server function

### Integration Tests

- Test full flow from UI to database

---

## Open Questions

- [ ] _Question that needs clarification?_
- [ ] _Decision that needs to be made?_

---

## Related Specs

- [01-related-spec.md](./01-related-spec.md) - How this relates
- [02-another-spec.md](./02-another-spec.md) - How this relates
