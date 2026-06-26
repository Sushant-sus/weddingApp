# Wedding Manager — Flutter Mobile App Plan

A native-feeling iOS/Android app (Flutter) that consumes the **existing** Wedding Management
REST API (Node/Express + Prisma + Postgres stored procedures). No backend changes required —
the app is a pure client of the API already deployed on Render.

This document has two parts:

- **Part A — Design Brief** → paste this verbatim into a fresh Claude (design/artifact) chat to
  generate the visual design (screens, component mockups, color system).
- **Part B — Technical Build Plan** → the engineering plan we follow *here* to implement the app
  in Flutter once the design is approved.

---

# PART A — DESIGN BRIEF (paste into a new Claude design chat)

> **Prompt to paste:**
>
> Design a mobile app called **"Wedding Manager"** — a collaborative wedding-planning app. I want
> a complete visual design: a design system + high-fidelity mockups of every screen. Target
> **iOS-first** aesthetics (works on Android too).
>
> ## Visual language — "Liquid Glass" (iOS 26 style)
> - **Frosted / translucent glass surfaces** everywhere: cards, sheets, the nav bar and app bar
>   use a blurred, semi-transparent material that lets a soft gradient background bleed through.
> - **Floating bottom tab bar**: a rounded, pill-shaped, translucent glass bar that hovers above
>   the content (not flush to the edge). Icons are thin-line, semi-transparent; the active tab
>   gets a subtle liquid highlight / glow and a tint, not a hard solid fill.
> - **Soft, romantic gradient background** behind the glass — blush/rose → champagne/gold →
>   soft lavender. Light mode primary; also provide a dark mode (deep plum/charcoal gradient).
> - Generous rounded corners (20–28px), soft layered shadows, subtle inner highlights on glass
>   edges to sell the "wet glass" refraction look.
> - Typography: a warm elegant serif for titles (e.g. Playfair/Cormorant), clean sans for body
>   (e.g. Inter/SF). Tasteful, wedding-appropriate, not childish.
>
> ## Brand palette (suggested, refine freely)
> - Rose / blush `#E8B4B8`, Champagne gold `#D4AF7A`, Deep plum `#3A2A3F`, Sage `#A8B89E`,
>   off-white `#FBF7F4`. Glass tints derived from these at low opacity.
>
> ## Screens to design
> 1. **Splash / Auth gate** (logo on gradient glass).
> 2. **Login** — email + password, "forgot password" link, link to Register.
> 3. **Register** — full name, email, password, confirm password.
> 4. **OTP / Email verification** — 6-digit code entry, resend.
> 5. **Forgot password / Reset password**.
> 6. **Events list / Event switcher** — cards per wedding event showing name, date, venue,
>    member count, my-role badge, guest count. "Create event" FAB. Pending-invite cards with
>    Accept / Decline.
> 7. **Create / Edit event** sheet — name, wedding date (picker), venue, description.
> 8. **Dashboard (Home tab)** — for the selected event: hero card (couple/event name +
>    countdown to wedding date), quick stat tiles (Guests, Confirmed, Gifts total, Budget
>    used vs estimated), recent activity feed.
> 9. **Guests tab** — sticky summary bar (Families / Est. attendees / Confirmed), search field,
>    filter chips (Family type, RSVP, Side), scrollable **guest cards** (name, RSVP badge,
>    type/side chips, attendee counts, tap-to-call phone, remarks). Card actions: Gifts, Edit,
>    Delete. "Add guest" via a slide-up glass sheet form.
> 10. **Guest detail / Gifts sheet** — list of gifts for a guest (cash amount or in-kind
>     description, date, remarks), add-gift form, running totals.
> 11. **Itinerary tab** — vertical timeline of events, color-coded by category (Ceremony,
>     Reception, Ritual, Meal, Entertainment, Other), each with time, title, location,
>     responsible person. **Drag-to-reorder** handle. Add/Edit event sheet. (Provide the
>     category color chips.)
> 12. **Cost tracker tab** — budget summary (Grand estimated, Grand actual, Variance),
>     by-category breakdown, line items with vendor, estimated/actual, payment-status badge
>     (Unpaid/Partial/Paid). Add/Edit item sheet. *(This tab is visible only to Owner/Leader.)*
> 13. **Members / Sharing** — member list with role badges, invite-by-email sheet, change-role,
>     remove, transfer ownership, pending invites. Activity log view.
> 14. **Profile / Settings** — current user, switch event, sign out, dark-mode toggle.
> 15. **Empty states & loading skeletons** for each list, **error/toast** style, and the
>     **role-restricted** state (e.g. "Costs are visible to organizers only").
>
> ## Components to define in the design system
> - Glass card, glass bottom-nav, glass app bar, glass bottom-sheet/modal.
> - Buttons (primary gradient, glass-outline, destructive, ghost), inputs, dropdown/select,
>   date/time pickers, search field, filter chip, segmented control.
> - Badges: RSVP status (Confirmed=green, Pending=amber, Declined=red), payment status,
>   event-role badge, category chip.
> - Stat tile, summary bar, timeline item, list-card, FAB, snackbar/toast.
> - Avatar/initials chip for members.
>
> ## Deliverables
> - A color + typography + spacing token sheet.
> - Mockups for all screens above in **both light and dark**.
> - The reusable component sheet.
> - Note the exact blur radius, opacity, corner radius, and shadow values used for the glass so
>   they can be reproduced in Flutter (BackdropFilter / ImageFilter.blur).

*(End of paste-ready brief.)*

---

# PART B — TECHNICAL BUILD PLAN (Flutter implementation)

## 1. Stack & key packages
- **Flutter** (stable) + Dart, single codebase iOS + Android.
- **State management:** `flutter_riverpod` (providers for auth, selected event, queries).
- **Networking:** `dio` (interceptors for Bearer token + 401 refresh-retry, mirrors the web
  `client/src/lib/api.ts`).
- **Routing:** `go_router` (declarative, auth-guarded redirects).
- **Secure token storage:** `flutter_secure_storage` (access + refresh tokens).
- **Models / JSON:** `freezed` + `json_serializable` (immutable models matching API types).
- **Glass UI:** built-in `BackdropFilter` + `ImageFilter.blur` for glassmorphism; optionally
  `liquid_glass_renderer` for the iOS-26 refraction look on the nav bar.
- **Drag-reorder:** `ReorderableListView` (built-in) for the itinerary.
- **Dates:** `intl`. **Phone dial:** `url_launcher`. **Pull-to-refresh:** built-in
  `RefreshIndicator`.

## 2. Project structure (feature-first, mirrors the web client)
```
mobile/
  lib/
    main.dart
    app.dart                      # MaterialApp.router + theme
    core/
      api/
        api_client.dart           # Dio instance + envelope unwrap + interceptors
        api_exception.dart
        token_store.dart          # secure storage wrapper
      config/env.dart             # API base URL
      theme/                      # colors, typography, glass tokens (from design)
      widgets/                    # GlassCard, GlassScaffold, GlassBottomNav, GlassSheet,
                                  # StatTile, StatusBadge, etc.
    features/
      auth/        (login, register, verify, forgot/reset, AuthController, models)
      events/      (event list/switcher, create/edit, members, activity, EventController)
      dashboard/
      guests/      (list, cards, form sheet, gifts sheet, models, repository)
      gifts/
      itinerary/   (timeline, reorderable, form sheet)
      costs/
      profile/
    routing/app_router.dart
```

## 3. API layer (no backend change)
- **Base URL:** `https://<render-app>/api/v1` (from `core/config/env.dart`; allow a debug
  override for `http://10.0.2.2:4000/api/v1` on Android emulator / LAN IP on device).
- **Envelope:** every response is `{ "success": bool, "data": ... }` → `ApiClient` unwraps `data`;
  errors come as `{ error: { code, message, details } }` → throw `ApiException`.
- **Auth interceptor:** attach `Authorization: Bearer <accessToken>`. On `401`, attempt **one**
  refresh via `POST /auth/refresh-token { refreshToken }`, store the new access token, retry the
  original request; if refresh fails, clear tokens and route to Login. Skip refresh for
  `/auth/*` except `/auth/me` (exactly like the web client).

### Endpoint map the app consumes
**Auth**
- `POST /auth/register` `{fullName,email,password,confirmPassword}`
- `POST /auth/verify-email` `{email, code}`
- `POST /auth/login` `{email,password}` → `{accessToken, refreshToken, user}`
- `POST /auth/refresh-token` `{refreshToken}` → `{accessToken}`
- `POST /auth/logout`
- `GET  /auth/me`
- `POST /auth/forgot-password` `{email}` · `POST /auth/reset-password`

**Events**
- `GET /events` · `POST /events` `{name,weddingDate,venue,description}`
- `GET /events/:id` · `PATCH /events/:id` (Owner/Leader) · `DELETE /events/:id` (Owner)
- `POST /events/invite/accept` `{token}` · `POST /events/invite/decline` `{token}`
- `GET /events/:id/members` · `POST /events/:id/members/invite` `{email, eventRole}`
- `PATCH /events/:id/members/:userId/role` · `DELETE /events/:id/members/:userId`
- `POST /events/:id/transfer-ownership` · `GET /events/:id/activity`

**Event-scoped (prefix `/events/:eventId`)**
- Guests: `GET /guests/summary`, `GET /guests?familyType&rsvpStatus&side`, `POST /guests`,
  `PATCH /guests/batch`, `GET/PATCH/DELETE /guests/:id`
- Gifts: `GET /gifts/summary`, `GET /gifts`, `GET /guests/:guestId/gifts`,
  `POST /guests/:guestId/gifts`, `PATCH /gifts/:id`, `DELETE /gifts/:id`
- Itinerary: `GET /itinerary`, `POST /itinerary`, `PATCH /itinerary/reorder`,
  `PATCH /itinerary/:id`, `DELETE /itinerary/:id`
- Costs (Owner/Leader only): `GET /costs/summary`, `GET /costs`, `POST /costs`,
  `PATCH /costs/:id`, `DELETE /costs/:id`

## 4. Models (match API JSON, snake_case fields)
Mirror the web TS types: `Guest`, `GuestSummary`, `Gift`, `GiftSummary`, `CostItem`,
`CostSummary`, `ItineraryEvent`, `WeddingEvent`, `EventMember`, `ActivityEntry`, `AuthUser`.
Note money fields (`amount`, `estimated_cost`, …) arrive as **strings** — parse to `num` in the
model. Enums: `FamilyType`, `Side`, `RsvpStatus`, `GiftType`, `PaymentStatus`, `EventCategory`,
`EventRole`.

## 5. Permissions (event role gating — match the server)
Drive UI affordances off `event.my_role` (rank: OWNER 5 ▸ LEADER 4 ▸ EDITOR 3 ▸ CONTRIBUTOR 2 ▸
VIEWER 1):
- **View all tabs except Costs:** all roles.
- **Add guest/gift (contribute):** Contributor+.
- **Edit/delete guests, batch, itinerary CRUD:** Editor+.
- **Costs tab, members management, transfer/role changes, delete itinerary/gift:** Leader+ /
  Owner. Hide the **Costs** tab entirely for < Leader (server returns 403 anyway).
- **Delete event / transfer ownership:** Owner only.
Hide buttons the role can't use; still handle 403 gracefully as a fallback.

## 6. Navigation — the glass bottom bar
- 5 tabs: **Home (dashboard) · Guests · Itinerary · Costs · More(members/profile)**.
  Costs tab conditionally hidden for non-organizers.
- Implement with `go_router` `StatefulShellRoute.indexedStack` (per-tab navigation state).
- The bar itself: a floating, rounded, `ClipRRect` + `BackdropFilter(blur)` container with a
  low-opacity gradient fill and a hairline border; thin-line icons; active tab gets a tinted
  liquid pill + glow. Honor safe-area inset.

## 7. Screen ↔ feature build order (milestones)
1. **Scaffold + theme + glass component library** (GlassScaffold, GlassCard, GlassBottomNav,
   GlassSheet, StatusBadge, StatTile) from the approved design tokens.
2. **API client + token store + auth interceptor.**
3. **Auth flow:** login → register → OTP verify → forgot/reset; AuthController + secure storage;
   `go_router` redirect guard.
4. **Events:** list/switcher, create/edit, accept/decline invites; selected-event provider.
5. **Dashboard:** stats from guest/gift/cost summaries + activity feed + wedding countdown.
6. **Guests:** summary bar, search, filter chips, cards, add/edit sheet, delete confirm,
   tap-to-call; gifts sheet (list + add).
7. **Itinerary:** category-colored timeline, `ReorderableListView` → `PATCH /itinerary/reorder`,
   add/edit/delete.
8. **Costs:** summary + by-category + line items + add/edit, role-gated.
9. **Members & activity:** list, invite, role change, remove, transfer; activity log.
10. **Profile/settings:** current user, switch event, dark mode, sign out.
11. **Polish:** loading skeletons, empty states, pull-to-refresh, error toasts, offline message.

## 8. Cross-cutting
- **Theming:** light + dark from the design tokens; glass blur/opacity/radius constants central.
- **Error handling:** map `ApiException.code` to friendly snackbars (e.g. `RATE_LIMITED`,
  validation details).
- **Caching/refresh:** Riverpod `FutureProvider`/`AsyncNotifier` with `invalidate` after
  mutations; `RefreshIndicator` for manual refresh.
- **Config:** `--dart-define=API_BASE_URL=...` for dev/prod; never hardcode secrets (the app only
  holds user JWTs, no server secrets).

## 9. Out of scope (v1)
- Global admin panel (`/admin`) — web-only for now.
- Excel-style batch grid editing (desktop pattern) — mobile uses per-row edit sheets; the
  `PATCH /guests/batch` endpoint is still available if we add multi-select later.
- Push notifications, offline write/sync (future).

## 10. Next action
Once the design from Part A is approved, we run `flutter create mobile` inside this repo and
implement milestones 1→11 in order.

---

# PART C — UTSAV SERVICE MARKETPLACE (backend implemented)

The `design_handoff_utsav` package adds a **two-sided service marketplace** on top of the event
app: a **host** opens a *service request* against an itinerary item, *providers* submit *pitches*,
and the host books one. The backend for this is **already built and additive** — new tables, new
stored procedures, new routes; **no existing table or SP was modified** (the itinerary "service
pill" is derived via a join in `sp_itinerary_with_services`, leaving `itinerary_events` untouched).

## New database objects (migrations 010 + 011)
- Enums: `service_audience_enum (BROADCAST|TARGETED)`, `service_request_status_enum
  (LIVE|BOOKED|CANCELLED)`, `pitch_status_enum (NEW|SHORTLISTED|ACCEPTED|DECLINED)`.
- Tables: `service_categories` (seeded: Mehendi/Catering/Photography/Decor/Makeup/DJ-Dhol/Pandit/
  Mandap), `service_providers`, `provider_portfolio`, `provider_reviews`, `service_requests`,
  `service_request_targets`, `service_pitches`.
- SPs: `sp_category_list`, `sp_provider_list/get_by_id/get_by_user/upsert/portfolio_add/review_add/
  dashboard_feed`, `sp_service_request_create/get_by_id/list_for_event/cancel`,
  `sp_itinerary_with_services`, `sp_pitch_list_for_request/create/book/decline`, plus
  `sp_request_event_role` / `sp_pitch_event_role` authorization helpers.
- **To apply:** run `npm run db:migrate` (or paste 010 then 011 into the Supabase SQL editor).

## New API endpoints the app consumes
**Categories & providers (top-level, authenticated)**
- `GET /service-categories` — catalogue with provider counts.
- `GET /providers?category=<slug>&search=<text>` — browse/discovery.
- `GET /providers/:id` — profile incl. portfolio + reviews.
- `GET /providers/me` · `PUT /providers/me` `{name,bio,categories[],basePrice,city,distanceKm}`
  — the caller's own provider profile (upsert).
- `GET /providers/me/dashboard` — matched LIVE requests for the caller's provider profile.
- `POST /providers/:id/portfolio` `{imageUrl,caption,sortOrder}` ·
  `POST /providers/:id/reviews` `{rating,body}`.

**Service requests — host side (event-scoped, `/events/:eventId`)**
- `GET /itinerary-services` — itinerary items each with their active service request (pill).
- `GET /service-requests` — all requests for the event (with pitch counts).
- `POST /service-requests` `{category,title,itineraryItemId?,budgetMin?,budgetMax?,audience,
  targetProviderIds?}` — requires Contributor+.

**Request- & pitch-scoped (top-level, authorized via the resource's event membership)**
- `GET /service-requests/:id` — detail (member). `POST /service-requests/:id/cancel` — Editor+.
- `GET /service-requests/:id/pitches` — ranked best-match first (member).
- `POST /service-requests/:id/pitches` `{price,message,availableOnDate}` — **provider action**
  (provider derived from the caller; `NOT_PROVIDER` if no profile; `ALREADY_PITCHED` /
  `REQUEST_NOT_LIVE` guards).
- `POST /pitches/:id/book` — Editor+; accepts this pitch, declines siblings, flips request to
  BOOKED. `POST /pitches/:id/decline` — Editor+.

## App impact (adds to the screen list / nav)
- **Mode switch (Host ⇄ Provider):** a client-side toggle (no DB field) that swaps the tab set.
  Provider mode is available once `GET /providers/me` returns a profile (else prompt to create one).
- **Host tabs:** Home · Itinerary (now shows service pills + "open request") · Market (browse
  providers) · Costs · Profile.
- **Provider tabs:** Dashboard (matched feed) · Requests · Pitches · Earnings · Profile.
- **New screens** to add to Part A's set: Create Service Request sheet, Request Detail / Pitches
  (many + empty states), Browse Providers, Provider Profile, Provider Dashboard, Submit Pitch sheet
  — all already specified in `design_handoff_utsav/README.md` with exact tokens (category accents,
  glass spec, Libre Caslon + Plus Jakarta Sans, ₹ Indian money formatting).
- **Money:** all amounts come back as strings → parse to `num`; render with `₹` + Indian grouping,
  symbol lighter/smaller than digits; budgets as ranges `₹10,000–15,000`.
