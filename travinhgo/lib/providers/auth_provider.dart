import 'package:flutter/widgets.dart';
import 'package:travinhgo/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  String? _phoneNumber;
  String? _email;
  String? _userId;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get phoneNumber => _phoneNumber;
  String? get email => _email;
  String? get userId => _userId;

  // Constructor to check authentication state
  AuthProvider() {
    _initAuthState();
  }

  // Initialize auth state and load user claim
  Future<void> _initAuthState() async {
    _isAuthenticated = await _authService.isLoggedIn();
    if (_isAuthenticated) {
      _userId = await _authService.getUserId();
    }
    notifyListeners();
  }

  Future<bool> signInWithPhone(String phoneNumber) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _authService.authenticationWithPhone(phoneNumber);

      if (success) {
        // Store the phone number but don't mark as fully authenticated yet
        // User still needs to verify OTP
        _phoneNumber = phoneNumber;
      } else {
        _error = 'Authentication failed';
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _authService.verifyOtp(otp);

      if (success) {
        _isAuthenticated = true;
        // Get user ID from secure storage
        _userId = await _authService.getUserId();
      } else {
        _error = 'OTP verification failed';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _authService.authenticateWithGoogle();

      if (success) {
        // Store the email but don't mark as fully authenticated yet
        // User still needs to verify OTP
      } else {
        _error = 'Failed to authenticate with Google';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> refreshOtp(String identifier) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _authService.refreshOtp(identifier);

      if (!success) {
        _error = 'Failed to refresh OTP';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkAuthentication() async {
    final isLoggedIn = await _authService.isLoggedIn();
    _isAuthenticated = isLoggedIn;

    if (isLoggedIn) {
      // Load user ID from secure storage
      _userId = await _authService.getUserId();
    } else {
      _userId = null;
    }

    notifyListeners();
    return isLoggedIn;
  }

  // Check session with context to show dialog if needed
  Future<bool> checkSession(BuildContext context) async {
    return await _authService.checkSession(context);
  }

  Future<void> signOut() async {
    await _authService.logout();
    _isAuthenticated = false;
    _phoneNumber = null;
    _userId = null;
    notifyListeners();
  }
}
