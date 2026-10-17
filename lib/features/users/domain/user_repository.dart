import '../../auth/domain/app_user.dart';

abstract class UserRepository {
  Future<List<AppUser>> list();
  Future<AppUser> get(String id);
  Future<AppUser> create({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String phone,
  });
  Future<AppUser> update(AppUser u, {String? password});
  Future<void> remove(String id);
}
