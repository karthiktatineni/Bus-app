# Screen Map

This document maps the exported Stitch designs in `screen_designs/` to the application screens.

1. `01_login`: Authentication screen -> `lib/src/features/auth/presentation/login_screen.dart`
2. `02_dashboard`: Main overview dashboard with depot metrics -> `lib/src/features/dashboard/presentation/dashboard_screen.dart`
3. `03_drawer`: Left navigation drawer with user profile and menu -> `lib/src/common_widgets/app_drawer.dart`
4. `04_vehicles_list`: List of all buses with search, filter, and quick statuses -> `lib/src/features/vehicles/presentation/vehicles_list_screen.dart`
5. `05_vehicle_detail_overview`: Vehicle detail view (Overview tab) -> `lib/src/features/vehicles/presentation/vehicle_detail_screen.dart`
6. `05_vehicle_detail_alt`: Vehicle detail view (Service History/Issues tab) -> `lib/src/features/vehicles/presentation/vehicle_detail_screen.dart`
7. `06_add_edit_vehicle`: Stepper form to add or edit a vehicle's details -> `lib/src/features/vehicles/presentation/add_edit_vehicle_screen.dart`
8. `07_service_detail`: Read-only view of a completed maintenance service -> `lib/src/features/services/presentation/service_detail_screen.dart`
9. `08_add_service`: Stepper form to add a service record, highlighting Bill OCR -> `lib/src/features/services/presentation/add_service_screen.dart`
10. `09_service_history`: Screen showing service history and bills lists -> `lib/src/features/services/presentation/service_history_screen.dart`
11. `10_reminders`: Grouped lists of upcoming maintenance tasks (Overdue, This Week, etc.) -> `lib/src/features/reminders/presentation/reminders_screen.dart`
12. `11_users`: Admin view listing depot staff and user roles -> `lib/src/features/users/presentation/users_screen.dart`
13. `12_settings`: Application settings, preferences, and notifications -> `lib/src/features/settings/presentation/settings_screen.dart`
