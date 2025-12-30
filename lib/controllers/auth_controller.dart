import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// Controlador de autenticación (demo)
class AuthController extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  static const String _userKey = 'logged_in_user';

  /// Inicializa el controlador y verifica sesión guardada
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_userKey) ?? false;

      if (isLoggedIn) {
        _currentUser = User.demo;
      }
    } catch (e) {
      debugPrint('Error al inicializar auth: $e');
    }

    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  /// Login con credenciales demo
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simular latencia de red
    await Future.delayed(const Duration(milliseconds: 800));

    // Credenciales demo: cualquier email con password "demo"
    if (password == 'demo' || (email == 'demo@streamui.chat')) {
      _currentUser = User(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        name: _extractName(email),
        email: email,
      );

      // Guardar sesión
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_userKey, true);

      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Login rápido con usuario demo
  Future<void> loginAsDemo() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _currentUser = User.demo;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_userKey, true);

    _isLoading = false;
    notifyListeners();
  }

  /// Cerrar sesión
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);

    _isLoading = false;
    notifyListeners();
  }

  /// Extrae el nombre del email
  String _extractName(String email) {
    final localPart = email.split('@').first;
    return localPart
        .split(RegExp(r'[._-]'))
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}
