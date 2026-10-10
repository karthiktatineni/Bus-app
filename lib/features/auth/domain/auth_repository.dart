import 'app_user.dart';

abstract class AuthRepository {
  Future<AppUser> signIn(String email, String password);
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<void> changePassword(String current, String next);
  Future<AppUser?> getCurrentUser();
}
