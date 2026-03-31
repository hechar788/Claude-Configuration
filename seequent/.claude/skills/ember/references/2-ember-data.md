## ember-data — Models, Adapters, Serializers

---

### Technology Stack

| Layer | Class | imago-portal | imago-admin |
|---|---|---|---|
| Models | `@ember-data/model` | TypeScript | JavaScript |
| Adapter | `RESTAdapter` | `api/1` namespace | `api/1` + `mp/1` |
| Serializer | `RESTSerializer` | Custom overrides | Custom overrides |

---

### Model Definition

```typescript
// app/models/borehole.ts (imago-portal)
import Model, { attr, belongsTo, hasMany } from '@ember-data/model'
import type CollectionModel from './collection'
import type SampleModel from './sample'

export default class BoreholeModel extends Model {
  @attr('string') declare name: string
  @attr('number') declare depth: number
  @attr('string') declare status: 'active' | 'archived'
  @attr('date')   declare createdAt: Date
  @attr()         declare metadata: Record<string, unknown> // untyped JSON

  @belongsTo('collection', { async: true, inverse: 'boreholes' })
  declare collection: AsyncBelongsTo<CollectionModel>

  @hasMany('sample', { async: true, inverse: 'borehole' })
  declare samples: AsyncHasMany<SampleModel>

  // Getters as computed properties (Octane style)
  get isArchived(): boolean {
    return this.status === 'archived'
  }
}

// TypeScript module augmentation for ember-data registry
declare module 'ember-data/types/registries/model' {
  export default interface ModelRegistry {
    borehole: BoreholeModel
  }
}
```

**`@attr` type transforms:**

| Transform | Type |
|---|---|
| `@attr('string')` | `string` |
| `@attr('number')` | `number` |
| `@attr('boolean')` | `boolean` |
| `@attr('date')` | `Date` |
| `@attr()` | Raw JSON (no transform) |

---

### Store API

```typescript
// In a route, component, or service
import { inject as service } from '@ember/service'
import type Store from '@ember-data/store'

class MyRoute extends Route {
  @service declare store: Store

  // Fetch all records (network request + cache population)
  async model() {
    return this.store.findAll('borehole')
  }

  // Fetch by ID
  async model({ borehole_id }: { borehole_id: string }) {
    return this.store.findRecord('borehole', borehole_id)
  }

  // Fetch with query params
  async model() {
    return this.store.query('borehole', { status: 'active', project_id: 'p-1' })
  }
}
```

| Method | Network | Cache | Returns |
|---|---|---|---|
| `findAll(type)` | Always | Populates | `RecordArray` (live) |
| `findRecord(type, id)` | Always | Populates | Record |
| `query(type, params)` | Always | Populates | `RecordArray` (snapshot) |
| `peekAll(type)` | Never | Reads | `RecordArray` (live) |
| `peekRecord(type, id)` | Never | Reads | Record or `null` |
| `createRecord(type, attrs)` | Never | Adds new | Unsaved record |

**Rule:** Use `peekRecord`/`peekAll` when you know the data is already in the store (e.g., after a `findAll`). Avoid redundant network requests.

---

### Creating, Saving, and Rolling Back

```typescript
// Create and save
const borehole = this.store.createRecord('borehole', {
  name: 'BH-042',
  depth: 0,
  status: 'active',
})

try {
  await borehole.save()
  // record is now persisted — id is populated
} catch (error) {
  borehole.rollbackAttributes() // discard unsaved changes, remove from store
  throw error
}

// Update and save
const borehole = await this.store.findRecord('borehole', 'bh-1')
borehole.name = 'Updated Name'
borehole.depth = 120

try {
  await borehole.save()
} catch {
  borehole.rollbackAttributes() // revert to last saved values
}

// Delete
await borehole.destroyRecord() // DELETE /api/1/boreholes/bh-1
```

---

### Adapter Configuration

The REST adapter for imago-portal uses the `api/1` namespace. imago-admin uses both `api/1` and `mp/1` depending on the model.

```typescript
// app/adapters/application.ts (imago-portal)
import RESTAdapter from '@ember-data/adapter/rest'
import { inject as service } from '@ember/service'

export default class ApplicationAdapter extends RESTAdapter {
  namespace = 'api/1'

  get headers() {
    return {
      Authorization: `Bearer ${this.session.data.authenticated.apiToken}`,
    }
  }

  // Custom URL for non-conventional endpoints
  urlForQuery(query: Record<string, unknown>, modelName: string) {
    if (modelName === 'project-imagery') {
      return `/${this.namespace}/projects/${query.projectId}/imagery`
    }
    return super.urlForQuery(query, modelName)
  }
}
```

For imago-admin models that use the `mp/1` namespace:
```javascript
// app/adapters/user.js (imago-admin)
import ApplicationAdapter from './application'

export default class UserAdapter extends ApplicationAdapter {
  namespace = 'mp/1'
}
```

---

### Serializer Conventions

```typescript
// app/serializers/application.ts
import RESTSerializer from '@ember-data/serializer/rest'

export default class ApplicationSerializer extends RESTSerializer {
  // API returns camelCase — no keyForAttribute override needed
  // If API returned snake_case:
  keyForAttribute(attr: string) {
    return underscore(attr) // 'createdAt' → 'created_at'
  }

  keyForRelationship(rawKey: string) {
    return underscore(rawKey)
  }

  // Strip unknown attributes that would cause Ember errors
  normalize(modelClass: Model, resourceHash: Record<string, unknown>) {
    delete resourceHash.unknownServerField
    return super.normalize(modelClass, resourceHash)
  }
}
```

---

### Async Relationships

`belongsTo` and `hasMany` relationships with `async: true` return proxies that load on access.

```typescript
// In a component or route
const borehole = await this.store.findRecord('borehole', 'bh-1')

// Access async belongsTo — triggers a network request if not cached
const collection = await borehole.collection

// Access async hasMany — triggers network request for all samples
const samples = await borehole.samples

// Check if already loaded without triggering a request
if (borehole.belongsTo('collection').value() !== null) {
  // already loaded
}
```

**Avoid N+1:** When rendering a list of boreholes that each display their collection name, pre-load via `store.query` with sideloaded data, or use `{ async: false }` with a `store.findAll` that includes the relationship.

---

### `model-support.js` Mixin (imago-admin)

All imago-admin models extend from a shared `model-support.js` mixin. It provides:

- **Dirty tracking helpers:** `isDirty` getter, `hasChanges` computed
- **Validation hooks:** `validate()` method called before `save()`
- **Error mapping:** Maps server validation errors onto model attributes
- **Safe save pattern:** `trySave()` that wraps `save()` with error handling

```javascript
// Usage pattern in imago-admin models
import DS from 'ember-data'
import ModelSupport from '../mixins/model-support'

export default DS.Model.extend(ModelSupport, {
  name: DS.attr('string'),
  email: DS.attr('string'),
})
```

When migrating imago-admin models to React/RTK Query, replicate this behavior with:
- Dirty tracking → `useForm` `formState.isDirty`
- Validation → Zod schema
- Error mapping → RTK Query error handling in `onQueryStarted`

---

### Anti-Patterns

```typescript
// DON'T: call findAll inside a component on every render
// Use the route model hook or a service to load data once

// DON'T: mutate relationships directly
borehole.samples.push(newSample) // does not persist, may corrupt cache

// DO: create the child record with the relationship set
const sample = this.store.createRecord('sample', {
  borehole: borehole,
  depth: 10,
})
await sample.save()

// DON'T: use findAll then filter in a component
// Use store.query with server-side filtering params instead

// DON'T: forget rollbackAttributes on save failure
try {
  await record.save()
} catch {
  // if you omit rollbackAttributes, the record stays in a dirty state
  record.rollbackAttributes()
}

// DON'T: use async: false for new relationships unless you're certain the data is always present
// It throws if the related record is not in the store
```
