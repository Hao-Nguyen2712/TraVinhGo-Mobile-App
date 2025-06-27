import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:travinhgo/services/auth_service.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../main.dart'; // Import navigatorKey
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isGoogleSignInInProgress = false;
  String? _error;
  String? _phoneNumber;
  String? _email;
  String? _userId;
  // Store Google user data
  GoogleSignInAccount? _googleUser;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isGoogleSignInInProgress => _isGoogleSignInInProgress;
  String? get error => _error ?? _authService.lastError;
  String? get phoneNumber => _phoneNumber;
  String? get email => _email;
  String? get userId => _userId;

  // Safe notify listeners that doesn't cause widget tree lock
  void _safeNotifyListeners() {
    // Use scheduleMicrotask to avoid widget tree lock issues
    debugPrint("AUTH: Scheduling notifyListeners via microtask");
    scheduleMicrotask(() {
      try {
        debugPrint("AUTH: Executing notifyListeners");
        notifyListeners();
      } catch (e) {
        debugPrint("AUTH: Error in notifyListeners: $e");
      }
    });
  }

  // Constructor to check authentication state
  AuthProvider() {
    debugPrint("AUTH: Initializing AuthProvider");
    _initAuthState();
  }

  // Initialize auth state and load user claim
  Future<void> _initAuthState() async {
    debugPrint("AUTH: Initializing auth state");

    // First check for any persisted Google sign-in state in case the app was killed during sign-in
    await _checkPersistedGoogleSignInState();

    _isAuthenticated = await _authService.isLoggedIn();
    debugPrint("AUTH: Initial authentication state: $_isAuthenticated");
    if (_isAuthenticated) {
      _userId = await _authService.getUserId();
      debugPrint("AUTH: User ID loaded: $_userId");
    }
    _safeNotifyListeners();
  }

  // Check if there was a Google sign-in in progress when the app was closed
  Future<void> _checkPersistedGoogleSignInState() async {
    try {
      final inProgress =
          await _secureStorage.read(key: 'google_signin_in_progress');
      final email = await _secureStorage.read(key: 'google_signin_email');

      if (inProgress == 'true' && email != null) {
        debugPrint(
            "AUTH: Restoring Google sign-in in progress for email: $email");
        _isGoogleSignInInProgress = true;
        _email = email;
        // Don't restore immediately to avoid race conditions
        // The user will need to manually retry or cancel
      }
    } catch (e) {
      debugPrint("AUTH: Error checking persisted Google sign-in state: $e");
    }
  }

  // Google sign-in method - COMPLETELY REWRITTEN to fix race conditions
  Future<bool> signInWithGoogle() async {
    // Track if timeout has occurred
    bool timeoutOccurred = false;
    Timer? timeoutTimer;

    debugPrint("Log_Auth_flow: ---- STARTING GOOGLE SIGN-IN FLOW ----");

    try {
      // Check if we're already in the middle of a sign-in process
      if (_isGoogleSignInInProgress) {
        debugPrint(
            "Log_Auth_flow: Google sign-in already in progress, ignoring new request");
        return false;
      }

      debugPrint(
          "Log_Auth_flow: Pre-emptively signing out from previous Google session");
      try {
        await _googleSignIn.signOut();
        debugPrint("Log_Auth_flow: Pre-emptive Google sign-out completed");
      } catch (e) {
        debugPrint(
            "Log_Auth_flow: Error during pre-emptive Google sign-out: $e");
        // Continue anyway - this is just to ensure a clean slate
      }

      // IMPORTANT: Set flag synchronously BEFORE any async operations to block router redirects
      _isGoogleSignInInProgress = true;
      _error = null;
      debugPrint(
          "Log_Auth_flow: Setting Google sign-in in progress flag to TRUE");

      // ENHANCEMENT: Immediate notification to block router redirects before next frame
      notifyListeners();
      debugPrint(
          "Log_Auth_flow: 🚫 BLOCKING ALL ROUTER REDIRECTS - Google sign-in starting");

      // Persist the sign-in in progress state in case app is killed
      await _secureStorage.write(
          key: 'google_signin_in_progress', value: 'true');
      debugPrint(
          "Log_Auth_flow: Persisted Google sign-in state to secure storage");

      // Add a small delay to ensure redirects are blocked
      await Future.delayed(const Duration(milliseconds: 500));
      debugPrint("Log_Auth_flow: Added delay to ensure redirects are blocked");

      // ENHANCEMENT: Set up a pre-resume flag to catch app lifecycle transitions
      // This flag will be checked when the app resumes from the Google sign-in native UI
      await _secureStorage.write(
          key: 'expecting_google_signin_resume', value: 'true');
      debugPrint("Log_Auth_flow: Set flag to expect resume from Google UI");

      debugPrint("Log_Auth_flow: About to show Google account picker UI");

      // FIXED: Set up a timeout that doesn't clear Google sign-in state immediately
      // Instead it sets a flag that we can check later
      debugPrint(
          "Log_Auth_flow: Setting up 45-second timeout for Google sign-in");
      timeoutTimer = Timer(const Duration(seconds: 45), () {
        debugPrint(
            "Log_Auth_flow: ⏰ Google sign  -in timeout triggered after 45 seconds");
        timeoutOccurred = true;

        // Just set a flag - don't clear state or complete completer yet
        debugPrint("Log_Auth_flow: Setting timeout flag to true");

        // CRITICAL FIX: Don't call notifyListeners during timeout as it might trigger navigation
        // Update UI to show timeout message
        _error = 'Sign-in is taking longer than expected. Please wait...';
        // _safeNotifyListeners(); // Commented out to prevent navigation
        debugPrint(
            "Log_Auth_flow: Timeout error set but not notified to prevent navigation");
      });

      // Start the sign-in process with a separate try-catch
      debugPrint(
          "Log_Auth_flow: Calling Google sign-in method - app may go to background now");
      GoogleSignInAccount? googleUser;

      try {
        // ENHANCEMENT: Set a marker right before the critical sign-in call that causes app to go to background
        await _secureStorage.write(
            key: 'google_signin_native_ui_starting', value: 'true');

        // This is the call that triggers the native UI and causes app to background
        googleUser = await _googleSignIn.signIn();

        // ENHANCEMENT: Immediately mark that we've returned from native UI
        await _secureStorage.write(
            key: 'google_signin_native_ui_starting', value: 'false');
        await _secureStorage.write(
            key: 'expecting_google_signin_resume', value: 'false');

        debugPrint("Log_Auth_flow: Google sign-in completed successfully");
      } catch (signInError) {
        debugPrint(
            "Log_Auth_flow: 🛑 Google sign-in threw exception: $signInError");

        // ENHANCEMENT: Mark that we've returned from native UI
        await _secureStorage.write(
            key: 'google_signin_native_ui_starting', value: 'false');
        await _secureStorage.write(
            key: 'expecting_google_signin_resume', value: 'false');

        // Cancel timeout timer if it's still active
        if (timeoutTimer != null && timeoutTimer.isActive) {
          timeoutTimer.cancel();
          debugPrint("Log_Auth_flow: Cancelled timeout timer after error");
        }

        // Provide more specific error message for common errors
        if (signInError.toString().contains("network_error") ||
            signInError.toString().contains("ApiException: 7")) {
          _error =
              'Network error during sign-in. Please check your internet connection.';
          debugPrint("Log_Auth_flow: Network error detected");
        } else if (signInError.toString().contains("canceled")) {
          _error = 'Sign-in was canceled.';
          debugPrint("Log_Auth_flow: User cancelled sign-in");
        } else {
          _error = 'Google sign-in failed: ${signInError.toString()}';
          debugPrint(
              "Log_Auth_flow: Other sign-in error: ${signInError.toString()}");
        }

        // Clear Google sign-in state
        await _clearGoogleSignInStateSync();
        debugPrint("Log_Auth_flow: Cleared Google sign-in state after error");

        return false;
      }

      // Cancel timeout timer if it's still active
      if (timeoutTimer != null && timeoutTimer.isActive) {
        timeoutTimer.cancel();
        debugPrint(
            "Log_Auth_flow: Cancelled timeout timer after sign-in completed");
      }

      // CRITICAL FIX: Check if timeout occurred
      if (timeoutOccurred) {
        debugPrint(
            "Log_Auth_flow: ⚠️ Timeout occurred before Google sign-in completed");
        _error = 'Sign-in timed out. Please try again.';
        await _clearGoogleSignInStateSync();
        _safeNotifyListeners();
        return false;
      }

      // Store the Google user
      _googleUser = googleUser;

      // Check if user cancelled
      if (_googleUser == null) {
        debugPrint("Log_Auth_flow: Google sign-in was cancelled by user");
        _error = 'Google sign-in was cancelled';

        // Use the helper method to clear Google sign-in state
        await _clearGoogleSignInStateSync();
        _safeNotifyListeners();

        return false;
      }

      // Check if user cancelled
      if (_googleUser == null) {
        debugPrint("Log_Auth_flow: Google sign-in was cancelled by user");
        _error = 'Google sign-in was cancelled';

        // Use the helper method to clear Google sign-in state
        _clearGoogleSignInState();
        _safeNotifyListeners();

        debugPrint("Log_Auth_flow: Returning false after user cancellation");
        return false;
      }
      debugPrint("Log_Auth_flow: User selected a Google account");

      debugPrint(
          "Log_Auth_flow: User selected a Google account: ${_googleUser!.email}");
      _email = _googleUser!.email;
      debugPrint("Log_Auth_flow: Selected Google account email: $_email");

      // Persist email in case app is killed
      await _secureStorage.write(key: 'google_signin_email', value: _email);
      debugPrint("Log_Auth_flow: Persisted Google email to secure storage");

      // Set loading state before backend call
      _isLoading = true;
      _safeNotifyListeners();
      debugPrint("Log_Auth_flow: Set loading state to true before API call");
      debugPrint("Log_Auth_flow: Calling backend to verify email");

      // Authenticate with backend with timeout - REDUCED to 10 seconds for better UX
      debugPrint("Log_Auth_flow: Starting API call with 10-second timeout");
      bool success = false;
      try {
        success =
            await _authService.authenticateWithSelectedEmail(_email!).timeout(
          const Duration(seconds: 300),
          onTimeout: () {
            debugPrint(
                "Log_Auth_flow: Backend authentication timed out after 300 seconds");
            _error =
                'Connection timed out. Please check your internet connection.';
            return false;
          },
        );
        debugPrint("Log_Auth_flow: API call completed with result: $success");
      } catch (apiError) {
        debugPrint("Log_Auth_flow: API call threw exception: $apiError");
        success = false;
        _error = 'Error connecting to server: ${apiError.toString()}';
      }

      _isLoading = false;
      debugPrint("Log_Auth_flow: Set loading state to false after API call");

      if (!success) {
        debugPrint("Log_Auth_flow: Backend authentication failed");
        // Use the error from auth service if available
        if (_error == null && _authService.lastError != null) {
          _error = _authService.lastError;
          debugPrint("Log_Auth_flow: Error from auth service: $_error");
        } else if (_error == null) {
          _error = 'Authentication failed with Google account';
          debugPrint("Log_Auth_flow: Using default error message");
        }

        // Clear Google sign-in state
        await _clearGoogleSignInStateSync();
        _safeNotifyListeners();

        debugPrint("Log_Auth_flow: Returning false after backend auth failure");
        return false;
      }

      debugPrint(
          "Log_Auth_flow: ✅ Backend auth success, preparing to navigate to OTP screen");

      // Keep the redirect block active during navigation
      if (navigatorKey.currentContext != null) {
        debugPrint(
            "Log_Auth_flow: Navigator context found, attempting navigation");

        // CRITICAL FIX: Store current route to return to after authentication
        String currentRoute = '/login'; // Safe default
        try {
          // Use a safer method to get the current route
          final router = GoRouter.of(navigatorKey.currentContext!);
          currentRoute =
              router.routerDelegate.currentConfiguration.uri.toString();
        } catch (e) {
          debugPrint(
              "Log_Auth_flow: Could not get current route safely, using default: $e");
        }
        debugPrint(
            "Log_Auth_flow: Current route before navigation: $currentRoute");

        // Use pushNamed instead of goNamed to preserve history stack
        try {
          debugPrint(
              "Log_Auth_flow: Using pushNamed to navigate to verifyOtp with email: $_email");

          // IMPORTANT: Keep the Google sign-in flag active during navigation
          // but clear it AFTER navigation is complete
          GoRouter.of(navigatorKey.currentContext!).pushNamed(
            'verifyOtp',
            queryParameters: {
              'googleEmail': _email,
              'returnTo': currentRoute, // Pass the return route as a parameter
            },
          );
          debugPrint("Log_Auth_flow: Navigation call completed");

          // Add a delay to ensure navigation completes before resetting the flag
          debugPrint(
              "Log_Auth_flow: Adding 1-second delay before resetting flags");
          await Future.delayed(const Duration(milliseconds: 1000));
          debugPrint("Log_Auth_flow: Delay completed, now resetting flags");

          // Reset flag and notify AFTER navigation completes
          await _clearGoogleSignInStateSync();
          _safeNotifyListeners();

          debugPrint(
              "Log_Auth_flow: Google sign-in process completed successfully");
          return true;
        } catch (navError) {
          debugPrint("Log_Auth_flow: Navigation error: $navError");
          // Clear Google sign-in state on navigation error
          await _clearGoogleSignInStateSync();
          _error = 'Navigation error: ${navError.toString()}';
          _safeNotifyListeners();
          return false;
        }
      } else {
        debugPrint(
            "Log_Auth_flow: ⚠️ Navigator context is null, cannot navigate");
        // Reset flag if navigation fails
        await _clearGoogleSignInStateSync();
        _safeNotifyListeners();
        debugPrint(
            "Log_Auth_flow: Returning false due to missing navigator context");
        return false;
      }
    } catch (e) {
      // Handle any unexpected errors
      debugPrint("Log_Auth_flow: ❌ Caught exception during Google sign-in: $e");
      _error = 'Google sign-in error: ${e.toString()}';
      _isLoading = false;

      // Clear Google sign-in state
      _clearGoogleSignInState();
      _safeNotifyListeners();

      debugPrint("Log_Auth_flow: Notified listeners after error");

      debugPrint("Log_Auth_flow: Returning false after handling exception");
      return false;
    }
  }

  Future<bool> signInWithPhone(String phoneNumber) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Add timeout to prevent indefinite loading
      final success =
          await _authService.authenticationWithPhone(phoneNumber).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint("AUTH: Phone authentication timed out");
          _error = 'Connection timed out. Please try again.';
          return false;
        },
      );

      if (success) {
        // Store the phone number but don't mark as fully authenticated yet
        // User still needs to verify OTP
        _phoneNumber = phoneNumber;
      } else {
        // Use the error from auth service if available
        if (_error == null && _authService.lastError != null) {
          _error = _authService.lastError;
        } else {
          _error ??=
              'Authentication failed. Please check your phone number and try again.';
        }
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = 'Error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint("AUTH: Starting OTP verification with code: [masked]");

      // Add timeout to OTP verification
      final success = await _authService.verifyOtp(otp).timeout(
        const Duration(seconds: 300),
        onTimeout: () {
          debugPrint("AUTH: OTP verification timed out");
          _error = 'Connection timed out. Please try again.';
          return false;
        },
      );

      debugPrint("AUTH: OTP verification result: $success");

      if (success) {
        // Double-check that session_id is actually present
        final sessionId = await _authService.getSessionId();
        if (sessionId != null && sessionId.isNotEmpty) {
          _isAuthenticated = true;
          // Get user ID from secure storage
          _userId = await _authService.getUserId();
          // Reset Google sign-in flag on successful authentication
          _isGoogleSignInInProgress = false;

          debugPrint(
              "AUTH: Authentication successful! SessionId exists and user is authenticated");
        } else {
          // Session ID wasn't saved properly
          debugPrint(
              "AUTH: Warning - API returned success but no session ID was stored");
          _error =
              'Authentication succeeded but session was not stored correctly';
          _isAuthenticated = false;
          _isGoogleSignInInProgress = false;

          // Try to get error from auth service
          if (_authService.lastError != null) {
            _error = _authService.lastError;
            debugPrint("AUTH: Using error from auth service: $_error");
          }

          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        // Use the error from auth service if available
        if (_error == null && _authService.lastError != null) {
          _error = _authService.lastError;
        } else {
          _error ??=
              'OTP verification failed. Please check the code and try again.';
        }
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = 'Error: ${e.toString()}';
      // Reset flag on error
      _isGoogleSignInInProgress = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> refreshOtp(String identifier) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Add timeout to refreshOtp call
      final success = await _authService.refreshOtp(identifier).timeout(
        const Duration(seconds: 300),
        onTimeout: () {
          _error = 'Connection timed out. Please try again.';
          return false;
        },
      );

      if (!success) {
        // Use the error from auth service if available
        if (_error == null && _authService.lastError != null) {
          _error = _authService.lastError;
        } else {
          _error ??= 'Failed to refresh OTP. Please try again.';
        }
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = 'Error: ${e.toString()}';
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
      debugPrint(
          "AUTH: Authentication check - User is logged in, ID: $_userId");
    } else {
      _userId = null;
      debugPrint("AUTH: Authentication check - User is not logged in");
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

  // Reset Google sign-in progress flag - called in error cases
  Future<void> resetGoogleSignInProgress() async {
    if (_isGoogleSignInInProgress) {
      debugPrint("AUTH: Resetting GoogleSignInProgress to FALSE");
      _isGoogleSignInInProgress = false;

      // Clear persisted state
      try {
        await _secureStorage.delete(key: 'google_signin_in_progress');
        await _secureStorage.delete(key: 'google_signin_email');
      } catch (e) {
        debugPrint("AUTH: Error clearing persisted Google sign-in state: $e");
      }

      // Use safe notify to avoid widget tree lock issues
      _safeNotifyListeners();
    }
  }

  // Helper method to clear Google sign-in state
  void _clearGoogleSignInState() {
    debugPrint("Log_Auth_flow: Clearing Google sign-in state");
    _isGoogleSignInInProgress = false;

    // Clear persisted state asynchronously
    Future.microtask(() async {
      try {
        await _secureStorage.delete(key: 'google_signin_in_progress');
        await _secureStorage.delete(key: 'google_signin_email');
        debugPrint(
            "Log_Auth_flow: Successfully cleared persisted Google sign-in state");
      } catch (e) {
        debugPrint(
            "Log_Auth_flow: Error clearing persisted Google sign-in state: $e");
      }
    });
  }

  // Helper method to clear Google sign-in state synchronously (awaitable)
  Future<void> _clearGoogleSignInStateSync() async {
    debugPrint("Log_Auth_flow: Clearing Google sign-in state synchronously");
    _isGoogleSignInInProgress = false;

    try {
      await _secureStorage.delete(key: 'google_signin_in_progress');
      await _secureStorage.delete(key: 'google_signin_email');
      debugPrint(
          "Log_Auth_flow: Successfully cleared persisted Google sign-in state");
    } catch (e) {
      debugPrint(
          "Log_Auth_flow: Error clearing persisted Google sign-in state: $e");
    }
  }
}
