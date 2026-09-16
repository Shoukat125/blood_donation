# Blood Donation App — Complete & Finalize (Antigravity Build Prompt)

## Project Context
This is an existing Flutter (mobile, Android-first) + Python FastAPI backend project called
**Blood Donation App**. Most of the core functionality is already built and working. Your job
is to **complete the missing pieces, clean up the code architecture, and make it Play
Store-ready** — not rebuild from scratch.

Read the existing codebase fully before writing anything. Do not duplicate existing working
features (Login, Register, Dashboard, Donor Search, Request Blood, Confirmation, My Profile,
Donor Notifications — these already work end-to-end against the FastAPI backend).

---

## 1. Non-Negotiable Code Architecture Rules

- **Never put everything in one file.** Each screen, widget, model, and service must live in
  its own file, organized like this:
  ```
  lib/
    main.dart              -> app entry point ONLY (MaterialApp setup, theme, initial route)
    routes.dart            -> a single source of truth mapping route names -> screen widgets
    models/                -> plain Dart data classes (User, DonationRequest, Donor, etc.)
    services/               -> api_service.dart, auth_service.dart, storage_service.dart etc.
    screens/
      auth/                -> login_screen.dart, register_screen.dart, forgot_password_screen.dart
      onboarding/          -> onboarding_screen.dart
      dashboard/           -> dashboard_screen.dart
      donors/              -> donor_search_screen.dart, donor_profile_screen.dart
      requests/            -> request_blood_screen.dart, confirmation_screen.dart
      profile/             -> my_profile_screen.dart, edit_profile_screen.dart, settings_screen.dart
      notifications/       -> donor_notifications_screen.dart
    widgets/                -> small reusable pieces used across screens (buttons, cards, empty-state widget, loading spinner)
    theme/                  -> app_colors.dart, text_styles.dart
  ```
- **All navigation must go through `routes.dart`** using named routes
  (`Navigator.pushNamed(context, AppRoutes.dashboard)`), not raw `MaterialPageRoute` scattered
  across screens. `main.dart` should only reference `routes.dart`, never import individual
  screens directly except for the initial/home route.
- Extract repeated UI (empty-state message widget, loading button, section header, blood-type
  chip) into `widgets/` so screens stay short and readable — a screen file should ideally stay
  under ~250 lines; if it's longer, split it into smaller widgets.
- Delete dead code: `donor_registration_screen.dart` is currently unused (Register screen
  already collects blood type). Remove it, or if you intend a real "complete your donor
  profile after signup" step, wire it into the actual signup flow with a named route and
  explain why it's separate from Register.

---

## 2. Features To Complete (Currently Missing)

### 2.1 Onboarding (3 slides) — HIGHEST PRIORITY, currently 0% built
- Shown only on first-ever app open (persist a flag in SharedPreferences, e.g. `onboarding_seen`).
- 3 slides with swipe/PageView:
  1. "Khoon Do, Zindagi Bachao" — app's purpose
  2. "Apne Shehar Mein Donor Dhundo" — search feature
  3. "Emergency? Ek Click Mein Request Karo" — request feature
- Skip button (top-right) and "Shuru Karein" button on the last slide, both leading to
  Login/Register.
- On every subsequent app open, skip onboarding entirely and go straight to the auth-gate logic
  (already implemented in `auth_gate.dart`).

### 2.2 Forgot Password — currently missing entirely
- Add `forgot_password_screen.dart`: email input -> calls a new backend endpoint
  `POST /api/auth/forgot-password` -> sends a reset link/token (or, for a lightweight v1,
  a simple "reset code" flow: email -> 6-digit code -> new password screen).
- Add the corresponding backend route in `routers/auth.py` plus any schema needed in
  `schemas.py`. Keep it simple: for v1, email delivery can be logged to console/dev email
  service; note clearly in code comments where a real email provider (e.g. SendGrid) should be
  plugged in later.
- Add a "Forgot Password?" text button on the Login screen that navigates to this new screen.

### 2.3 Empty States & Polish (mostly done — verify, don't rebuild)
Empty states already exist for the urgent-requests list and donor search results. Just verify
every list-type screen (donation history, notifications list) also has a friendly empty-state
message instead of a blank screen.

---

## 3. Explicit "Do NOT Build" List
- Do not add a large standalone Settings page with many sub-pages — keep it to simple toggles
  on one screen (already mostly correct — verify `settings_screen.dart` stays lightweight).
- Do not add a generic "Notifications" page unrelated to real backend data — the existing
  `donor_notifications_screen.dart` (backend-connected donor-match accept/decline) is fine and
  should stay; do not add a second, decorative notifications page.
- Do not re-introduce a separate "Donor Registration" screen unless it's genuinely wired into a
  real flow (see 1, dead code note).
- Do not add features not listed here (Google Maps, SMS/Twilio) unless explicitly asked in a
  later phase — they are intentionally out of scope for this pass to keep the app lightweight.

---

## 4. Backend Requirements
- Backend (`backend/`) is a working FastAPI app (`main.py`, `routers/auth.py`,
  `routers/donors.py`, `routers/requests.py`, `routers/messages.py`, `routers/hospitals.py`).
  Add the new `forgot-password` route(s) here following the same patterns already used
  (JWT auth via `python-jose`, password hashing via `passlib`/`bcrypt`).
- `SECRET_KEY` must never ship with a weak default in production. Confirm the existing
  `main.py` startup warning (already present) still fires if `SECRET_KEY` env var is unset.
- CORS is currently `allow_origins=["*"]` — acceptable for early testing, but note in a code
  comment that this should be restricted to the real deployed frontend origin(s) before public
  launch.
- Do not hardcode the backend URL. `api_service.dart` already supports
  `--dart-define=API_BASE_URL=https://your-backend-url` — preserve this pattern; never revert
  to a hardcoded local IP.

### 4.1 Database: local PostgreSQL (`blood_db`), not SQLite
- The project has been switched from SQLite to a local **PostgreSQL** database created in
  pgAdmin 4, named **`blood_db`** (server: `localhost`, port `5432`, user `postgres`).
- `backend/database.py` now reads `DATABASE_URL` from the environment (via `python-dotenv`),
  falling back to `postgresql://postgres:Admin@123@localhost:5432/blood_db` if unset. Keep this
  pattern — never hardcode a different DB URL directly into `database.py`.
- `backend/.env` already contains the correct `DATABASE_URL` for local development. Do not
  commit real production database credentials into `.env` — `.env.example` documents the
  production pattern (env var set on Render/Railway dashboard).
- `requirements.txt` uses `psycopg2-binary` (PostgreSQL driver) instead of `pymysql` — do not
  reintroduce MySQL-specific packages or syntax anywhere in the backend.
- SQLAlchemy models (`models.py`) are already portable ANSI-SQL-style column types
  (`String`, `Integer`, `Boolean`, `DateTime`, `Float`, `Text`) and need no changes for
  Postgres — `models.Base.metadata.create_all(bind=engine)` in `main.py` will create all
  tables inside `blood_db` automatically on first run. Do not write manual `CREATE TABLE`
  SQL for this.
- Keep the SQLAlchemy connection pool small (`pool_size=3`, `max_overflow=2`, already set in
  `database.py`) — this matters on the 4GB RAM dev machine described in Section 7; a large
  pool holds open Postgres connections that each consume memory on both the Python process
  and the Postgres server.

---

## 5. Play Store Readiness Checklist (apply once features above are complete)
- [ ] Confirm `applicationId` / `namespace` in `android/app/build.gradle` is a real, final
      package id (e.g. `com.yourcompany.blooddonation`) — this cannot change after first
      publish.
- [ ] Set a real app icon (all mipmap densities) and app label (`android:label` in
      `AndroidManifest.xml`).
- [ ] Set `minSdk` appropriately (24+ recommended) and `compileSdk`/`targetSdk` to a current
      supported version.
- [ ] Generate a release keystore, wire it via `key.properties` + `signingConfigs.release` in
      `build.gradle` (never use the debug key for the release build type).
- [ ] Remove `linux/`, `macos/`, `windows/`, and `web/` platform folders if this app is
      Android-only, to keep the repository lightweight (these do not affect APK size either
      way, but keep the project clean).
- [ ] Write/confirm a Privacy Policy (the app uses location-free personal data: name, email,
      phone, blood type, donation history — mention this explicitly) and host it at a public
      URL for the Play Console listing.
- [ ] Build with `flutter build appbundle --release --dart-define=API_BASE_URL=<deployed backend URL>`.
- [ ] Confirm the backend is deployed to a public host (Railway/Render) with HTTPS before
      building the final release — an app pointed at a local IP will not work for real users.

---

## 7. Low-RAM Development Machine Constraints (4GB RAM laptop)
This project is being built and tested on a laptop with only 4GB RAM, which caused build
hangs on a previous Flutter project. Apply these constraints so the same problem doesn't
happen here. This now also covers running PostgreSQL locally alongside the build tools:

- **PostgreSQL server itself is fine on 4GB RAM** for local dev (it idles at a small memory
  footprint), but avoid running heavy extras at the same time as a `flutter build`:
  - Do not run **Stack Builder** installs, `pgAdmin`'s Query Tool with large result sets, or
    other database GUI tools simultaneously with a Gradle/Flutter build — close pgAdmin (or
    at least its dashboard/query tabs) while building the APK.
  - Keep the SQLAlchemy connection pool small (`pool_size=3, max_overflow=2` — already set in
    `database.py`); do not increase it without a real reason.
  - Run the FastAPI backend (`uvicorn`) and the Flutter build in separate terminals only when
    needed — stop `uvicorn` (Ctrl+C) if you're not actively testing API calls while a build is
    running, to free RAM for Gradle.
- **Keep `android/gradle.properties` memory-light** from the start:
  ```
  org.gradle.jvmargs=-Xmx1024M -XX:MaxMetaspaceSize=384m
  org.gradle.daemon=false
  org.gradle.parallel=false
  android.useAndroidX=true
  android.enableJetifier=true
  ```
- **Avoid adding heavy Flutter packages** unless truly necessary. Every extra native/plugin
  dependency (especially ones with native Android/iOS code) increases Gradle build time and
  memory pressure. Before adding a new package, check if the same result is achievable with
  what's already in `pubspec.yaml` (http, shared_preferences, provider, etc.).
- **Do not enable code minification/shrinking (`minifyEnabled true`, R8/ProGuard) during
  active development** — only turn it on for the final Play Store release build, since it
  significantly increases build time and memory use.
- When testing locally, prefer building for a single architecture to save time and memory:
  ```
  flutter build apk --release --target-platform android-arm64
  ```
  instead of the default multi-architecture build, unless a universal APK is specifically
  needed.
- Keep the number of installed Flutter/Dart analyzer plugins and running background apps
  (browser tabs, Android Studio's own indexing) minimal while running any `flutter build` or
  `flutter run` command.
- If a build hangs for more than ~15-20 minutes with no progress in the terminal, it's safer
  to cancel, close other applications, and retry rather than waiting indefinitely.

---

## 8. What "Done" Looks Like For This Pass
1. Onboarding flow built and gated correctly (first-run only).
2. Forgot Password flow built end-to-end (UI + backend route).
3. Dead/unused files removed, all navigation routed through `routes.dart`.
4. No single file holds more than one screen's worth of logic; shared UI extracted into
   `widgets/`.
5. Backend still runs unchanged for all previously-working features (do not break existing
   Login/Register/Dashboard/Search/Request/Confirmation/Profile/Notifications flows).
6. Gradle/build settings stay memory-light as specified in section 7.
7. A short summary of every file added/changed/removed, so it can be reviewed before merging.
