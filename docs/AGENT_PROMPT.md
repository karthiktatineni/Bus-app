# ROLE

You are a senior Flutter engineer and product designer. Build the FRONTEND ONLY of a
fleet maintenance mobile app for a bus operator. Follow every rule in this document
exactly. If a rule conflicts with your habits, the rule wins.

Read `ARCHITECTURE.md` first. It defines the folder structure, layering, and
dependencies. Do not deviate from it.

# SCOPE

IN scope:
- Flutter app (Android + iOS, one codebase), Material 3, light and dark theme.
- All screens listed below, fully navigable, running on realistic MOCK DATA.
- Repository interfaces with in-memory mock implementations, so a real backend can be
  swapped in later without touching UI code.

OUT of scope (do NOT build, do NOT add packages for):
- Real backend, real auth, real database, real file upload, real OCR.
- Push notifications (build the settings UI only).
- Web or desktop targets.

The OCR feature is a UI flow only: the user picks a bill image, a short fake "Scanning..."
state runs, and fields are pre-filled from mock data. It sits behind an `OcrService`
interface.

# PRODUCT CONTEXT

- Client: bus operator with roughly 10 buses (must scale to 100+ without redesign).
- Currency: INR (₹). Distance: km. Dates: dd MMM yyyy. Use Indian-style number grouping
  for money (e.g. ₹1,24,500).
- Registration numbers look like `TS 09 UB 4521`. Use realistic Indian bus fleet data.
- Roles: `admin` and `staff`. Admin can do everything. Staff can view vehicles, add
  service records and upload photos, but cannot add users, delete vehicles, or edit
  company settings.

# SCREENS (build exactly these)

## 1. Login
- Product name + simple logo mark at top (placeholder wordmark, no stock illustration).
- Email field, password field with show/hide toggle, "Sign in" button, "Forgot password?"
  text button (opens a simple screen with an email field and a confirmation state).
- Inline validation errors under fields. Loading state on the button while "signing in".
- Mock credentials: `admin@demo.com / demo1234` (admin), `staff@demo.com / demo1234`
  (staff). Wrong credentials show an inline error banner, not a dialog.
- Keyboard must not overflow the layout. Support small phones (360x640).

## 2. Home (Dashboard)
App bar: hamburger icon (opens drawer), screen title, notification bell with unread dot.

Body, top to bottom, in one scrollable page:
1. **Greeting line + date** (small, secondary text).
2. **Summary row**: three compact stat tiles: Overdue, Due in 14 days, Buses in workshop.
3. **To-do list** (section header "To do" with a count and a "View all" link):
   - Checklist of maintenance tasks due within 14 days, sorted by due date.
   - Each row: checkbox, task title (e.g. "Oil and filter change"), bus registration,
     due date label ("Tomorrow", "In 5 days", "Overdue by 3 days" in danger color).
   - Tapping the checkbox marks it done with a short strike-through animation and an
     Undo snackbar. Tapping the row opens the bus detail.
4. **"Next 2 weeks" flashcards**: a HORIZONTAL scrolling list, one card per bus that has
   work due in the next 14 days. Card width about 78% of screen with the next card
   peeking. Snap scrolling. Each card shows: registration, model, a status chip
   (Overdue / Due soon / On track), 2 to 3 upcoming tasks with due dates, odometer, and
   a "View bus" action. Buses with nothing due do not get a card.
5. **All vehicles** (section header with count): search field + filter chips (All, Due
   soon, Overdue, In workshop, Active). Vertical list of vehicle tiles: thumbnail,
   registration, model/year, last service date, next service date, status chip.
   Tapping opens Vehicle Detail.
- Pull-to-refresh (mock delay). Empty and loading (skeleton) states for every list.
- Admin only: extended FAB or app-bar action "Add vehicle".

## 3. Navigation Drawer (hamburger)
- Header: user avatar (initials), name, role badge, company name.
- Items, in order: Dashboard, Vehicles, Add vehicle, Service history, Bills, Reminders,
  Users (admin only), Settings, Help and support, Log out (bottom, separated by a divider).
- Active item is visibly highlighted. Closing and routing must feel instant.
- Hide admin-only items for staff; do not show disabled ones.

## 4. Vehicles list
Same list component as Home but full screen, with sort (registration, next service date,
odometer) and filters.

## 5. Vehicle Detail
Header: hero image, registration, model/year, status chip, odometer, edit action (admin).
Tabs:
- **Overview**: key specs (make, model, year, chassis no., engine no., seating, fuel,
  purchase date), assigned depot, current odometer, next service due card.
- **Service history**: reverse-chronological timeline. Each entry: date, service type,
  odometer, workshop, total cost, number of parts replaced, photo count. Tap opens
  Service Detail.
- **Upcoming**: scheduled maintenance items with due date and/or due km, and a
  "Mark as done" action.
- **Documents**: insurance, fitness certificate, permit, pollution certificate, each with
  expiry date and status chip.
- **Photos**: grid grouped by service, with full-screen pinch-zoom viewer.

## 6. Add / Edit Vehicle (multi-section form, not a wizard)
Fields: registration no., make, model, year, chassis no., engine no., seating capacity,
fuel type, odometer, depot, purchase date, up to 5 photos (camera or gallery via the shared photo source sheet),
documents with expiry dates. Sticky "Save" bar. Validation on submit. Unsaved-changes
confirmation on back.

## 7. Service Detail
Service type, date, odometer, workshop, mechanic, notes, itemized parts list (name,
qty, cost), labour cost, tax, total. Photo sections: **Before**, **After**, **Parts
replaced** (with caption per photo), and **Bill** (image + extracted fields). Edit and
delete are admin only.

## 8. Add Service Record (stepper, 4 steps)
1. Details (type, date, odometer, workshop, notes)
2. Parts and costs (add/remove rows, running total)
3. Photos (before, after, parts replaced; camera or gallery)
4. Bill: "Scan bill" opens the camera capture flow (see CAMERA AND PHOTO CAPTURE), then a mock OCR flow pre-fills vendor,
   bill number, bill date, line items, tax, and total. Every pre-filled field is
   editable, and low-confidence fields (mock a couple) are highlighted with a "Check
   this" hint. Then a Review screen and Save.

## 9. Service history and Bills (global)
Service history: all services across buses with filters (bus, date range, type). Bills:
list of bills with vendor, date, amount, and linked bus; tap opens bill image.

## 10. Reminders
List of upcoming reminders grouped by Overdue, This week, Next week, Later.

## 11. Users (admin only)
- List of users: avatar, name, email, role badge, status (Active / Invited / Disabled).
- "Add user" bottom sheet or screen: name, email, phone, role, send invite (mock).
- User detail: change role, disable/enable, remove (with confirmation).

## 12. Settings (EVERY user, both roles)
Grouped list with section headers. Build all of these:

**Account**
- Profile: avatar (change photo), full name, phone, email (read-only).
- Change password: current, new, confirm, with strength hint.

**Preferences**
- Appearance: System / Light / Dark (applies instantly and persists in memory).
- Language: English (others shown as "Coming soon", disabled).
- Units and format: distance unit (km/mi), currency (₹ default), date format.

**Notifications**
- Master toggle for notifications.
- Service reminders toggle with lead time selector (3 days, 1 week, 2 weeks).
- Document expiry reminders toggle (30, 15, 7 days).
- Delivery channels: Push, Email (toggles only).

**Security**
- Biometric lock toggle (UI only).
- Active sessions: show "This device" only (mock).
- Sign out of all devices (confirmation dialog).

**Company** (admin only section)
- Company name, logo, depots list, default reminder lead time.

**About**
- App version, Terms, Privacy policy, Help and support, Log out.

Settings values are held in a `SettingsController` backed by a `SettingsRepository`
interface (mock in-memory now, real storage later).

# CAMERA AND PHOTO CAPTURE (applies to every photo feature)

Photo capture is a core feature, not a detail. It is used for: vehicle photos, service
Before / After photos, Parts-replaced photos, Bill capture, and the profile avatar.

## Shared building blocks (build once in core/, reuse everywhere)
- `PhotoSourceSheet`: bottom sheet with "Take photo", "Choose from gallery", and Cancel.
- `MediaService` (interface in core/services, mock-safe implementation using `image_picker`):
  `pickFromCamera()`, `pickFromGallery()`, `pickMultiFromGallery(limit)`, `compress(file)`.
- `PhotoCaptureField`: a reusable widget showing thumbnails, an "Add photo" tile, per-photo
  remove (with confirm), per-photo caption (where required), reorder is optional, and a
  max-count indicator ("3 of 5").
- `PhotoViewer`: full-screen, pinch-zoom, swipe between photos, delete (where allowed).

## Behavior rules
- Camera opens the rear camera by default. Gallery supports multi-select where more than
  one photo is allowed.
- After capture show a preview with "Use photo" and "Retake". For bills also offer rotate
  and a simple crop, because bills are photographed at angles.
- Bill capture: full-screen guidance text ("Place the bill flat, fill the frame, avoid
  glare"), then preview, then the mock OCR step. Allow adding multiple pages to one bill.
- Show a thumbnail immediately after capture with an upload-state overlay (mock: uploading,
  done, failed with Retry). This models the real upload behavior built later.
- Compress images before use (target longest side about 1600 px, quality about 80) behind
  `MediaService.compress` so the real upload reuses it.
- Photos are tagged by type (`before`, `after`, `part`, `bill`, `vehicle`, `avatar`) and by
  the service/vehicle they belong to.
- Parts-replaced photos can be linked to a specific part row, with a caption.
- Staff and admin can both add photos. Only admin can delete a saved photo.

## Permissions and edge cases
- Camera and photo-library permission requests happen at the moment of first use, with a
  one-line explanation first ("We use the camera to photograph bills and parts").
- If permission is denied: show an inline message with a "Choose from gallery" fallback.
- If permanently denied: show a clear message and an "Open settings" button.
- Handle cancel, no camera available (simulator), very large images, and the app being
  backgrounded during capture without losing the in-progress service draft.
- Do not crash or overflow on any of these. Add widget tests for the permission-denied UI
  states using a fake `MediaService`.

## Platform configuration (the agent must do this, not skip it)
- iOS `Info.plist`: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`
  (and `NSPhotoLibraryAddUsageDescription` if saving). Use plain, specific wording.
- Android: camera and media permissions as required by the `image_picker` version in use;
  verify on Android 13 and 14 behavior.
- Document the exact setup in README.md and test on a real device at least once
  (camera does not work on iOS simulator).

# DESIGN SYSTEM (strict)

The result must look like a shipped B2B product, not a template or a generated demo.

## Principles
Calm, dense-but-readable, data first. Operational software for people who check it
quickly on a phone. Nothing decorative.

## Color tokens (define in `core/theme/app_colors.dart`, never hardcode elsewhere)
Light:
- primary `#0F4C81`, onPrimary `#FFFFFF`
- background `#F6F7F9`, surface `#FFFFFF`, surfaceMuted `#EEF0F3`
- textPrimary `#111827`, textSecondary `#5B6472`, border `#E2E5EA`
- success `#157347`, warning `#B26A00`, danger `#B42318`, info `#175CD3`
  (each with a matching 10 to 12% tinted background for chips)
Dark: derive proper dark equivalents (background `#0E1116`, surface `#171B22`, etc.).
Contrast must meet WCAG AA in both themes.

## Typography
Font: Inter (bundle in `assets/fonts/`, do not fetch at runtime).
Scale: headline 24/600, title 18/600, subtitle 16/600, body 14/400, label 12/500,
caption 12/400. Use tabular figures for odometer, dates, and money.

## Spacing, shape, elevation
- 4 pt base grid. Allowed spacing: 4, 8, 12, 16, 24, 32.
- Screen horizontal padding 16. Card radius 12. Input radius 10. Chip radius 999.
- Cards: 1 px border, NO shadows. At most one elevated element per screen (FAB).
- Minimum tap target 48x48.

## Components (build once in `core/widgets/`, reuse everywhere)
`AppButton` (primary, secondary, text, destructive), `AppTextField`, `StatusChip`,
`SectionHeader`, `StatTile`, `VehicleTile`, `BusFlashCard`, `TaskTile`, `TimelineEntry`,
`PhotoGrid`, `PhotoViewer`, `EmptyState`, `ErrorState`, `SkeletonBox`, `AppBottomSheet`,
`ConfirmDialog`, `SettingsTile`, `SettingsSection`.

## Hard bans
- No gradients, glassmorphism, neon, or drop-shadow stacks.
- No emoji anywhere in the UI. Use Material Symbols / `Icons` consistently (one icon
  family, rounded or outlined, never mixed).
- No stock-photo illustrations, no lorem ipsum, no "Item 1 / Test" data.
- No more than one accent color. Status colors are only for status.
- No full-width colored banners except for errors.
- No hardcoded colors, font sizes, or spacing values inside screen files.
- No `Scaffold` copy-paste: use a shared page scaffold for consistent app bars.

## Motion
Subtle only: 150 to 250 ms, standard easing. Page transitions use the platform default.
Checkbox complete, chip changes, and drawer are the only custom animations.

## Accessibility
Semantics labels on icon buttons and images, text scales to 1.3x without overflow,
status never conveyed by color alone (chip includes text), works with TalkBack/VoiceOver.

# MOCK DATA REQUIREMENTS

- 10 buses with varied makes (Ashok Leyland, Tata, Eicher, Volvo), years 2016 to 2024,
  odometers 40,000 to 480,000 km, mixed statuses (6 active/on track, 2 due soon,
  1 overdue, 1 in workshop).
- 3 to 8 historical services per bus, realistic costs (₹2,500 to ₹1,80,000), parts lists
  (brake pads, clutch plate, engine oil, air filter, tyres, battery, alternator, etc.).
- Dates are generated RELATIVE to today so the dashboard always looks current.
- 5 users (2 admin, 3 staff) with mixed statuses.
- Mock images: ship 6 to 10 neutral local placeholder images in `assets/mock/`. If none
  are available, use a neutral placeholder widget. Never use network images.
- Simulate latency (300 to 800 ms) in mock repositories and one failing request path to
  prove error states work.

# ENGINEERING RULES

- Flutter stable, Dart null-safe, `flutter_lints` + `very_good_analysis`-style strictness.
  `flutter analyze` must show ZERO issues.
- State: Riverpod (`flutter_riverpod`, `AsyncNotifier`). Routing: `go_router` with a
  role-based redirect guard.
- Models are immutable (`freezed` is optional, plain const classes with `copyWith` are
  fine). Add `fromJson/toJson` to models now so the backend swap is trivial.
- UI never touches mock data directly. UI -> controller -> repository interface.
- Screens under 250 lines. Extract widgets. No business logic in `build()`.
- All strings in one `core/constants/app_strings.dart` (prepares for localization).
- No packages beyond: `flutter_riverpod`, `go_router`, `intl`, `image_picker`,
  `shimmer` (optional), `photo_view`, `flutter_svg` (optional). Ask before adding any
  other.
- Responsive: phone portrait is primary; tablets use constrained max width (600) centered.
- Add widget tests for: login validation, role-based drawer items, to-do completion,
  settings theme switch. Add at least one golden test for `BusFlashCard`.

# WORKFLOW

Work in these milestones. After each, run `flutter analyze` and `flutter test`, then
summarize what was built before moving on. Do NOT skip ahead.

1. Project setup, theme, tokens, core widgets, router skeleton.
2. Mock data layer + repositories + providers.
3. Login + Forgot password.
4. Home dashboard (summary, to-do, flashcards, all vehicles) + drawer.
5. Vehicle list, Vehicle detail (all tabs), Add/Edit vehicle.
6. Service detail, Add service record (with mock OCR), Service history, Bills, Reminders.
7. Users (admin) + Settings (all sections).
8. Polish: empty/error/loading states, dark mode pass, accessibility pass, tests.

# DEFINITION OF DONE

- App runs on Android emulator and iOS simulator with no errors or overflow warnings.
- Every screen above exists, is reachable, and handles loading, empty, and error states.
- Staff and admin experiences differ exactly as specified.
- Light and dark themes both look finished.
- `flutter analyze` clean, tests pass.
- README with run instructions, demo credentials, and a screen map.
- A short `DEMO_SCRIPT.md` listing a 5-minute click path to show the client.

# IF YOU ARE UNSURE

Make the most conventional, professional choice and note it in `DECISIONS.md`.
Do not ask questions that block progress. Do not add features not listed here.
