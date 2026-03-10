import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:to_do_app_herody/features/auth/data/auth_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  // ── State Variables ──────────────────────────────────────────
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;

  // ── Getters ──────────────────────────────────────────────────
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get userId => _user?.uid;
  String? get userEmail => _user?.email;
  String? get userName => _user?.displayName;
  String? get userPhoto => _user?.photoURL;

  // ── Constructor → listen to Firebase auth state automatically ─
  AuthProvider() {
    _init();
  }

  void _init() {
    // Listens to login/logout changes from Firebase automatically
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      if (user != null) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  // ─────────────────────────────────────────────────────────────
  // 1. SIGN UP
  // ─────────────────────────────────────────────────────────────
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final credential = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (credential != null) {
        _user = credential.user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 2. LOGIN with Email & Password
  // ─────────────────────────────────────────────────────────────
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final credential = await _authService.loginWithEmail(
        email: email,
        password: password,
      );

      if (credential != null) {
        _user = credential.user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 3. GOOGLE SIGN IN
  // ─────────────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();

      final credential = await _authService.signInWithGoogle();

      // User cancelled Google picker
      if (credential == null) {
        _setLoading(false);
        return false;
      }

      _user = credential.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 4. FORGOT PASSWORD
  // ─────────────────────────────────────────────────────────────
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 5. LOGOUT
  // ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.signOut();
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 6. CLEAR ERROR — call this when user starts typing again
  // ─────────────────────────────────────────────────────────────
  void clearError() => _clearError();

  // ── Private Helpers ──────────────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = AuthStatus.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}