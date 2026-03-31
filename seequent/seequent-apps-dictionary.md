# Seequent Apps Dictionary

## How to Use This Dictionary

This file is a **technical reference** for Seequent's frontend applications. Use it to:

- Understand **what each app is**, what it does, and who uses it
- Know **how to start** each app locally (ports, prerequisites, env vars)
- Understand **how apps relate to each other** — which ones must run together, which embed others
- Find **key files** quickly when making changes (auth, API, routing, config)
- Understand the **migration strategy** — which apps are legacy Ember, which are the modern React replacements, and how they coexist during migration

**How entries are organised:** Each app is a `##` section. Subsections cover overview, repo path, how to run, tech stack, auth, API, routes, and key files. Add new apps at the bottom of the list before the final divider line.

**Quick orientation:** If you're new, read [System Architecture & How It All Fits Together](#system-architecture--how-it-all-fits-together) first — it explains ports, the iframe strategy, and why two apps run at once.

---

## Table of Contents

- [System Architecture & How It All Fits Together](#system-architecture--how-it-all-fits-together)
- [imago-portal](#imago-portal) — Legacy Ember.js imagery management app (standalone repo)
- [user-portal > imago](#user-portal--imago) — Modern React replacement, entry point for users (monorepo)
- [imago-admin](#imago-admin) — Legacy Ember.js management portal / imago-mp (standalone repo)
- [user-portal > imago-mp](#user-portal--imago-mp) — Modern React management portal, early-stage (monorepo)
- [user-portal monorepo](#user-portal-monorepo) — Rush.js monorepo containing all modern apps and shared libraries

---

## System Architecture & How It All Fits Together

### The Two Product Lines

Seequent has two distinct Imago products:

| Product | Purpose | Users |
|---------|---------|-------|
| **imago** | Geotechnical imagery management — uploading, browsing, annotating drill core images and borehole data | Field geologists, data managers |
| **imago-mp** (Management Portal) | Admin panel for Seequent staff — managing customer subscriptions, users, workspaces, tenants, support | Internal Seequent administrators |

Each product has a **legacy Ember app** (still in use) and a **modern React app** (in progress, gradually replacing the Ember one).

---

### The imago Migration Strategy: Two Apps, One UI

The core complexity of the imago product is that **two separate apps must run simultaneously** to serve one user experience.

```
USER'S BROWSER
└── https://imago-local.dev-sqnt.com:4200   ← React app (user-portal/apps/imago)
    ├── React AppBar, TopBar, SideMenu
    ├── React pages (routes that have been migrated)
    └── <iframe src="https://imago-local.dev-sqnt.com:4201/react?origin=...">
            └── Ember app (imago-portal) — all not-yet-migrated routes live here
```

**Why:** The Ember app is too large to migrate all at once. The React app wraps it and progressively replaces individual routes/pages. Until a feature is rewritten in React, the Ember app handles it inside the iframe.

**What the user sees:** A seamless single-page application. The React shell handles the top bar, navigation, and any migrated pages. The iframe is full-viewport and shows when an Ember route is active — users generally cannot tell which app they are in.

---

### The Iframe Mechanism in Detail

**Step 1 — URL resolution (`get-imago-ember-origin.ts`)**

When the React app loads, it looks at `window.location.host` and maps it to the Ember app's origin using a lookup table in:
`user-portal/apps/imago/src/utils/get-imago-ember-origin.ts`

```
React host (port 4200)              → Ember iframe URL (port 4201)
─────────────────────────────────────────────────────────────────
imago-local.dev-sqnt.com:4200       → https://imago-local.dev-sqnt.com:4201
imago1.dev-sqnt.com                 → https://eimago1.dev-sqnt.com
imago2.dev-sqnt.com                 → https://eimago2.dev-sqnt.com
imago3.dev-sqnt.com                 → https://eimago3.dev-sqnt.com
imago4.dev-sqnt.com                 → https://eimago4.dev-sqnt.com
imago5.dev-sqnt.com                 → https://eimago5.dev-sqnt.com
imago6.dev-sqnt.com                 → https://eimago6.dev-sqnt.com
imago7.dev-sqnt.com                 → https://eimago7.dev-sqnt.com
imago8.dev-sqnt.com                 → https://eimago8.dev-sqnt.com
imagotest.dev-sqnt.com              → https://eimagotest.dev-sqnt.com
imagoci.dev-sqnt.com                → https://eimagoci.dev-sqnt.com
imago.seequent.com                  → https://eimago.seequent.com
rimago.seequent.com                 → https://eimago.seequent.com  ← release/staging variant
```

**Naming convention:** React lives on `imago*`, Ember lives on `eimago*` (the `e` prefix = "ember"). Numbered slots 1–8 are shared dev environments on the CI infrastructure. `rimago` is a release/staging variant of production.

If the current host isn't in the map (e.g. running on localhost without the hosts file entry), `getImagoEmberOrigin()` returns `undefined` and the iframe is not rendered.

**Step 2 — Loading the iframe (`EmberFrame.tsx`)**

`user-portal/apps/imago/src/components/ember-frame/EmberFrame.tsx` renders the `<iframe>`. The iframe `src` is set to:
```
{emberOrigin}/react?origin={window.location.origin}&rand={uuid}
```
- The `origin` query param tells Ember which React host to communicate back to
- The `rand` uuid busts the cache on every load (prevents stale Ember app state)
- The Ember route `/react` is a special landing route that initialises the PostMessage channel

**Step 3 — Establishing the communication channel (`EmberContext.tsx`)**

`user-portal/apps/imago/src/context/EmberContext.tsx` manages all React↔Ember communication.

Sequence on load:
1. React renders the iframe pointing at `/react` on the Ember origin
2. Ember's `/react` route fires, creates a `MessageChannel`, sends one port to React via `window.postMessage({ type: 'port' }, reactOrigin)` with the port in `event.ports[0]`
3. React receives this in `onWindowMessage`, validates the origin against `/https:\/\/.*\.((seequent\.com)|(dev-sqnt\.com))(:[0-9]*)?/`
4. React stores the `MessagePort` and immediately sends a `setAccessToken` message through it containing the auth token, uid, addOns, apiEndpoint (dev only), and requested initial route
5. Ember receives the token, authenticates its own session, and navigates to the requested route
6. React sends a `ping` every **1000ms** through the channel as a heartbeat

**Messages React → Ember (via MessagePort):**
| Message type | Payload | Purpose |
|---|---|---|
| `setAccessToken` | `accessToken`, `tokenType`, `uid`, `addOns`, `apiEndpoint`, `initialRequestedRoute` | Bootstrap Ember session after load |
| `ping` | — | Heartbeat every 1s |
| Other route/command messages | varies | React-driven navigation or state changes |

**Messages Ember → React (via MessagePort):**
Ember sends state updates and navigation events back through its end of the port. The `useOnChannelMessageCallback` hook in React processes these.

**Promise timeout:** Any message sent from React that expects an acknowledgement will reject after **30 seconds** if no ack is received.

**Redux state for iframe lifecycle** (`ember-slice`):
- `isLoaded` — whether the Ember iframe has finished loading
- `isEmberRouteReady` — whether Ember has signalled it's ready to show
- The iframe is only rendered in the DOM once `isEmberRouteReady = true`; before that, a `<CircularProgress>` loading screen is shown

---

### Port Map — What Runs Where Locally

| App | URL | Notes |
|-----|-----|-------|
| `imago` (React, user-portal) | `https://imago-local.dev-sqnt.com:4200` | **Entry point** — open this in your browser |
| `imago-portal` (Ember) | `https://imago-local.dev-sqnt.com:4201` | Embedded inside React as iframe — do not open directly |
| `imago-admin` (Ember) | `http://localhost:4201` | Standalone, open directly |
| `imago-mp` (React, user-portal) | TBD | Standalone React app |
| `evo` | `https://...:4000` | Separate product |
| `blockmodel` | `https://...:4001` | Separate product |
| `gtmodeler` | `https://...:4003` | Separate product |
| `condsim-dashboard` | `https://...:4002` | Separate product |
| `cpt2bh` | `https://...:4400` | Separate product |
| `dev-portal` | `http://localhost:3000` | Docusaurus docs site |

> **Note:** `imago-portal` and `imago-admin` both default to port 4201 but they are never run at the same time — they serve entirely different products.

---

### Authentication Flow for imago

```
1. User navigates to https://imago-local.dev-sqnt.com:4200
2. React app loads, checks @local/login for existing session
3. If no session → redirect to Seequent ID (SQID) OAuth login
   - SQID is at https://uat-id.test.seequent.com (UAT) or https://id.seequent.com (prod)
   - OAuth 2.0 with PKCE (code verifier stored in sessionStorage)
   - Callback: /sqid/loginsuccess in imago-portal (Ember handles the OAuth callback)
4. Ember gets the token, validates it at /api/1/validate
5. Ember loads in the iframe and immediately sends the MessagePort to React
6. React receives the port, sends setAccessToken back through it
7. Both apps are now authenticated with the same token
   - imago-api-token header used for all API calls in both apps
```

The **shared token** is the key — React and Ember use the same `imago-api-token`. React passes it to Ember via the `setAccessToken` PostMessage. There is no separate Ember login screen when running inside the React host.

---

### API Namespaces

Both imago products talk to the same backend host but use different API namespaces:

| Namespace | Used by | Purpose |
|-----------|---------|---------|
| `/api/1` | imago-portal, imago (React) | Standard user-facing data (collections, imagery, workspaces, users) |
| `/mp/1` | imago-admin, imago-mp (React) | Management portal operations (subscriptions, tenants, billing, admin ops) |

Dev API host: `https://imago-ci.api.dev-sqnt.com`
Prod API host: `https://imago.api.seequent.com`

---

### Tech Stack Comparison

| | imago-portal | imago (React) | imago-admin | imago-mp (React) |
|--|--|--|--|--|
| **Status** | Legacy (active) | Modern (in progress) | Legacy (active) | Modern (early-stage) |
| **Framework** | Ember 5.12 | React 18 + Vite | Ember 3.28 | React 18 + Vite |
| **Language** | TS + JS | TypeScript | JavaScript | TypeScript |
| **Data fetching** | ember-data (REST) | RTK Query | ember-data (REST) | RTK Query |
| **State** | Ember services | Redux Toolkit | Ember services | Redux Toolkit |
| **Styling** | ember-css-modules | tss-react + MUI | Bootstrap 4 | tss-react + MUI |
| **Auth** | SQID OAuth PKCE | via @local/login | Username/password | TBD |
| **Feature flags** | LaunchDarkly | LaunchDarkly | — | LaunchDarkly |
| **API namespace** | `api/1` | `api/1` | `mp/1` | TBD |
| **Routing** | Ember Router | React Router 7 | Ember Router | React Router 7 |
| **Testing** | ember-qunit + Cypress | Jest + RTL | ember-qunit | Jest |
| **Repo** | imago-portal/ | user-portal/apps/imago/ | imago-admin/ | user-portal/apps/imago-mp/ |

---

---

## imago-portal

**Type:** Standalone repo | **Framework:** Ember.js 5.12 (Octane) | **Language:** TypeScript + JS

### Overview
The original Imago platform — a geotechnical imagery and drilling data management system. Provides tools for uploading, browsing, annotating, and analysing drill core images and borehole data. During migration to React, this app runs embedded as an `<iframe>` inside the React `imago` app. It is still the primary app for most features while migration is in progress.

**Do not run this standalone for normal development.** It must run alongside `user-portal/apps/imago` — see the architecture section above.

### Repo
`C:/Users/Hector.Harris/Documents/Github/imago-portal/`

### How to Run
```bash
cp .env.example .env          # fill in SQID_CLIENT_ID, Sentry DSN, DataDog tokens
pnpm install
# SSL certs: copy dev-sqnt.pem and dev-sqnt.crt from user-portal/utils/downloadDevSqntCerts.sh
# Hosts file: 127.0.0.1 imago-local.dev-sqnt.com
pnpm start                    # → https://imago-local.dev-sqnt.com:4201
```
**Port:** 4201 (accessed via iframe from port 4200, not directly)

**Other scripts:**
```bash
pnpm test                     # QUnit unit tests (parallel, split=4)
pnpm cypress:local            # Cypress E2E (needs IMAGO_INSPECTOR_SQUID_* env vars)
pnpm build:prod               # Production build
pnpm get-config / set-config  # Switch build-time API host config
```

### Tech Stack
| Concern | Library | Notes |
|---------|---------|-------|
| Framework | Ember.js 5.12.0 (Octane) | Modern Ember with decorators, glimmer components |
| Data layer | ember-data 5.7.0 | REST adapter, namespace `api/1` |
| Auth session | ember-simple-auth 6.1.0 | localStorage key: `imagosession` |
| Maps | ember-leaflet + Leaflet 1.9.4 | For `/desk/map` view |
| Image deep-zoom | openseadragon 5.0.1 | High-res image viewer |
| WebGL rendering | pixi.js-legacy 7.4.3 | Feature/annotation overlays |
| Async tasks | ember-concurrency 4.0.6 | Task-based async patterns |
| i18n | ember-intl 7.3.1 | All strings in `translations/en-us.yaml` (111KB) |
| Feature flags | ember-launch-darkly 5.2.4 | LaunchDarkly; dev client ID in environment.js |
| Analytics | Segment + DataDog RUM + Sentry | All configured via `.env` |
| CSS | ember-css-modules + ember-cli-sass | Scoped SCSS |
| Dropdowns | ember-power-select 8.8.0 | |
| Testing (unit) | ember-qunit + ember-exam | Parallel test splitting |
| Testing (E2E) | Cypress 14.5.4 | |
| Math | mathjs 13.2.3 + linear-algebra | For image analysis |

### Authentication
**Primary: Seequent ID (SQID) — OAuth 2.0 with PKCE**
- Authenticator: `app/authenticators/sqid.ts`
- Service: `app/services/seequent-id.js`
- Flow:
  1. `SeequentIdService.redirectToProvider()` — generates PKCE challenge, redirects to IDP
  2. IDP redirects to `/sqid/loginsuccess?code=...&state=...`
  3. `sqid.ts` exchanges code for tokens at `ENV.SQID.authenticationUrl`
  4. Calls `/api/1/validate` (via `subscription-manager.js`) to get uid + addOns
  5. Stores `apiToken`, `uid`, `addOns` in ember-simple-auth session
- PKCE verifier stored in `sessionStorage` (`PKCECODEVERIFIER` key)
- Prod IDP: `https://id.seequent.com/oauth2/authz`
- UAT IDP: `https://uat-id.test.seequent.com/oauth2/authz`
- SQID client ID: `imago-uat-fe` (set via `SQID_CLIENT_ID` env var)

**Legacy: Imago ID** (feature-flagged off)
- Authenticator: `app/authenticators/imago.js`
- Username/password → `PUT /api/1/signin` → `imago-api-token`
- Disabled by LaunchDarkly flag `imagoui-disable-legacy-signin`

**Enterprise SSO:** SAML 2.0 / ADFS via `/enterprise/:code` route

**When running inside the React iframe:** React passes the token via PostMessage (`setAccessToken`) — no user login screen is shown.

### API
- **Base URL:** `config/build-config.json` → `IMAGO_API_HOST`
  - Dev: `https://imago-ci.api.dev-sqnt.com`
  - Prod: `https://imago.api.seequent.com`
- **Namespace:** `api/1`
- **Auth header:** `imago-api-token` (from session)
- **Adapter:** `app/adapters/application.js` — REST, CORS with credentials
- **Auto-logout:** 401 responses trigger logout if LaunchDarkly flag `imagoui-auto-logout` is on
- **Main service:** `app/services/imago-api.ts` (1263 lines) — direct fetch calls for non-ember-data endpoints

### Route Structure
```
/login
/sqid/loginsuccess          ← OAuth callback
/enterprise/:code           ← Enterprise SSO
/enterprise/auth/:apitoken  ← Token-based SSO
/logout
/react                      ← Special: entry point when loaded in React iframe
/compatibility
/demo, /demo/drilling

/main (authenticated)
  /desk                     ← PRIMARY: image viewer
    /table                  ← Tabular data view
    /map                    ← Leaflet map view
    /gallery                ← Image gallery view
  /analytics
    /annotated
    /recentuploads
    /imageryintervalcheck
    /validations
  /account
    /workspaces
      /workspace/:id
        /dataset/:child_id
        /security
        /profile/:profile_id
    /workprofiles
      /workprofile/:wp_id
        /security, /securitygroups
    /imagery
      /imagerytypes → /imagerytype/:id/labels
      /featuredefs  → /featuredef/:id/:featuretype_id
      /attrdefs     → /attrdef/:id/:attributetype_id
      /labeldefs    → /labeldef/:id/:labeltype_id
      /legenddefs   → /legenddef/:id
    /training
      /dataset/:id → /attributes, /features, /security
    /secgroups
    /workspacetiers
    /general
    /tools                  ← Autocrop, assisted logging, reprocessing
  /admin
    /imagerytypes → /new
    /attributetables → /new
    /colourmaps → /edit/:id, /new
  /users → /add, /edit/:id
  /users/groups → /add, /edit/:id
  /api/display
  /api/v2/display
  /queue
  /react                    ← Iframe integration landing route
/denied, /terms, /error/:error
```

### Key Files
| File | Purpose |
|------|---------|
| `app/router.ts` | Full route map (204 lines) |
| `app/services/imago-api.ts` | Main API client (1263 lines, direct fetch) |
| `app/services/desk-selection.ts` | Desk view state — active imagery, layers (35KB) |
| `app/services/work-session.ts` | Session state, layout, user settings |
| `app/services/imago-react-service.ts` | PostMessage bridge back to React host |
| `app/services/subscription-manager.js` | Subscription validation at login |
| `app/services/seequent-id.js` | SQID OAuth service |
| `app/authenticators/sqid.ts` | OAuth 2.0 PKCE authenticator |
| `app/authenticators/imago.js` | Legacy username/password authenticator |
| `app/adapters/application.js` | REST adapter (api/1, imago-api-token header) |
| `config/environment.js` | All env + LaunchDarkly config |
| `config/build-config.json` | Build-time API host / domain |
| `translations/en-us.yaml` | All UI strings (111KB) |
| `cypress/e2e/commands.cy.js` | Cypress helpers incl. SQID login flow |
| `cypress/e2e/post-deploy/login.cy.js` | Login E2E tests |

### Environment Variables (`.env`)
```
SQID_CLIENT_ID=imago-uat-fe
SEGMENT_WRITE_KEY=
IMAGO_PORTAL_SENTRY_DSN=
DATA_DOG_APPLICATION_ID=
DATA_DOG_CLIENT_TOKEN=
ARTIFACTORY_TOKEN=
```

---

## user-portal > imago

**Type:** App in Rush monorepo | **Framework:** React 18 + Vite 6 | **Language:** TypeScript

### Overview
The modern React replacement for `imago-portal`. This is the **browser entry point** for the imago product — users navigate to the React app, which hosts the Ember app inside an iframe. New features are built here; Ember routes are replaced one by one. See [System Architecture](#system-architecture--how-it-all-fits-together) for the full iframe interaction model.

### Repo
`C:/Users/Hector.Harris/Documents/Github/user-portal/apps/imago/`

### How to Run
```bash
# Prerequisites: rush installed, Azure CLI authenticated, hosts file updated
# Hosts file entry: 127.0.0.1 imago-local.dev-sqnt.com

# From user-portal root:
rush update
rush build --to imago         # Build imago + all its @local/* dependencies

# Copy SSL certs into app dir:
cp dev-sqnt.pem dev-sqnt.crt apps/imago/

cd apps/imago
pnpm start                    # → https://imago-local.dev-sqnt.com:4200
```
**Port:** 4200 — this is what you open in your browser

**imago-portal must also be running on port 4201** for the iframe to load.

**Other scripts:**
```bash
pnpm build          # tsc + vite build + CSP header injection into index.html
pnpm test           # Jest unit tests
pnpm test:watch     # Jest watch mode
pnpm test:coverage  # Jest with coverage report
pnpm lint           # ESLint
pnpm lint-fix       # ESLint autofix
pnpm preview        # Preview production build locally
```

**Launch Darkly toolbar** (dev only): Open browser console and run `enableLDToolbar()` to override feature flags locally.

### Tech Stack
| Concern | Library | Version |
|---------|---------|---------|
| Framework | React | 18.3.1 |
| Build tool | Vite | 6.4.1 |
| Language | TypeScript | 5.6.2 |
| Routing | React Router | 7.12.0 |
| Server state | RTK Query (Redux Toolkit) | 2.11.0 |
| Client state | Redux Toolkit + React Redux | 2.11.0 / 9.2.0 |
| Forms | React Hook Form + Zod | 7.43.8 / 4.1.12 |
| UI components | MUI | 7.3.8 |
| Styling | tss-react + Emotion | 4.9.19 / 11.14 |
| Notifications | notistack | 3.0.2 |
| i18n | react-intl | 7.1.14 |
| Feature flags | LaunchDarkly React SDK | 3.9.0 |
| Error tracking | Sentry | via @sentry/vite-plugin — project: `seequent-ltd/imago-portal-react` |
| Date handling | dayjs | 1.11.13 |
| File upload | react-dropzone | 14.2.3 |
| Resizable panels | re-resizable | 6.11.2 |
| Testing | Jest + @testing-library/react | 30.2.0 / 16.3.0 |
| IDs | uuid | 11.1.0 |

### Iframe Integration (Full Detail)

**The iframe URL is determined by `src/utils/get-imago-ember-origin.ts`:**

```typescript
// Maps current React host → Ember iframe URL
export const getImagoEmberOrigin = () => {
    const { host } = window.location;
    return {
        'imago.seequent.com':               'https://eimago.seequent.com',
        'rimago.seequent.com':              'https://eimago.seequent.com',
        'imago-local.dev-sqnt.com:4200':    'https://imago-local.dev-sqnt.com:4201',
        'imagotest.dev-sqnt.com':           'https://eimagotest.dev-sqnt.com',
        'imagoci.dev-sqnt.com':             'https://eimagoci.dev-sqnt.com',
        'imago1.dev-sqnt.com':              'https://eimago1.dev-sqnt.com',
        // ... imago2–8
    }[host];
};
```
If the host is not in the map, `undefined` is returned and the iframe is not rendered.

**`EmberFrame.tsx`** (`src/components/ember-frame/EmberFrame.tsx`) renders:
```html
<iframe
  src="{emberOrigin}/react?origin={window.location.origin}&rand={uuid}"
  ref={emberFrameRef}
/>
```
- `rand` is a fresh UUID every mount — prevents caching
- Shows a `<CircularProgress>` loading screen until `isEmberRouteReady` is true in Redux

**`EmberContext.tsx`** (`src/context/EmberContext.tsx`) handles all communication:
- Validates incoming messages against origin regex: `/https:\/\/.*\.((seequent\.com)|(dev-sqnt\.com))(:[0-9]*)?/`
- Ember sends a `MessagePort` → React stores it and uses it for all subsequent messages
- React sends `setAccessToken` immediately on receiving the port
- Heartbeat: React pings Ember every 1000ms
- Promise timeout: 30s for any message expecting an acknowledgement

**Redux slice** (`ember-slice`):
- `isLoaded` — iframe has loaded
- `isEmberRouteReady` — Ember has signalled ready (iframe becomes visible)

### Authentication
Auth is handled by `@local/login` shared library. The React app itself does not implement login — it delegates entirely to the shared library. The token is then passed to Ember via `setAccessToken` through the MessagePort.

`getCombinedToken()` from `@local/login` returns `{ access_token, token_type }` which is sent to Ember.

### State Management
Redux store at `src/store/store.ts`. Slices in `src/store/slices/`:
| Slice | State |
|-------|-------|
| `ember-slice` | `isLoaded`, `isEmberRouteReady` — iframe lifecycle |
| `user-slice` | Current user uid, addOns, subscription |
| `active-imagery-slice` | Currently selected imagery items |
| `annotations-slice` | Annotation state |
| `custom-attributes-slice` | Custom attribute values |
| `feature-definitions-slice` | Feature definition cache |
| `image-analysis-review-slice` | Image analysis review state |

RTK Query API client: `src/apiClients/imago-api/` — 40+ endpoints covering collections, imagery, workspaces, users, training datasets, annotations, image analysis.

### Routes & Permissions
Routes defined in `src/hooks/use-imago-routes.tsx`. Permission levels gate access:
- `demo` — Demo users
- `standard` — Regular subscription users
- `subscription-owner` — Admins/owners
- `ml-training` — ML feature access

```
/ (imagery / desk view)
/gallery, /map
/account/workspaces → /:workspaceId → /security
/account/workprofiles → capture profiles
/account/tools → image processing tools
/account/imagery → data definitions (imagery types, features, attrs, labels, legends)
/account/training → ML training datasets
/analytics → /validations, /imageryintervalcheck, /annotated
/users → /:userId; /users/groups/:groupId
/api/v2/display, /api/display
/demo, /demo/drilling
/user_logout, /error, /enterprise/*
```

### Shared Libraries Used (`@local/*`)
| Library | Purpose |
|---------|---------|
| `@local/login` | Auth, token management, SQID login |
| `@local/error-logging` | ErrorBoundary + Sentry |
| `@local/metrics` | Analytics, DataDog |
| `@local/app-config` | API endpoint config per environment |
| `@local/web-design-system-2` | Primary UI design system (WDS2) |
| `@local/web-design-system` | Legacy UI components still in use |
| `@local/workspaces` | Workspace management components |
| `@local/user-manage` | User management utilities |
| `@local/webviz` | Visualisation components |
| `@local/svgs` | SVG icon assets |

### Key Files
| File | Purpose |
|------|---------|
| `src/utils/get-imago-ember-origin.ts` | **The** host → Ember URL mapping table |
| `src/context/EmberContext.tsx` | PostMessage bridge, port management, heartbeat |
| `src/components/ember-frame/EmberFrame.tsx` | Iframe component |
| `src/store/slices/ember-slice.ts` | Iframe load state in Redux |
| `src/hooks/use-imago-routes.tsx` | Route definitions + permission guards |
| `src/apiClients/imago-api/imago-api.ts` | RTK Query API client |
| `src/apiClients/imago-api/queries/` | 40+ individual query/mutation files |
| `src/store/store.ts` | Redux store config |
| `vite.config.ts` | Vite: HTTPS certs, Sentry plugin, CSP, LaunchDarkly toolbar asset |

---

## imago-admin

**Type:** Standalone repo | **Framework:** Ember.js 3.28 LTS | **Language:** JavaScript

### Overview
The **Management Portal** (imago-mp) — used by Seequent staff to administer the Imago platform. Manages customer subscriptions, user accounts, workspaces, tenants, storage backends, SSO configuration, support packages, and monitors sign-in activity and system warnings.

Runs standalone — not embedded in any other app. Communicates with the `mp/1` API namespace (management portal), which is entirely separate from the `api/1` namespace used by the user-facing imago apps.

### Repo
`C:/Users/Hector.Harris/Documents/Github/imago-admin/`

### How to Run
```bash
cp .env.example .env    # fill in credentials (see below)
pnpm install
pnpm start              # → http://localhost:4201
```
**Port:** 4201

**Dev credentials (`.env.example`):**
```
ADMIN_USERNAME=cloudadmin
ADMIN_PASSWORD=Velcro-Glitzy-Selector2
API_HOST=https://imago-ci.api.dev-sqnt.com
```

**Other scripts:**
```bash
pnpm build-dev          # Dev build
pnpm build-staging      # Staging build
pnpm build-prod         # Production build
pnpm lint:js            # ESLint
pnpm lint:hbs           # Template lint
ember test              # QUnit tests
```

### Tech Stack
| Concern | Library | Notes |
|---------|---------|-------|
| Framework | Ember.js 3.28.12 LTS | Not Octane — older patterns, some class-based |
| Data layer | ember-data 3.28.13 | REST adapter, namespace `mp/1` |
| Auth | ember-simple-auth 3.0.0 | localStorage key: `%@!7438yhgfjbv87@!%^#g` |
| UI | ember-bootstrap 4.9.0 + Bootstrap 4.6.2 | Bootstrap-based UI |
| Dropdowns | ember-power-select 8.7.3 | |
| Date picker | ember-pikaday 3.0.0 | |
| Async | ember-concurrency 4.0.4 | |
| AJAX | ember-ajax 5.1.2 + ember-fetch 7.1.0 | |
| Mock API (dev) | ember-cli-mirage 3.0.4 | |
| Testing | ember-qunit + QUnit | |
| IDs | uuid 3.2.1 | For record generation |

### Authentication
**Method:** Simple username/password → API token. No OAuth.

- **Sign in:** `PUT {host}/mp/1/signin` body: `{ username, password, product: 'imagoadmin' }` → `{ apiToken, uid }`
- **Validate (restore):** `POST {host}/mp/1/validate` with current token
- **Sign out:** `DELETE {host}/mp/1/signout`
- **Session:** Stored in localStorage under obfuscated key `%@!7438yhgfjbv87@!%^#g`
- **Auth header:** `imago-api-token: {token}` on all requests
- **Authenticator files:** `app/authenticators/imago.js` (production), `app/authenticators/debug.js` (dev stub)
- **SSO note:** The app configures SAML 2.0 / ADFS SSO for customer subscriptions (via the UI) but does not itself use SSO for admin login

### API
- **Base URL:** `process.env.API_HOST` (e.g. `https://imago-ci.api.dev-sqnt.com`)
- **Admin namespace:** `mp/1` — all management operations
- **Data namespace:** `api/1` — some supplementary data queries
- **Adapter:** `app/adapters/application.js` — REST, CORS with credentials, UUID v4 record IDs
- **Main service:** `app/services/imago-api.js` — all custom (non-ember-data) operations

#### Admin API Endpoints (`/mp/1/`)
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/signin` | PUT | Authenticate |
| `/validate` | POST | Validate/restore token |
| `/signout` | DELETE | Logout |
| `/adduser` | POST | Add user to subscription |
| `/chguserstate` | PUT | Enable / disable user |
| `/chgsubstate` | PUT | Change subscription state |
| `/changewrkstate` | PUT | Change workspace state |
| `/changauthstate` | PUT | Change SSO auth state |
| `/chguserpwd` | PUT | Reset user password |
| `/gentoken` | PUT | Generate user access token |
| `/sqid/users` | POST | Add Seequent ID users |
| `/listroles` | GET | List workspace roles |
| `/assignrole` | POST | Assign role to user in workspace |
| `/unassignrole` | DELETE | Remove role from user |
| `/image/access/` | GET | Get image store access URL |
| `/datasetImageryTypes` | GET | List dataset imagery types |
| `/resetdit` | POST | Reset dataset imagery type |
| `/{model}/{id}` (DELETE) | DELETE | Archive record |
| `/{model}/{id}` (PATCH) | PATCH | Unarchive record |

### Route Structure
```
/login
  /auth/:apitoken         ← SSO token callback
/portal (authenticated)
  / (index / dashboard)
  /sign-ins               ← Login activity audit log
  /support-warnings       ← System warnings with codes/subcodes
  /users                  ← Global user management
  /subscription/:id
    / (overview)
    /workspace/:workspace_id
    /reset-dataset/:workspace_id
    /multiple-users
    /archived
      /collection
      /:collection_id     ← Imagery in archived collection
    /support
      /support-packages_id
      /sso-authentication/:authentication_id
  /settings
    /tenants
    /tenant/:id
    /tenantstore/:id
/denied, /logout, /datalist
```

### Data Models
All models extend a `model-support.js` mixin that adds `state` (Active=`A`, Inactive=`I`, Archived=`X`) with `isActive` and `isArchived` computed properties.

| Model | Key attributes |
|-------|---------------|
| `subscription` | subscriptionName, planCode, customerName, region, sessionTimeOut |
| `user` | login, email, name, permission flags (hasSupportRole, hasEntitlementsRole, etc.) |
| `workspace` | name, description, access, imageStore, clientStore, containerId |
| `tenant` | name, tenantConnectionString, isDefault |
| `tenant-store` | storeType (image/client), isDefault |
| `addon` | product codes with billing |
| `authentication` | ssoType (adfs-saml), issuer, ispEntrypoint, ispPublicCert |
| `support-package` | support tier config |
| `support-warning` | code, subcode, lastReported, dailyTotals |
| `sign-in` | login activity records |
| `imagery-type`, `image-type` | format type definitions |
| `collection`, `dataset` | archived content |

**Product/plan reference data** (from `app/services/reference-data.js`):
- Products: `IMAGO-S`, `IMAGO-E`, `IMAGO-J` (Standard/Enterprise/Junior + hibernation variants), `IMAGO-CAPACITY-UNITS`, `MOBILE-CAPTURE`, `IMAGO-EAP`, `IMAGO-DATA-SHARING`, `CAPTURE-CHIP/CORE`
- Plan codes: academic, commercial, consultant, daily, e365, emergency-top-ups, internal, partner, overdrafts, support, training, trial, sponsorship, tpa-developer

### Mirage (Dev Mock API)
Active in development mode. Mocks: `users`, `subscriptions`, `tenants`, `tenantStores`, `addons`.
Fixtures in `mirage/fixtures/`: addons, authStrategies, authentications, subscriptions, tenantStores, tenants, users.

### Key Files
| File | Purpose |
|------|---------|
| `app/router.js` | Route map |
| `app/services/imago-api.js` | All custom admin API operations |
| `app/services/reference-data.js` | Plan/product codes, role checks |
| `app/authenticators/imago.js` | Username/password token auth |
| `app/adapters/application.js` | REST adapter (mp/1, imago-api-token header) |
| `config/environment.js` | API host, auth, CSP, session config |
| `mirage/config.js` | Dev mock API routes |
| `mirage/fixtures/` | Mock fixture data |
| `scripts/*.pgsql` | DB migration scripts for subscriptions |

---

## user-portal > imago-mp

**Type:** App in Rush monorepo | **Framework:** React 18 + Vite 6 | **Language:** TypeScript

### Overview
The modern React replacement for `imago-admin`. Currently **early-stage / barebones** — the foundation is in place but feature coverage is limited. It will gradually replace `imago-admin` using the same migration approach as `imago` replaces `imago-portal`. Simpler than the `imago` app — no Sentry integration, no custom CSP injection.

### Repo
`C:/Users/Hector.Harris/Documents/Github/user-portal/apps/imago-mp/`

### How to Run
```bash
# From user-portal root:
rush update
cd apps/imago-mp
pnpm start
```

### Tech Stack
Lighter version of the `imago` stack:
| Concern | Library |
|---------|---------|
| Framework | React 18.3.1 + Vite 6.4.1 |
| Language | TypeScript 5.6.2 |
| State | Redux Toolkit + RTK Query |
| UI | MUI v7 + tss-react + Emotion |
| Feature flags | LaunchDarkly React SDK |
| Testing | Jest |
| **Not included** | Sentry, custom CSP injection (unlike `imago`) |

### Status
Check `src/` for current feature coverage. As features are implemented here, they will replace routes currently handled by `imago-admin`.

---

## user-portal monorepo

**Type:** Rush.js monorepo | **Package manager:** pnpm 10.6.5 | **Node:** `>=22.12.0 <23.0.0`

### Overview
Seequent's main frontend monorepo containing all modern React applications and all shared libraries. 13 apps, 16+ shared libraries, managed with Rush v5. Apps share code through `@local/*` packages using pnpm workspaces.

### Repo
`C:/Users/Hector.Harris/Documents/Github/user-portal/`

### Setup & Key Commands
```bash
npm install -g @microsoft/rush       # Install Rush globally (once)
az login                             # Azure auth for build cache
rush update                          # Install all dependencies (like npm install)
rush update-cloud-credentials        # Refresh Azure SAS token for build cache
rush build --to <app>                # Build app + all its @local/* deps
rush build --from <lib>              # Build everything that depends on a lib
cd apps/<app> && pnpm start          # Run an app
cd apps/<app> && pnpm test           # Test an app
```

### All Apps
| App | Port | Build | Notes |
|-----|------|-------|-------|
| `imago` | 4200 | Vite | Main imago app — entry point for users |
| `imago-mp` | TBD | Vite | Management portal — imago-admin replacement |
| `evo` | 4000 | Vite | Enterprise app (Leaflet, Cesium, Arrow) |
| `blockmodel` | 4001 | Vite | BlockSync WebUI (ag-grid, Cesium, Playwright) |
| `central-portal` | — | Webpack | Central portal |
| `dev-portal` | 3000 | Docusaurus | Developer docs site (OpenAPI, MDX, Mermaid) |
| `gtmodeler` | 4003 | Vite | Geotechnical modeller (Immer, react-window) |
| `condsim-dashboard` | 4002 | Vite | Condition simulation (Plotly.js) |
| `cpt2bh` | 4400 | Vite | CPT2BH tool (Cesium, Leaflet, Arrow, Plotly) |
| `my-seequent` | — | Vite | MySeequent (D3/C3 charts, Stripe, RxJS) |
| `obsidian` | — | Vite | Obsidian app (Redux-persist, Playwright) |
| `public` | — | Webpack | Public-facing site |
| `template` | — | Vite | Starter template for new apps |

### Shared Libraries (`@local/*`)
| Package | Location | Purpose |
|---------|----------|---------|
| `@local/login` | `libraries/login/` | Auth, token handling, SQID + legacy login flows |
| `@local/error-logging` | `libraries/error-logging/` | ErrorBoundary + Sentry integration |
| `@local/metrics` | `libraries/metrics/` | Analytics + DataDog |
| `@local/app-config` | `libraries/app-config/` | Environment config, API endpoint resolution |
| `@local/web-design-system-2` | `libraries/web-design-system-2/` | **Primary** design system (WDS2) |
| `@local/web-design-system` | `libraries/web-design-system/` | Legacy design system (WDS1) |
| `@local/workspaces` | `libraries/workspaces/` | Workspace management |
| `@local/user-manage` | `libraries/user-manage/` | User management |
| `@local/shell` | `libraries/shell/` | Shell/layout container |
| `@local/webviz` | `libraries/webviz/` | Web visualisation |
| `@local/svgs` | `libraries/ui/svgs/` | SVG assets |
| `@local/content-area` | `libraries/ui/content-area/` | Content layout component |
| `@local/split-layout` | `libraries/ui/split-layout/` | Split layout (WDS1 + WDS2 variants) |
| `@local/filtering` | `libraries/ui/filtering/` | Filtering UI |
| `@local/waffle-menu` | `libraries/ui/waffle-menu/` | App switcher menu |
| `@local/central-portal-core` | `libraries/central-portal-core/` | Central portal shared logic |
| `@local/duckdb` | `libraries/duckdb/` | DuckDB integration |
| `@local/lineage-graph` | `libraries/lineage-graph/` | Lineage graph visualisation |

### API Libraries (`@api/*`)
`@api/azure`, `@api/colormap`, `@api/goose`, `@api/file`, `@api/lineage`, `@api/visualization`, `@api/task`, `@api/blockmodel`

### Coding Standards (from `CODINGSTANDARDS.md`)
- **Directory structure:** Feature-based — no `utilities/` or `common/` dumping grounds
- **No default exports**
- **File naming:** camelCase functions/variables, PascalCase components/types/classes, UPPERCASE constants; prefer `thing-name.ts` over `index.ts` for root files
- **File size:** Under 1000 lines (prefer few hundred)
- **Server state:** RTK Query only — never duplicate API data in Redux slices or `useState`
- **Client state:** Redux Toolkit slices
- **Forms:** React Hook Form + Zod
- **Styles:** tss-react `makeStyles` — no raw divs, no hardcoded colours, no inline styles, no `!important`
- **Layout:** MUI `Stack`, `Box`, `Grid2`
- **Icons:** `@mui/icons-material` only
- **Notifications:** notistack
- **Dependencies:** Be conservative — minimise coupling, prefer internal libraries over new npm packages

### Environments & Domains
| Environment | Domain pattern | Notes |
|-------------|---------------|-------|
| Local dev | `*-local.dev-sqnt.com` | Custom port, requires hosts file entry + SSL certs |
| CI | `*ci.dev-sqnt.com` | Automated CI environment |
| Dev slots 1–8 | `imago1-8.dev-sqnt.com` | Shared numbered dev environments |
| Test | `imagotest.dev-sqnt.com` | |
| Integration | `*.integration.seequent.com` | |
| Staging | `*.stage.seequent.com` | |
| Production | `*.seequent.com` | |

### Infrastructure
- **Hosting:** Azure Front Door + Static file storage accounts
- **SSL certs:** `dev-sqnt.pem` + `dev-sqnt.crt` for local dev (download via `utils/downloadDevSqntCerts.sh`)
- **CSP:** Content Security Policy injected into each app's `index.html` at build time (`infrastructure/contentSecurityPolicy/`)
- **Build cache:** Azure storage — incremental builds; refresh with `rush update-cloud-credentials`
- **CI/CD:** GitHub Actions
- **IaC:** Terraform in `infrastructure/main/` + `infrastructure/tf_modules/`
- **Source maps:** Sentry DevTools Sourcemap Extension (see `docs/Source_Maps.md`)

### Tools (`tools/`)
| Package | Purpose |
|---------|---------|
| `@local/eslint-config-base` | Shared ESLint config for all apps |
| `@local/jest-config-base` | Shared Jest config |
| `@local/test-utils` | Testing utilities and helpers |
| `@local/tsconfig-base` | Base TypeScript config |

---

*Add new app entries above this line, following the `##` dictionary format used above.*
