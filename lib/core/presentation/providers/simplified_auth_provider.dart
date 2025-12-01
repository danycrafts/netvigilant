import 'package:flutter/foundation.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/usecases/auth_usecase.dart';
import '../../domain/result.dart';

class SimplifiedAuthProvider extends ChangeNotifier {
  final AuthUseCase _authUseCase;
  
  AuthUser? _currentUser;
  bool _isLoading = false;

  SimplifiedAuthProvider(this._authUseCase) {
    _loadCurrentUser();
  }

  AuthUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get userEmail => _currentUser?.email;
  String? get userId => _currentUser?.id;

  Future<void> _loadCurrentUser() async {
    _setLoading(true);
    
    final result = await _authUseCase.getCurrentUser();
    result.fold(
      onSuccess: (user) => _currentUser = user,
      onFailure: (error) => _currentUser = null,
    );
    
    _setLoading(false);
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    
    final result = await _authUseCase.login(email, password);
    final success = result.fold(
      onSuccess: (user) {
        _currentUser = user;
        return true;
      },
      onFailure: (error) => false,
    );
    
    _setLoading(false);
    return success;
  }

  Future<bool> register(String email, String password, String confirmPassword) async {
    _setLoading(true);
    
    final result = await _authUseCase.register(email, password, confirmPassword);
    final success = result.fold(
      onSuccess: (user) {
        _currentUser = user;
        return true;
      },
      onFailure: (error) => false,
    );
    
    _setLoading(false);
    return success;
  }

  Future<void> logout() async {
    _setLoading(true);
    
    await _authUseCase.logout();
    _currentUser = null;
    
    _setLoading(false);
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
}