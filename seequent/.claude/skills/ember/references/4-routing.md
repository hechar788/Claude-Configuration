## Routing

---

### Route Definition

```typescript
// app/router.ts (imago-portal)
import EmberRouter from '@ember/routing/router'
import config from './config/environment'

export default class Router extends EmberRouter {
  location = config.locationType
  rootURL = config.rootURL
}

Router.map(function () {
  this.route('login')
  this.route('auth-callback')

  this.route('main', function () {
    this.route('desk', function () {
      this.route('imagery', function () {
        this.route('collection', { path: '/collections/:collection_id' }, function () {
          this.route('borehole', { path: '/:borehole_id' })
        })
      })
      this.route('collections')
      this.route('projects')
    })
    this.route('account', function () {
      this.route('profile')
      this.route('settings')
    })
    this.route('admin', function () {
      this.route('users')
      this.route('workspaces')
    })
  })

  this.route('not-found', { path: '/*path' })
})
```

Routes nest — `main.desk.imagery.collection.borehole` resolves to the URL `/main/desk/imagery/collections/:collection_id/:borehole_id`.

---

### imago-portal Route Structure

| Route level | Purpose |
|---|---|
| `application` | Root layout; session restore, SQID auth guard, iframe setup |
| `main` | Authenticated shell; injects session, sets up workspace context |
| `main.desk` | The primary work area; houses the Ember↔React iframe |
| `main.desk.imagery` | Imagery management sub-area |
| `main.account` | User account section |
| `main.admin` | Admin management (users, workspaces) |
| `login` | Unauthenticated; SQID login initiation |
| `auth-callback` | OAuth PKCE callback; exchanges code for token |

---

### Route Class Hooks

```typescript
// app/routes/main/desk/imagery/collection.ts
import Route from '@ember/routing/route'
import { inject as service } from '@ember/service'
import type Store from '@ember-data/store'
import type RouterService from '@ember/routing/router-service'
import type SessionService from '../../../services/session'

interface Params {
  collection_id: string
}

export default class CollectionRoute extends Route {
  @service declare store: Store
  @service declare router: RouterService
  @service declare session: SessionService

  // beforeModel — runs before model(); use for auth guards and redirects
  async beforeModel() {
    if (!this.session.isAuthenticated) {
      this.router.transitionTo('login')
    }
  }

  // model — fetches data; return value becomes @model in the template
  async model({ collection_id }: Params) {
    return this.store.findRecord('collection', collection_id)
  }

  // afterModel — runs after model resolves; use for redirects based on model data
  async afterModel(collection: CollectionModel) {
    if (collection.isArchived) {
      this.router.transitionTo('main.desk.collections')
    }
  }

  // setupController — runs after afterModel; sets controller properties beyond model
  setupController(controller: CollectionController, model: CollectionModel) {
    super.setupController(controller, model)
    controller.set('relatedBoreholes', model.boreholes)
  }

  // activate — runs when route becomes active (entered)
  activate() {
    this.deskSelection.setContext('imagery')
  }

  // deactivate — runs when route is exited
  deactivate() {
    this.deskSelection.clearContext()
  }
}
```

| Hook | When it runs | Use for |
|---|---|---|
| `beforeModel()` | Before model fetch | Auth guards, prerequisite redirects |
| `model()` | Main data fetch | Fetching the primary resource |
| `afterModel(model)` | After model resolves | Redirect based on model state |
| `setupController(controller, model)` | After afterModel | Set controller state beyond `model` |
| `activate()` | Route entered | Side effects: tracking, service state |
| `deactivate()` | Route exited | Cleanup, reset service state |

---

### Navigation

**`<LinkTo>` in templates:**
```handlebars
{{! Static route }}
<LinkTo @route="main.desk.collections">Collections</LinkTo>

{{! With dynamic segment }}
<LinkTo @route="main.desk.imagery.collection" @model={{@collection.id}}>
  {{@collection.name}}
</LinkTo>

{{! With multiple segments }}
<LinkTo @route="main.desk.imagery.collection.borehole" @models={{array @collection.id @borehole.id}}>
  {{@borehole.name}}
</LinkTo>
```

**Programmatic navigation in a class:**
```typescript
// Transition (pushes to history)
this.router.transitionTo('main.desk.collections')
this.router.transitionTo('main.desk.imagery.collection', collectionId)

// Replace (replaces current history entry — no back button)
this.router.replaceWith('main.desk.collections')
```

---

### Query Params

Declared on the **controller** (not the route):

```typescript
// app/controllers/main/desk/imagery.ts
import Controller from '@ember/controller'
import { tracked } from '@glimmer/tracking'

export default class ImageryController extends Controller {
  queryParams = ['filter', 'page']

  @tracked filter = 'all'
  @tracked page = 1
}
```

Route configuration for query param behaviour:
```typescript
// app/routes/main/desk/imagery.ts
export default class ImageryRoute extends Route {
  queryParams = {
    filter: {
      refreshModel: true,  // re-runs model() when filter changes
    },
    page: {
      refreshModel: true,
      replace: true,       // uses replaceWith instead of transitionTo (no history entry)
    },
  }

  model({ filter, page }: { filter: string; page: number }) {
    return this.store.query('imagery', { filter, page })
  }
}
```

**In a component, link with query params:**
```handlebars
<LinkTo @route="main.desk.imagery" @query={{hash filter="archived"}}>
  Archived
</LinkTo>
```

---

### Route-Driven Data Loading: Route vs Component

| Load in route | Load in component |
|---|---|
| Primary resource for the page | Secondary/supplementary data |
| Data needed before render (blocking) | Data that can load after render |
| Data shared across nested routes | Data specific to one UI element |
| Auth/redirect logic | User interactions that trigger fetches |

```typescript
// CORRECT: primary resource in route model hook
async model({ borehole_id }: Params) {
  return this.store.findRecord('borehole', borehole_id)
}

// WRONG: primary resource fetched in component
// Results in flash of empty state, no loading UI managed by router
@tracked borehole = null
constructor(owner, args) {
  super(owner, args)
  this.store.findRecord('borehole', this.args.boreholeId).then(b => this.borehole = b)
}
```

---

### Error Substates

When `model()` rejects, Ember looks for an `error` substate route or template:

```
app/templates/main/desk/imagery/error.hbs   ← catches model errors in imagery and below
app/templates/error.hbs                      ← global fallback
```

```handlebars
{{! app/templates/main/desk/imagery/error.hbs }}
<div class="error-state">
  <p>Failed to load imagery data.</p>
  <LinkTo @route="main.desk.collections">Go back</LinkTo>
</div>
```

---

### Anti-Patterns

```typescript
// DON'T: fetch data in the component constructor
// Use the route's model hook instead

// DON'T: use transitionTo with a full URL string
this.router.transitionTo('/main/desk/collections') // WRONG — use route name
this.router.transitionTo('main.desk.collections')  // CORRECT

// DON'T: put redirects in model() — they won't fire if model throws
// Use beforeModel() for pre-fetch redirects, afterModel() for post-fetch redirects

// DON'T: declare queryParams on the route without a matching controller property
// They will be silently ignored

// DON'T: use refreshModel: true for query params that don't affect the fetched data
// Triggers unnecessary network requests on every param change
```
