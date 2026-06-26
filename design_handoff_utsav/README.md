# Handoff: Utsav — Liquid Glass Event Planner + Service Marketplace

## Overview
Utsav is a two-sided mobile app for planning multi-ceremony events (built around an Indian
wedding) with a built-in service marketplace. A **host** builds a ceremony itinerary, opens any
itinerary item as a **service request**, and compares incoming **price pitches** from providers.
The same account can flip to **provider** mode to see matched requests and submit pitches. The
visual language is iOS-26 "Liquid Glass": frosted, translucent surfaces over soft colour
gradients, with light and dark themes.

The **core loop** this package documents:
`Itinerary → Open service request → providers pitch → Host compares & books`
plus the provider side: `Dashboard feed → Submit pitch`.

## About the Design Files
The files in this bundle are **design references created in HTML** — prototypes showing the
intended look and behaviour, **not production code to copy directly**. They are authored in a
small HTML component framework ("Design Components") that is specific to the design tool, so do
**not** try to reuse the markup or the `.dc.html` runtime.

Your task is to **recreate these designs in the target codebase's environment** using its
established patterns and libraries. This is a native-feeling mobile app — the natural targets are
**SwiftUI** (iOS), **Jetpack Compose** (Android), **React Native / Expo**, or **Flutter** (the
original brief targets Flutter, and a `BackdropFilter` spec table is included below for that path).
If no codebase exists yet, pick the most appropriate of these for the project and implement there.

`backdrop-filter` blur is the heart of the aesthetic — make sure your chosen stack can render
real-time background blur (SwiftUI `.ultraThinMaterial`, Compose `Modifier.blur`/`RenderEffect`,
Flutter `BackdropFilter`, RN `@react-native-community/blur` or Expo `BlurView`).

## Fidelity
**High-fidelity (hifi).** Final colours, typography, spacing, radii, and shadows are all
specified. Recreate the UI pixel-faithfully using the codebase's native materials. The exact glass
recipe (blur sigma + overlay fill + inner stroke) is tabulated under **Design Tokens → Glass spec**.

## Device frame
All screens are designed at **iPhone logical size 390 × 844 pt** with a Dynamic-Island status bar
(time `9:41` left; cellular/wifi/battery right). Content uses ~20px horizontal padding. A floating
glass tab bar sits ~13px above the bottom safe area. Corner radius of the screen content is 46px
inside an 11px bezel.

---

## Screens / Views

### 1. Itinerary (Host home)
- **Purpose:** Host sees the wedding's ceremony timeline and which items still need a service.
- **Layout:** Vertical scroll. Header row (event name + stacked guest avatars), then a 2-up row of
  glass stat tiles ("25 days to wedding", "1 open service request"), then section header
  "Itinerary · 6 events", then a vertical timeline list.
- **Timeline item:** left rail (42px) with the date label, a 13px category-colour dot ringed by a
  translucent halo, and a connector line; right side is a glass card containing a category chip,
  serif event title, venue line, and — if applicable — a **service status pill**:
  - *Open* (gathering pitches): rose-gold accent `#C9A28A`, e.g. "Needs Mehendi Artist · 4 pitches".
  - *Booked*: green accent `#6FBF8E`, e.g. "Booked · BeatWala DJ & Dhol".
- **Sample data (6 ceremonies):** Engagement (Jun 28, Taj Lands End) · Haldi (Jul 16, Residence
  Lawn) · Mehendi (Jul 17, Garden Terrace — **open, 4 pitches**) · Sangeet (Jul 17, Grand Ballroom —
  booked DJ) · Wedding (Jul 18, Seaside Mandap — booked pandit) · Reception (Jul 19, Sky Lounge).
- **Bottom nav:** Host tabs — Home · **Itinerary** (active) · Market · Costs · Profile.

### 2. Create Service Request (sheet)
- **Purpose:** Host opens a request from the Mehendi item.
- **Layout:** A glass sheet rising over a dimmed/blurred background; rounded top corners (34px),
  grabber handle. Sections top→bottom: context chip ("Mehendi · Jul 17"), serif title "Open a
  service request", **Category** chips (Mehendi selected, + Catering/Decor/Makeup), **Budget range**
  (two glass fields MIN ₹10,000 / MAX ₹15,000), **Who sees this** segmented control
  (**Broadcast** "42 nearby artists" selected vs Targeted "pick providers"), and a pinned primary
  button "Post to 42 artists".

### 3. Request Detail — Pitches (two states)
- **Purpose:** Host compares incoming pitches and books one.
- **Many state:** back chevron + serif "Mehendi Artist" title + "Open · 4" pill; a budget/sort bar
  ("Budget ₹10,000–15,000" · "Sort · Best match"); then a list of pitch cards. Each card: provider
  avatar (initials), name, `★ rating · N reviews · distance`, a large right-aligned **price**
  (`₹12,500` with the `₹` deemphasised), one line of pitch message, and two actions
  **Decline** (secondary) + **Book this artist** (primary). The best match carries a floating
  "★ RECOMMENDED" tab and sits first.
  - Pitches: Henna by Simran ₹12,500 (4.9, recommended) · The Mehendi Co. ₹11,200 (4.6) ·
    Aabroo Studio ₹9,800 (4.7) · Roshni Arts ₹15,000 (5.0).
- **Empty state:** centred floating glass circle with a clock icon (gentle 4s float animation),
  serif "No pitches yet", body "Your request is live to **42 Mehendi artists** nearby. Pitches
  usually arrive within a few hours.", and a glass "Invite specific artists" button.
- **Behaviour:** Booking a pitch auto-declines the rest (state note below).

### 4. Browse Providers (Marketplace)
- **Purpose:** Discovery by category.
- **Layout:** serif "Find a service", a glass search field ("Search vendors near Mumbai"), a 2-column
  **category grid** (each tile: colour swatch, name, "N nearby"), then "Top rated near you" list of
  vendor rows (striped colour thumbnail, name, `★ rating · distance`, category label, base price).
  - Categories: Mehendi 42 · Catering 88 · Photography 120 · Decor 65 · Makeup 73 · DJ/Dhol 31 ·
    Pandit 19 · Mandap 24.

### 5. Provider Profile
- **Purpose:** Vendor detail + entry into the quote flow.
- **Layout:** back/share glass icon buttons in the bar; header (66px rounded avatar "HS", serif name
  "Henna by Simran" + verified badge, `★ 4.9 · 128 reviews · 3.2 km`); tags (Mehendi · "Bridal henna ·
  from ₹8,000"); **Portfolio** 2-column gallery (4 placeholder tiles); **Reviews** list. A persistent
  glass action bar pins **♥** + **Request a quote** (primary) to the bottom.

### 6. Provider Dashboard
- **Purpose:** Provider's home; matched incoming requests.
- **Layout:** greeting ("Good morning / Simran") with a **Host ⇄ Provider** glass segmented switch
  (Provider active); a stat row ("This month ₹84,200", "Pending 3 pitches"); section "Incoming
  requests" + "2 matched"; a feed of request cards (category chip, posted-time, serif event name,
  `date · budget · distance`, **Details** + **Send a pitch** actions).
  - Feed: Aanya & Veer Wedding (Mehendi, Jul 17, ₹10–15k, matched) · Nexa Diwali Gala (Mehendi,
    Aug 02, ₹6–9k, matched) · Diya 25th Birthday (Mehendi, Jul 30, ₹3–5k).
- **Bottom nav:** Provider tabs — **Dashboard** (active) · Requests · Pitches · Earnings · Profile.

### 7. Submit a Pitch (sheet)
- **Purpose:** Provider responds to a request.
- **Layout:** rising glass sheet; serif "Your pitch"; a context card (A&V Wedding · Mehendi · Jul 17 ·
  budget); **Your price** — a large money field (`₹ 12,500`, rose-gold inner stroke) with a "within
  budget" hint; **Message** textarea; an "Available on Jul 17" row with a green toggle (on); pinned
  primary "Send pitch · ₹12,500".

### 8. Component Sheet (design system reference — not an app screen)
Light and dark panels showing every surface (glass card, buttons, badges/chips, stat tile, mode
switch, money field, nav pill) plus the **Flutter glass spec table** reproduced under Design Tokens.

---

## Interactions & Behavior
- **Bottom tab bar:** liquid glass pill; the active tab has a radial rose-gold highlight that
  **morphs (x + width) between tabs** with a spring. Flutter: `SpringDescription(mass: 1,
  stiffness: 320, damping: 30)`. Native: matchedGeometry / shared-element style animation.
- **Sheets** (Create request, Submit pitch) rise from the bottom over a dimmed + blurred backdrop;
  rounded top corners, grabber handle, swipe-to-dismiss.
- **Empty-state icon** floats vertically ±7px on a 4s ease-in-out loop.
- **Book a pitch:** confirm → selected pitch becomes *Accepted*, all sibling pitches become
  *Declined*, the itinerary item's service pill flips from open (rose-gold) to booked (green).
- **Broadcast vs Targeted:** Broadcast posts to all matching providers in range; Targeted lets the
  host pick specific providers before posting. The CTA label reflects the count ("Post to 42 artists").
- **Mode switch (Host ⇄ Provider):** toggles the entire tab set and home surface for the same account.
- **Money formatting:** Indian grouping with `₹` prefix (e.g. `₹12,500`, `₹84,200`); the symbol is
  rendered lighter/smaller than the digits. Budgets show as ranges `₹10,000–15,000`.

## State Management
- `userMode`: `host | provider` (drives nav + home).
- `theme`: `light | dark`.
- `event`: name, date, guest list, list of `itineraryItems`.
- `itineraryItem`: `{ id, category, title, venue, date, service? }`.
- `serviceRequest`: `{ id, itemId, category, budgetMin, budgetMax, audience: broadcast|targeted,
  targetedProviderIds[], status: live|booked, pitches[] }`.
- `pitch`: `{ id, requestId, providerId, price, message, availableOnDate: bool,
  status: new|shortlisted|accepted|declined }`. Booking sets one `accepted`, others `declined`.
- `provider`: `{ id, name, categories[], basePrice, rating, reviewCount, distanceKm, portfolio[],
  reviews[] }`.
- Provider dashboard derives its **matched** feed from requests whose category ∈ provider.categories
  and within service radius.

## Design Tokens

### Colour — category accents (used app-wide for dots, chips, thumbnails)
| Category | Hex |
|---|---|
| Engagement | `#D98A94` |
| Haldi | `#E0A458` |
| Mehendi | `#6FBF8E` |
| Sangeet | `#A88BD9` |
| Wedding | `#C9A28A` |
| Reception | `#7FA8D9` |

### Colour — brand & accent per event type
- Primary accent (wedding rose-gold): `#C9A28A`; button gradient `#D8B49C → #BC8868`, label `#2C1A10`.
- Corporate `#7FA8D9` · Birthday `#D98A94` (swap the primary accent by event type).

### Status colours
Open/needs-service & primary `#C9A28A` (light text `#9A6238`/`#8A5A33`, dark `#F2CFB6`) ·
Accepted/booked `#6FBF8E` (light `#3E7E58`, dark `#9EE0BC`) · Pending `#E0A458` ·
Declined `#D9737A` · star rating `#E0A458`.

### Background gradients (behind the glass), 162°
- Light: `#F9DDE3 → #F5E8DB → #E3D8F2`
- Dark: `#2E1B38 → #3A1C33 → #241B40`

### Text colours
- Light: heading `#241B2C` / `#2B2630`; body 60% of `#2B2630`; on-glass secondary ~55%.
- Dark: heading `#FBEFE6` / `#F6F1EC`; body ~62% of `#F6F1EC`.

### Typography
- **Display / titles:** *Libre Caslon Display* (serif), weight 400 — event names, screen titles,
  big numbers. Sizes seen: 84 (cover), 30/27 (page H1), 22–26 (card/sheet titles), 18–19 (section).
- **Italic accents:** *Libre Caslon Text Italic*.
- **UI / body / numerals:** *Plus Jakarta Sans* (weights 400–800). Prices use weight 800 +
  `font-variant-numeric: tabular-nums`. Labels/eyebrows: 10–11px, weight 700, letter-spacing ~0.5px,
  uppercase. Min body 12px, base 13–14px.

### Spacing / radius / shadow
- Padding: screen 20px; cards 12–16px; sheets 22px.
- Radius: screen content 46; cards 18; large cards/sheets 20–24; sheet top 34; chips 9–14;
  buttons 12–18; nav pill 34; avatars 11–20.
- Card shadow (light): `0 8px 24px rgba(60,40,70,0.10–0.12)`; (dark): `0 8px 24px rgba(0,0,0,0.30–0.35)`.
- Primary button shadow: `0 10px 26px rgba(176,128,98,0.45)` (light) / `rgba(0,0,0,0.4)` (dark).

### Glass spec (BackdropFilter) — σ = blur sigma, fill = white overlay opacity
| Surface | Blur σ | Fill light / dark | Inner stroke | Radius | Shadow |
|---|---|---|---|---|---|
| Glass card | 20 | white 55% / 10% | white 65% / 16% · 1px | 18–24 | y8 blur24 black 12% |
| Bottom nav pill | 30 | white 36% / 10% | white 60% / 20% · 1px | 34 (pill) | y12 blur32 black 18–42% |
| Active-tab highlight | 12 | accent `#C9A28A` 22–62% radial | — | pill | glow 20px accent 50% |
| Sheet / modal | 28 | white 72% / 60% | white 50% / 16% · 1px | 34 (top) | y-10 blur40 black 16–40% |
| Chip / badge | 14 | white 50% / 8% (+ category tint) | white 60% / 16% · 1px | 10–14 | none |

All glass surfaces also get an **inner top highlight** `inset 0 1px 1px rgba(255,255,255,0.85–0.9)`
(light) for the wet-glass sheen, and use `saturate(1.5–1.7)` alongside the blur.

## Assets
- **Fonts:** Libre Caslon Display, Libre Caslon Text, Plus Jakarta Sans — all Google Fonts (swap to
  system serif + SF/Roboto if you prefer native). No licensed fonts required.
- **Icons:** simple line icons (home, calendar, grid, wallet, person, search, chevron, heart, share,
  plus, clock, paper-plane) drawn as inline SVG strokes — replace with your icon set (SF Symbols,
  Material Symbols, lucide).
- **Imagery:** portfolio/vendor thumbnails are **striped placeholders** — wire to real uploaded
  photos. No raster assets are shipped in this bundle.

## Files
Design reference files included in this folder (open in a browser to view; **do not** ship as-is):
- `Utsav - Liquid Glass.dc.html` — all 8 sections (cover, 7 screens, component sheet), light + dark.
- `GlassNav.dc.html` — the liquid-glass bottom tab bar component reference.

> The `.dc.html` files depend on a proprietary runtime and won't render outside the design tool's
> preview, but you can read them as structured markup references. The README above is intended to be
> **self-sufficient** — implement from it directly.
