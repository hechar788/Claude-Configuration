# Getting Started

## Section 1: Running Imago Locally

Imago is made up of two apps that must both be running:

| App | Repo | URL | Notes |
|-----|------|-----|-------|
| `imago` (React) | `user-portal/apps/imago` | `https://imago-local.dev-sqnt.com:4200` | **Entry point — open this in your browser** |
| `imago-portal` (Ember) | `imago-portal` | `https://imago-local.dev-sqnt.com:4201` | Embedded as iframe inside React — **do not open directly** |

> ⚠️ Always navigate to **port 4200**. Port 4201 is the Ember app running inside an iframe — opening it directly will result in OAuth errors and a broken login experience.

---

### Prerequisites (one-time setup)

**1. Add hosts file entry**

Windows (run Notepad as Administrator, open `C:\Windows\System32\drivers\etc\hosts`):
```
127.0.0.1 imago-local.dev-sqnt.com
```

**2. Download SSL certificates**

From `user-portal/utils/`, run the appropriate script (requires Azure CLI — run `az login` first):
```bash
# macOS/Linux
./downloadDevSqntCerts.sh

# Windows
./downloadDevSqntCerts.ps1
```
This produces `dev-sqnt.pem` and `dev-sqnt.crt`. Certificates expire every 3 months and must be renewed.

**3. Copy certs to both app directories**
```bash
# From user-portal/utils/
cp dev-sqnt.pem dev-sqnt.crt ../apps/imago/
cp dev-sqnt.pem dev-sqnt.crt ../../imago-portal/
```

---

### Step 1: Start imago-portal (Ember, port 4201)

```bash
cd imago-portal
cp .env.example .env      # First time only — fill in SQID_CLIENT_ID etc.
pnpm install              # First time only
pnpm start                # → https://imago-local.dev-sqnt.com:4201
```

---

### Step 2: Start imago React app (port 4200)

```bash
# From user-portal root:
rush update               # First time only
rush build --to imago     # First time only

cd apps/imago
pnpm start                # → https://imago-local.dev-sqnt.com:4200
```

---

### Step 3: Open in browser

Navigate to:
```
https://imago-local.dev-sqnt.com:4200
```

Login is handled by the React app via Seequent ID (SQID) OAuth. Once authenticated, the token is automatically shared with the Ember iframe — you will not see a separate Ember login screen.

---

## Section 2: Running Imago MP Locally

Imago MP is the management portal for Imago. There are two versions:

| Version | Repo | URL | Notes |
|---------|------|-----|-------|
| `imago-admin` (Ember) | `imago-admin` | `http://localhost:4201` | Mature, full-featured |
| `imago-mp` (React) | `user-portal/apps/imago-mp` | TBD | Early-stage replacement for imago-admin |

> ⚠️ `imago-admin` and `imago-portal` both use port 4201 — never run them at the same time.

---

### Running imago-admin (Ember)

```bash
cd imago-admin
cp .env.example .env      # First time only
pnpm install              # First time only
pnpm start                # → http://localhost:4201
```

**Default dev credentials (pre-filled in `.env.example`):**
```
ADMIN_USERNAME=cloudadmin
ADMIN_PASSWORD=Velcro-Glitzy-Selector2
API_HOST=https://imago-ci.api.dev-sqnt.com
```

Open in browser: `http://localhost:4201`

---

### Running imago-mp (React)

```bash
# From user-portal root:
rush update               # First time only

cd apps/imago-mp
pnpm start
```

> **Note:** imago-mp is early-stage. Check `src/` for current feature coverage. For full admin functionality, use `imago-admin` (Ember) until migration is complete.

---

*For deeper architectural information — including how the React/Ember iframe integration works, authentication flows, API namespaces, route structures, and tech stack details — see [seequent-apps-dictionary.md](./seequent-apps-dictionary.md).*
