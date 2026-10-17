import 'package:flutter_test/flutter_test.dart';
import 'package:bus_app/core/router/route_guards.dart';
import 'package:bus_app/features/auth/domain/app_user.dart';

void main() {
  group('RouteGuards Redirect Logic Tests', () {
    const adminUser = AppUser(
      id: '1',
      name: 'Admin',
      email: 'admin@fleetpulse.com',
      phone: '123',
      role: UserRole.admin,
      status: UserStatus.active,
    );

    const staffUser = AppUser(
      id: '2',
      name: 'Staff',
      email: 'staff@fleetpulse.com',
      phone: '456',
      role: UserRole.staff,
      status: UserStatus.active,
    );

    test(
        'unauthenticated user redirected to /login when accessing protected routes',
        () {
      expect(
        RouteGuards.checkRedirect(
            location: '/', isAuthenticated: false, currentUser: null),
        '/login',
      );
      expect(
        RouteGuards.checkRedirect(
            location: '/vehicles', isAuthenticated: false, currentUser: null),
        '/login',
      );
      expect(
        RouteGuards.checkRedirect(
            location: '/settings', isAuthenticated: false, currentUser: null),
        '/login',
      );
    });

    test(
        'unauthenticated user allowed on public routes (/login, /forgot-password)',
        () {
      expect(
        RouteGuards.checkRedirect(
            location: '/login', isAuthenticated: false, currentUser: null),
        isNull,
      );
      expect(
        RouteGuards.checkRedirect(
            location: '/forgot-password',
            isAuthenticated: false,
            currentUser: null),
        isNull,
      );
    });

    test(
        'authenticated user visiting /login or /forgot-password redirected to dashboard /',
        () {
      expect(
        RouteGuards.checkRedirect(
            location: '/login', isAuthenticated: true, currentUser: adminUser),
        '/',
      );
      expect(
        RouteGuards.checkRedirect(
            location: '/forgot-password',
            isAuthenticated: true,
            currentUser: adminUser),
        '/',
      );
    });

    test(
        'staff user blocked from admin-only routes and redirected to dashboard',
        () {
      expect(
        RouteGuards.checkRedirect(
            location: '/users', isAuthenticated: true, currentUser: staffUser),
        '/',
      );
      expect(
        RouteGuards.checkRedirect(
            location: '/vehicles/new',
            isAuthenticated: true,
            currentUser: staffUser),
        '/',
      );
      expect(
        RouteGuards.checkRedirect(
            location: '/settings/company',
            isAuthenticated: true,
            currentUser: staffUser),
        '/',
      );
    });

    test('admin user permitted on admin routes', () {
      expect(
        RouteGuards.checkRedirect(
            location: '/users', isAuthenticated: true, currentUser: adminUser),
        isNull,
      );
      expect(
        RouteGuards.checkRedirect(
            location: '/vehicles/new',
            isAuthenticated: true,
            currentUser: adminUser),
        isNull,
      );
    });
  });
}
