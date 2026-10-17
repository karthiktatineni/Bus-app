import '../../features/auth/domain/app_user.dart';

class RouteGuards {
  static const Set<String> publicRoutes = {'/login', '/forgot-password'};
  static const Set<String> adminOnlyRoutes = {
    '/users',
    '/vehicles/new',
    '/vehicles/add',
    '/settings/company'
  };

  /// Evaluates routing redirect logic based on current authentication state and route path.
  static String? checkRedirect({
    required String location,
    required bool isAuthenticated,
    required AppUser? currentUser,
  }) {
    final isPublic = publicRoutes.contains(location);

    // 1. Not signed in and trying to access a protected route
    if (!isAuthenticated && !isPublic) {
      return '/login';
    }

    // 2. Already signed in and trying to access login/forgot-password
    if (isAuthenticated && isPublic) {
      return '/';
    }

    // 3. Staff user attempting to access admin-only route or edit service URL.
    // Service entry creation is open to staff; post-upload edits/deletes are admin-only.
    final isServiceEditRoute =
        location.startsWith('/services/') && location.endsWith('/edit');
    if (isAuthenticated && currentUser != null && !currentUser.isAdmin) {
      if (adminOnlyRoutes.contains(location) || isServiceEditRoute) {
        return '/';
      }
    }

    // No redirection needed
    return null;
  }
}
