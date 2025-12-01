import '../result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class AuthUseCase {
  final IAuthRepository _authRepository;

  const AuthUseCase(this._authRepository);

  Future<Result<AuthUser>> login(String email, String password) async {
    if (email.isEmpty) {
      return const Failure('Email cannot be empty');
    }
    if (password.isEmpty) {
      return const Failure('Password cannot be empty');
    }
    if (!_isValidEmail(email)) {
      return const Failure('Please enter a valid email address');
    }
    if (password.length < 6) {
      return const Failure('Password must be at least 6 characters');
    }

    return _authRepository.login(email, password);
  }

  Future<Result<AuthUser>> register(String email, String password, String confirmPassword) async {
    if (email.isEmpty) {
      return const Failure('Email cannot be empty');
    }
    if (password.isEmpty) {
      return const Failure('Password cannot be empty');
    }
    if (confirmPassword.isEmpty) {
      return const Failure('Please confirm your password');
    }
    if (!_isValidEmail(email)) {
      return const Failure('Please enter a valid email address');
    }
    if (password.length < 6) {
      return const Failure('Password must be at least 6 characters');
    }
    if (password != confirmPassword) {
      return const Failure('Passwords do not match');
    }

    return _authRepository.register(email, password);
  }

  Future<Result<void>> logout() => _authRepository.logout();

  Future<Result<AuthUser?>> getCurrentUser() => _authRepository.getCurrentUser();

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}