## Services, Dependency Injection & State

---

### Defining a Service

```typescript
// app/services/workspace-settings.ts (imago-portal)
import Service from '@ember/service'
import { tracked } from '@glimmer/tracking'
import { inject as service } from '@ember/service'
import type RouterService from '@ember/routing/router-service'

export default class WorkspaceSettingsService extends Service {
  @service declare router: RouterService

  @tracked activeWorkspaceId: string | null = null
  @tracked isFilterPanelOpen = false

  get hasActiveWorkspace(): boolean {
    return this.activeWorkspaceId !== null
  }

  setWorkspace(id: string) {
    this.activeWorkspaceId = id
  }
}

// TypeScript module augmentation — required for @service injection to type-check
declare module '@ember/service' {
  interface Registry {
    'workspace-settings': WorkspaceSettingsService
  }
}
```

The registry augmentation is required in every service file. Without it, `@service declare workspaceSettings: WorkspaceSettingsService` will produce a TypeScript error.

---

### Injecting Services

```typescript
import { inject as service } from '@ember/service'
import type WorkspaceSettingsService from '../services/workspace-settings'
import type RouterService from '@ember/routing/router-service'
import type Store from '@ember-data/store'

export default class MyComponent extends Component<Args> {
  @service declare workspaceSettings: WorkspaceSettingsService
  @service declare router: RouterService
  @service declare store: Store
  @service declare session: SessionService // ember-simple-auth

  @action
  navigate() {
    this.router.transitionTo('main.desk.collections')
  }
}
```

Services are singletons per application instance — they share state across all consumers.

---

### Key Services in imago-portal

| Service | Purpose |
|---|---|
| `imago-api` | HTTP wrapper; adds auth token header to all API requests |
| `imago-react` / `imago-react-service` | Bridge to the React iframe; dispatches PostMessage commands |
| `session` | ember-simple-auth session; holds auth token and user info |
| `work-session` | Tracks the user's active workspace/project context |
| `desk-selection` | Tracks which desk/view is currently open |
| `context-settings` | User preferences and display settings |
| `router` | Ember built-in; navigation, current route inspection |
| `store` | Ember Data built-in; model cache and persistence |
| `intl` | Internationalisation (ember-intl) |

---

### `ember-simple-auth` Session Service

```typescript
import { inject as service } from '@ember/service'
import type SessionService from 'ember-simple-auth/services/session'

// Session data shape after SQID authentication
interface AuthenticatedData {
  apiToken: string
  uid: string
  addOns: string[]
}

export default class MyComponent extends Component<Args> {
  @service declare session: SessionService & {
    data: { authenticated: AuthenticatedData }
  }

  get isLoggedIn(): boolean {
    return this.session.isAuthenticated
  }

  get currentUserToken(): string {
    return this.session.data.authenticated.apiToken
  }

  @action
  async logout() {
    await this.session.invalidate()
    // ember-simple-auth triggers route transitions automatically after invalidation
  }
}
```

**Always guard access to `session.data.authenticated`** — it is `{}` when unauthenticated:
```typescript
// SAFE
const token = this.session.isAuthenticated
  ? this.session.data.authenticated.apiToken
  : null

// UNSAFE — throws when unauthenticated
const token = this.session.data.authenticated.apiToken
```

---

### SQID Authenticator (imago-portal)

The custom SQID authenticator in `app/authenticators/sqid.ts` implements the OAuth 2.0 PKCE flow:

1. `authenticate()` is called with the PKCE `code` from the callback URL
2. Exchanges the code for tokens by posting to the SQID token endpoint
3. Calls `subscriptionManager.loginToSubscription()` to resolve add-ons
4. Returns `{ apiToken, uid, addOns }` — stored in `session.data.authenticated`
5. `restore()` is called on page load — checks sessionStorage for existing tokens

On token failure/expiry, `session.invalidate()` clears the session and redirects to the login route.

---

### `imago-api` Service

All HTTP calls outside ember-data go through the `imago-api` service, which adds the auth token header automatically:

```typescript
// app/services/imago-api.ts pattern
export default class ImagoApiService extends Service {
  @service declare session: SessionService

  async fetch(url: string, options: RequestInit = {}): Promise<Response> {
    const token = this.session.data.authenticated.apiToken
    return fetch(url, {
      ...options,
      headers: {
        'imago-api-token': token,
        'Content-Type': 'application/json',
        ...options.headers,
      },
    })
  }

  async get<T>(path: string): Promise<T> {
    const response = await this.fetch(`/api/1/${path}`)
    if (!response.ok) throw new Error(`API error: ${response.status}`)
    return response.json()
  }
}
```

---

### LaunchDarkly Feature Flags

Feature flags in imago-portal are accessed via the `variation()` function imported directly from the LaunchDarkly SDK — not via a service wrapper:

```typescript
// app/types/variation.d.ts — typed union of all known flag keys
type FeatureFlag =
  | 'imagoui-disable-legacy-signin'
  | 'imagoui-auto-logout'
  | 'imagoui-new-upload-flow'
  | 'imagoui-enable-3d-viewer'

// Usage in a component
import { variation } from 'ember-launch-darkly'

export default class UploadButton extends Component<Args> {
  get useNewFlow(): boolean {
    return variation('imagoui-new-upload-flow') as boolean
  }
}
```

In tests, mock `variation` via `this.owner.register` or `jest.mock` (for tests migrated to Jest):

```javascript
// ember-qunit test
this.owner.register('service:launch-darkly', class {
  variation(flag) {
    return flag === 'imagoui-new-upload-flow'
  }
})
```

---

### Services as Shared State (Ember Redux Equivalent)

Services are the Ember equivalent of a Redux store — they hold cross-component state accessible anywhere.

```typescript
// Services replace Redux slices in imago-portal
// React (imago):                   Ember (imago-portal):
// useSelector(state => state.desk) this.deskSelection.activeDeskId
// dispatch(setDesk(id))            this.deskSelection.setDesk(id)
// useSelector(state => state.user) this.session.data.authenticated.uid
```

When migrating a component, identify which services it reads from and map them to the corresponding Redux state or RTK Query endpoint.

---

### Getters as Computed Properties

Replace `@computed` with plain getters. They auto-track `@tracked` properties and `this.args.*`.

```typescript
// Classic (imago-admin) — @computed
import { computed } from '@ember/object'
export default class MyComponent extends Component {
  @computed('items.length')
  get hasItems() { return this.items.length > 0 }
}

// Octane (imago-portal) — plain getter
export default class MyComponent extends Component<Args> {
  get hasItems(): boolean {
    return this.args.items.length > 0
  }
}
```

For expensive getters called multiple times per render, use `@cached`:

```typescript
import { cached } from '@glimmer/tracking'

@cached
get processedItems() {
  return this.args.items.filter(...).map(...)
}
```

---

### Anti-Patterns

```typescript
// DON'T: access session.data.authenticated without an isAuthenticated guard
const token = this.session.data.authenticated.apiToken // throws when unauthenticated

// DON'T: make direct fetch calls without going through imago-api service
const response = await fetch('/api/1/boreholes') // missing auth token

// DON'T: store mutable arrays in a service without @tracked
items: string[] = [] // mutations won't trigger template updates
@tracked items: string[] = [] // correct

// DON'T: use @computed in new code for imago-portal (Octane)
// Use plain getters instead

// DON'T: register multiple consumers of the same tracked state as separate properties
// Use a single shared service to avoid sync bugs
```
