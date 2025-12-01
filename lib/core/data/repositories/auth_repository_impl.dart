import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/result.dart';
import '../services/safe_preferences_manager.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final SafePreferencesManager _prefsManager;

  const AuthRepositoryImpl(this._prefsManager);

  @override
  Future<Result<AuthUser>> login(String email, String password) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Simple validation for demo
      if (email.isNotEmpty && password.length >= 6) {
        final user = AuthUser(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          createdAt: DateTime.now(),
        );
        
        final saveResult = await saveUser(user);
        if (saveResult.isFailure) {
          return Failure(saveResult.error!);
        }
        
        return Success(user);
      }
      
      return const Failure('Invalid email or password');
    } catch (e) {
      return Failure('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<Result<AuthUser>> register(String email, String password) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      final user = AuthUser(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        createdAt: DateTime.now(),
      );
      
      final saveResult = await saveUser(user);
      if (saveResult.isFailure) {
        return Failure(saveResult.error!);
      }
      
      return Success(user);
    } catch (e) {
      return Failure('Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _prefsManager.removeMultiple(['is_logged_in', 'user_email', 'user_id', 'user_created_at']);
      return const Success(null);
    } catch (e) {
      return Failure('Logout failed: ${e.toString()}');
    }
  }

  @override
  Future<Result<AuthUser?>> getCurrentUser() async {
    try {
      final isLoggedIn = await _prefsManager.getBool('is_logged_in');
      if (isLoggedIn.isFailure || !isLoggedIn.data!) {
        return const Success(null);
      }

      final emailResult = await _prefsManager.getString('user_email');
      final idResult = await _prefsManager.getString('user_id');
      final createdAtResult = await _prefsManager.getString('user_created_at');

      if (emailResult.isFailure || idResult.isFailure) {
        return const Success(null);
      }

      DateTime createdAt = DateTime.now();
      if (createdAtResult.isSuccess && createdAtResult.data != null) {
        createdAt = DateTime.tryParse(createdAtResult.data!) ?? DateTime.now();
      }

      return Success(AuthUser(
        id: idResult.data!,
        email: emailResult.data!,
        createdAt: createdAt,
      ));
    } catch (e) {
      return Failure('Failed to get current user: ${e.toString()}');
    }
  }

  @override
  Future<Result<void>> saveUser(AuthUser user) async {
    try {
      final results = await Future.wait([
        _prefsManager.setBool('is_logged_in', true),
        _prefsManager.setString('user_email', user.email),
        _prefsManager.setString('user_id', user.id),
        _prefsManager.setString('user_created_at', user.createdAt.toIso8601String()),
      ]);

      for (final result in results) {
        if (result.isFailure) {
          return Failure(result.error!);
        }
      }

      return const Success(null);
    } catch (e) {
      return Failure('Failed to save user: ${e.toString()}');
    }
  }
}