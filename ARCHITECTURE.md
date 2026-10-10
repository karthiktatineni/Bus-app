# ARCHITECTURE: Fleet Maintenance App (Flutter)

Audience: the AI coding agent building this project, and the developers who take it to
production. Frontend phase uses mock data. The structure is designed so the backend
phase replaces only the `data/` layer.

## 1. Principles

1. **Feature-first folders.** Each feature owns its UI, state, and data.
2. **Three layers per feature:** `presentation` (screens, widgets, controllers),
   `domain` (models, repository interfaces), `data` (repository implementations).
3. **Dependency direction:** presentation -> domain <- data. The UI never imports from `data/`.
4. **Mock now, real later.** Every repository has an interface in `domain` and a mock
   implementation in `data`. Swapping to the real backend means adding one new
   implementation and changing one provider override.
5. **Design tokens only.** No hardcoded colors, sizes, or strings in screen files.

## 2. Tech stack

| Concern | Choice |
|---|---|
| Framework | Flutter (stable), Dart |
| State | `flutter_riverpod` (AsyncNotifier) |
| Routing | `go_router` with role-based redirect |
| Images | `image_picker`, `photo_view` |
| Formatting | `intl` |
| Lints | `flutter_lints` (strict analysis options) |

Backend phase (not now): see section 9.

## 3. Folder structure

```
fleet_care/
├── AGENT_PROMPT.md
├── ARCHITECTURE.md
├── README.md
├── DECISIONS.md
├── DEMO_SCRIPT.md
├── pubspec.yaml
├── analysis_options.yaml
├── assets/
│   ├── fonts/                  # Inter
│   ├── mock/                   # placeholder bus, part, bill images
│   └── logo/
├── lib/
│   ├── main.dart
│   ├── app.dart                # MaterialApp.router, theme, providers scope
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_strings.dart
│   │   │   └── app_sizes.dart          # spacing, radius, tap targets
│   │   ├── theme/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_typography.dart
│   │   │   └── app_theme.dart          # light + dark ThemeData
│   │   ├── router/
│   │   │   ├── app_router.dart
│   │   │   ├── route_names.dart
│   │   │   └── route_guards.dart       # auth + role redirects
│   │   ├── utils/
│   │   │   ├── date_utils.dart         # "Tomorrow", "In 5 days", overdue labels
│   │   │   ├── money_format.dart       # Indian grouping, ₹
│   │   │   └── validators.dart
│   │   ├── errors/
│   │   │   └── app_exception.dart
│   │   ├── services/
│   │   │   ├── media_service.dart          # interface: camera, gallery, multi-pick, compress
│   │   │   └── image_picker_media_service.dart
│   │   └── widgets/                    # shared design-system components
│   │       ├── app_button.dart
│   │       ├── app_text_field.dart
│   │       ├── page_scaffold.dart
│   │       ├── status_chip.dart
│   │       ├── section_header.dart
│   │       ├── stat_tile.dart
│   │       ├── empty_state.dart
│   │       ├── error_state.dart
│   │       ├── skeleton_box.dart
│   │       ├── confirm_dialog.dart
│   │       ├── app_bottom_sheet.dart
│   │       ├── photo_grid.dart
│   │       ├── photo_source_sheet.dart     # take photo / choose from gallery
│   │       ├── photo_capture_field.dart    # thumbnails, add, remove, caption, upload state
│   │       ├── bill_capture_screen.dart    # guidance, preview, rotate, crop, multi-page
│   │       └── photo_viewer.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── domain/
│   │   │   │   ├── app_user.dart               # id, name, email, role, status
│   │   │   │   └── auth_repository.dart        # interface
│   │   │   ├── data/
│   │   │   │   └── mock_auth_repository.dart
│   │   │   └── presentation/
│   │   │       ├── auth_controller.dart        # session state
│   │   │       ├── login_screen.dart
│   │   │       └── forgot_password_screen.dart
│   │   ├── dashboard/
│   │   │   └── presentation/
│   │   │       ├── dashboard_screen.dart
│   │   │       ├── dashboard_controller.dart   # composes tasks + vehicles
│   │   │       └── widgets/
│   │   │           ├── summary_row.dart
│   │   │           ├── todo_section.dart
│   │   │           ├── task_tile.dart
│   │   │           ├── bus_flash_card.dart
│   │   │           └── flash_card_carousel.dart
│   │   ├── navigation/
│   │   │   └── presentation/
│   │   │       └── app_drawer.dart             # role-aware items
│   │   ├── vehicles/
│   │   │   ├── domain/
│   │   │   │   ├── vehicle.dart
│   │   │   │   ├── vehicle_document.dart       # insurance, permit, fitness, PUC
│   │   │   │   ├── vehicle_status.dart
│   │   │   │   └── vehicle_repository.dart
│   │   │   ├── data/
│   │   │   │   └── mock_vehicle_repository.dart
│   │   │   └── presentation/
│   │   │       ├── vehicles_screen.dart
│   │   │       ├── vehicle_detail_screen.dart
│   │   │       ├── vehicle_form_screen.dart    # add + edit
│   │   │       ├── vehicles_controller.dart
│   │   │       └── widgets/
│   │   │           ├── vehicle_tile.dart
│   │   │           ├── overview_tab.dart
│   │   │           ├── history_tab.dart
│   │   │           ├── upcoming_tab.dart
│   │   │           ├── documents_tab.dart
│   │   │           └── photos_tab.dart
│   │   ├── services/
│   │   │   ├── domain/
│   │   │   │   ├── service_record.dart
│   │   │   │   ├── service_part.dart           # name, qty, cost, photo
│   │   │   │   ├── service_photo.dart          # type: before | after | part | bill
│   │   │   │   ├── maintenance_task.dart       # upcoming/scheduled work
│   │   │   │   └── service_repository.dart
│   │   │   ├── data/
│   │   │   │   └── mock_service_repository.dart
│   │   │   └── presentation/
│   │   │       ├── service_detail_screen.dart
│   │   │       ├── service_history_screen.dart
│   │   │       ├── reminders_screen.dart
│   │   │       ├── add_service/
│   │   │       │   ├── add_service_screen.dart     # stepper host
│   │   │       │   ├── add_service_controller.dart # draft state
│   │   │       │   ├── step_details.dart
│   │   │       │   ├── step_parts.dart
│   │   │       │   ├── step_photos.dart
│   │   │       │   ├── step_bill.dart
│   │   │       │   └── step_review.dart
│   │   │       └── widgets/timeline_entry.dart
│   │   ├── bills/
│   │   │   ├── domain/
│   │   │   │   ├── bill.dart                   # vendor, number, date, items, tax, total
│   │   │   │   ├── ocr_service.dart            # interface: Future<OcrResult> scan(File)
│   │   │   │   └── bill_repository.dart
│   │   │   ├── data/
│   │   │   │   ├── mock_ocr_service.dart       # fake delay + canned fields
│   │   │   │   └── mock_bill_repository.dart
│   │   │   └── presentation/
│   │   │       ├── bills_screen.dart
│   │   │       └── bill_detail_screen.dart
│   │   ├── users/                              # admin only
│   │   │   ├── domain/user_repository.dart
│   │   │   ├── data/mock_user_repository.dart
│   │   │   └── presentation/
│   │   │       ├── users_screen.dart
│   │   │       ├── add_user_sheet.dart
│   │   │       └── user_detail_screen.dart
│   │   └── settings/                           # every user
│   │       ├── domain/
│   │       │   ├── user_settings.dart          # theme, units, notifications, security
│   │       │   ├── company_settings.dart       # admin section
│   │       │   └── settings_repository.dart
│   │       ├── data/
│   │       │   └── mock_settings_repository.dart
│   │       └── presentation/
│   │           ├── settings_screen.dart
│   │           ├── settings_controller.dart    # drives theme mode app-wide
│   │           ├── profile_screen.dart
│   │           ├── change_password_screen.dart
│   │           ├── notifications_settings_screen.dart
│   │           ├── security_settings_screen.dart
│   │           ├── company_settings_screen.dart  # admin only
│   │           └── widgets/
│   │               ├── settings_section.dart
│   │               └── settings_tile.dart
│   └── mock/
│       ├── mock_data.dart                      # builds fleet relative to DateTime.now()
│       └── mock_delay.dart                     # latency + failure simulation
└── test/
    ├── auth/login_validation_test.dart
    ├── navigation/drawer_roles_test.dart
    ├── dashboard/todo_completion_test.dart
    ├── settings/theme_switch_test.dart
    └── goldens/bus_flash_card_golden_test.dart
```

## 4. Layer contracts

### Domain models (immutable, with `copyWith`, `fromJson`, `toJson`)

- `AppUser { id, name, email, phone, role(admin|staff), status(active|invited|disabled), avatarUrl? }`
- `Vehicle { id, registrationNo, make, model, year, chassisNo, engineNo, seats, fuelType, odometerKm, depot, purchaseDate, status, photos[], documents[] }`
- `VehicleDocument { type, number, expiryDate, fileUrl? }`
- `MaintenanceTask { id, vehicleId, title, dueDate?, dueKm?, isDone }`
- `ServiceRecord { id, vehicleId, type, date, odometerKm, workshop, mechanic, notes, parts[], labourCost, tax, total, photos[], billId? }`
- `ServicePhoto { id, url, type(before|after|part|bill), caption?, partId? }`
- `Bill { id, vehicleId, serviceId, vendor, billNo, billDate, items[], tax, total, imageUrl, ocrConfidence }`
- `UserSettings { themeMode, language, distanceUnit, currency, dateFormat, notificationsEnabled, serviceReminders(bool, leadDays), docExpiryReminders(bool, leadDays), pushEnabled, emailEnabled, biometricLock }`
- `CompanySettings { name, logoUrl?, depots[], defaultReminderLeadDays }`

### Repository interfaces (domain)

```dart
abstract class AuthRepository {
  Future<AppUser> signIn(String email, String password);
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<void> changePassword(String current, String next);
}

abstract class VehicleRepository {
  Future<List<Vehicle>> list();
  Future<Vehicle> get(String id);
  Future<Vehicle> create(Vehicle v);
  Future<Vehicle> update(Vehicle v);
  Future<void> delete(String id);
}

abstract class ServiceRepository {
  Future<List<ServiceRecord>> listAll({String? vehicleId});
  Future<ServiceRecord> get(String id);
  Future<ServiceRecord> create(ServiceRecord r);
  Future<List<MaintenanceTask>> upcomingTasks({int withinDays = 14});
  Future<void> setTaskDone(String taskId, bool done);
}

abstract class OcrService {
  Future<OcrResult> scanBill(String imagePath);
}

abstract class UserRepository {
  Future<List<AppUser>> list();
  Future<AppUser> invite({required String name, required String email, required Role role});
  Future<AppUser> update(AppUser u);
  Future<void> remove(String id);
}

abstract class SettingsRepository {
  Future<UserSettings> getUserSettings();
  Future<void> saveUserSettings(UserSettings s);
  Future<CompanySettings> getCompanySettings();
  Future<void> saveCompanySettings(CompanySettings s);
}
```

### Providers wiring

All repositories are exposed through providers in a single place per feature, for
example `vehicleRepositoryProvider`. `main.dart` uses the mock implementations. The
backend phase overrides them with real implementations, and no UI file changes.

## 5. Navigation map

```
/login
/forgot-password
/ (shell with drawer)
 ├── /dashboard
 ├── /vehicles
 │    ├── /vehicles/new             (admin)
 │    └── /vehicles/:id
 │         ├── /vehicles/:id/edit  (admin)
 │         └── /vehicles/:id/service/new
 ├── /services                      (service history)
 │    └── /services/:id
 ├── /bills
 │    └── /bills/:id
 ├── /reminders
 ├── /users                         (admin)
 │    └── /users/:id
 ├── /settings
 │    ├── /settings/profile
 │    ├── /settings/password
 │    ├── /settings/notifications
 │    ├── /settings/security
 │    └── /settings/company         (admin)
 └── /help
```

Redirect rules in `route_guards.dart`:
- Not signed in -> `/login`.
- Signed in and visiting `/login` -> `/dashboard`.
- Staff visiting an admin route -> `/dashboard` with a snackbar.

## 6. Role matrix

| Capability | Admin | Staff |
|---|:--:|:--:|
| View dashboard, vehicles, history, bills | Yes | Yes |
| Add service record and photos | Yes | Yes |
| Mark tasks done | Yes | Yes |
| Add / edit / delete vehicle | Yes | No |
| Edit or delete service record | Yes | No |
| Manage users | Yes | No |
| Company settings | Yes | No |
| Personal settings (profile, theme, notifications, security) | Yes | Yes |

## 7. Settings architecture

- `SettingsController` (AsyncNotifier) loads `UserSettings` once after login.
- `app.dart` watches `settingsController.themeMode`, so changing appearance applies
  immediately app-wide.
- Notification and security toggles update the same state and save through
  `SettingsRepository`. Backend phase: persisted per user in the database.
- Company settings live in a separate controller, visible only to admin, and also drive
  the default reminder lead time used when new vehicles are created.

## 8. Testing strategy

- Unit: validators, date label helpers, money formatting.
- Widget: login validation, drawer shows admin-only items only for admin, to-do
  completion with undo, settings theme switch.
- Golden: `BusFlashCard` in light and dark.
- CI: `flutter analyze` and `flutter test` on every push (GitHub Actions).

## 8b. Camera and photo capture

- All photo features go through `MediaService` and the shared `PhotoSourceSheet` and
  `PhotoCaptureField` widgets. No feature calls `image_picker` directly.
- Used by: vehicle photos, service Before / After / Parts photos, bill capture, avatar.
- Images are compressed on the device before upload (about 1600 px longest side, quality
  about 80). Upload state per photo: uploading, done, failed (retry).
- Permissions are requested at first use with an explanation; denied and
  permanently-denied states have dedicated UI.
- Platform setup: iOS `Info.plist` camera and photo library usage descriptions; Android
  permissions per `image_picker` docs. Camera must be tested on a real device.
- Backend phase: photos upload to private Storage buckets, shown via signed URLs
  (see section 9). Bill capture feeds `OcrService`.

## 9. Backend phase (after client approves the demo)

Recommended: **Supabase** (Postgres + Auth + Storage + Row Level Security), or Firebase
if you prefer NoSQL. Both give auth, file storage, and a Flutter SDK.

| Need | Supabase | Firebase |
|---|---|---|
| Auth + roles | Supabase Auth + `profiles.role` | Firebase Auth + custom claims |
| Data | Postgres tables | Firestore |
| Images and bills | Storage buckets | Cloud Storage |
| Multi-company isolation | RLS policies on `company_id` | Security rules |
| Reminders | Scheduled Edge Function / pg_cron | Cloud Functions scheduler |

Planned tables: `companies`, `profiles`, `vehicles`, `vehicle_documents`,
`maintenance_tasks`, `service_records`, `service_parts`, `service_photos`, `bills`,
`user_settings`, `company_settings`. Every row carries `company_id`.

**OCR options:**
1. On-device: Google ML Kit text recognition (free, offline, then parse fields).
2. Cloud: Google Document AI (Invoice Parser) or AWS Textract for better structured
   extraction of vendor, bill number, line items, tax, total.

Start with option 1 for the pilot, move to option 2 if accuracy is not good enough.
The `OcrService` interface stays the same either way.

**Push notifications:** Firebase Cloud Messaging for both Android and iOS (iOS also
needs an APNs key from your Apple Developer account).

## 10. Release path

1. Client demo: Android release APK; iOS screen recording (or TestFlight once you have
   the Apple Developer account).
2. iOS builds need macOS + Xcode, or a cloud builder like Codemagic.
3. TestFlight and Google Play Internal Testing for the pilot with real buses.
4. Store release after the backend and OCR are stable.
5. Before release: app icon, splash screen, privacy policy URL, store screenshots,
   Android signing key backup, iOS bundle ID and signing set up.

## 11. Naming and code conventions

- Files `snake_case.dart`, classes `PascalCase`, providers `camelCaseProvider`.
- One public widget per file. Private helper widgets stay in the same file.
- Screens only compose widgets and watch providers. Logic lives in controllers.
- No `print`. Use a logger wrapper if logging is needed.
- No TODO comments left in the final frontend delivery. Put open items in `DECISIONS.md`.
