# Hype Music

Letterboxd for music — SwiftUI iOS app with a FastAPI backend in `../../backend/`.

## Prerequisites

- Xcode (iOS 17+)
- Python 3.11+ with a project venv in `backend/.venv`
- PostgreSQL with database `tap_in` (default URL in `backend/database.py`)
- Sign in with Apple capability enabled for bundle ID `com.jacobhancock.HypeMusic`

## Local development

### 1. Backend

```bash
cd ../../backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # then edit .env
```

**macOS SSL (required for Sign in with Apple):** The backend fetches Apple’s public keys over HTTPS. If you see `CERTIFICATE_VERIFY_FAILED` in the uvicorn log, install certs for your Python (common with python.org builds):

```bash
# Adjust version if needed, e.g. Python 3.14
open "/Applications/Python 3.14/Install Certificates.command"
```

Verify:

```bash
.venv/bin/python -c "from jwt import PyJWKClient; PyJWKClient('https://appleid.apple.com/auth/keys').get_jwk_set(); print('OK')"
```

**Run the API** (keep this terminal open):

```bash
cd ../../backend
source .venv/bin/activate
set -a; source .env; set +a
.venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Always use `.venv/bin/uvicorn` or `.venv/bin/python` — a global `uvicorn` may use the wrong Python and fail with `cannot import name 'PyJWKClient' from 'jwt'` (wrong `jwt` package vs **PyJWT**).

**Smoke test** (second terminal, while the server is running):

```bash
curl http://127.0.0.1:8000/docs
```

### 2. `backend/.env`

| Variable | Purpose |
|----------|---------|
| `JWT_SECRET` | Signs app session tokens after Apple sign-in. Optional locally (defaults to `dev-secret-change-me`). Use a long random string in production. |
| `APPLE_AUDIENCE` | Must match the iOS bundle ID (`com.jacobhancock.HypeMusic`). Check uvicorn logs for `Token aud=...` if you get 401. |
| `DEV_AUTH_ENABLED=1` | Enables `POST /auth/dev` for simulator-only bypass (see `AuthManager`). Off in production. |
| `DATABASE_URL` | Postgres connection string if not using the default in `database.py`. |

### 3. iOS API base URL

The app reads `APIBaseURL` from `Info.plist` (see `APIConfig` in `Core/Networking/MusicData.swift`).

| Target | `APIBaseURL` |
|--------|----------------|
| **Simulator** | `http://127.0.0.1:8000` |
| **Physical device** | `http://<your-mac-wifi-ip>:8000` |

Find your Mac’s IP:

```bash
ipconfig getifaddr en0
```

Update `Info.plist`, then **clean build and run** from Xcode so the new URL is embedded.

`NSAllowsLocalNetworking` is already set for HTTP to LAN hosts. On device: **Settings → Privacy & Security → Local Network** — allow Hype if prompted.

### 4. Device networking checklist

- iPhone and Mac on the **same Wi‑Fi** (not cellular-only; guest networks often block device-to-device traffic).
- Confirm reachability in **Safari on the phone**: `http://<mac-ip>:8000/docs`
- Mac firewall: allow incoming connections for Python if prompted.

### 5. Sign in with Apple flow

1. User completes Apple sign-in on the device (identity token).
2. App `POST`s to `/auth/apple` with the token.
3. Backend verifies the token with Apple’s JWKS, then returns your app JWT + user.
4. `AuthManager` stores the token in Keychain and routes to onboarding or the main app.

Watch the **uvicorn terminal** while signing in — it shows whether the phone reached the server and what failed.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|----------------|-----|
| `curl: (7) Failed to connect` | Server not running or stopped with Ctrl+C | Start uvicorn in a dedicated tab; test from a **second** tab |
| iOS timeout to `http://…:8000/auth/apple` | Phone can’t reach Mac | Same Wi‑Fi, correct `APIBaseURL`, Safari test on phone |
| `ImportError: PyJWKClient` | Global Python / wrong `jwt` package | Use `backend/.venv`; `pip install -r requirements.txt` |
| `POST /auth/apple` **401** + `CERTIFICATE_VERIFY_FAILED` | Python SSL certs on macOS | Run **Install Certificates.command** for your Python |
| `POST /auth/apple` **401** + `Token aud=...` | `APPLE_AUDIENCE` mismatch | Set `APPLE_AUDIENCE` in `.env` to bundle ID |
| No log line on sign-in | Request never hit Mac | Network / `APIBaseURL` / rebuild app |
| `POST /auth/apple` **200** but app errors | Client decode or stale build | Check Xcode console; clean build |

## Project layout

```
HypeMusic/
├── App/              # Entry, RootView, ContentView
├── Core/
│   ├── Auth/         # AuthManager, Keychain
│   ├── Networking/   # APIConfig, API client (single networking surface)
│   └── Theme/
├── Features/         # Home, Feed, Profile, Onboarding, Search, …
└── Info.plist        # APIBaseURL, URL schemes (Spotify callback)
```

Backend: `../../backend/` — FastAPI, `auth.py` (Apple + app JWT), Postgres models.

## Design

- Primary accent: `#FFB300` (`Color(hexString:)` in `Core/Extensions/Color+Hex.swift`)
- Premium, minimal, vinyl-inspired UI
