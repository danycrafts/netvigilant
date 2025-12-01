import '../result.dart';
import '../entities/auth_user.dart';

abstract class IAuthRepository {
  Future<Result<AuthUser>> login(String email, String password);
  Future<Result<AuthUser>> register(String email, String password);
  Future<Result<void>> logout();
  Future<Result<AuthUser?>> getCurrentUser();
  Future<Result<void>> saveUser(AuthUser user);
}