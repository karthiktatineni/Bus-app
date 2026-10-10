import '../../auth/domain/app_user.dart';

abstract class UserRepository {
  Future<List<AppUser>> list();
  Future<AppUser> get(String id);
  Future<AppUser> invite({
    required String name,
    required String email,
    required UserRole role,
    required String phone,
  });
  Future<AppUser> update(AppUser u);
  Future<void> remove(String id);
}
