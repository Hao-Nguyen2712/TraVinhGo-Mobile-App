import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/providers/auth_provider.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final TextEditingController _phoneController = TextEditingController();
  String? _phoneError;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Store the previous route for back navigation
  String? _previousRoute;
  bool _isBackNavigationAvailable = false;

  // Key to track if we're resuming from Google sign-in
  static const String _previousRouteKey = 'previous_route_before_login';
  static const String _resumingFromGoogleSignInKey =
      'resuming_from_google_signin';

  @override
  void initState() {
    super.initState();
    // Register for lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Load previous route from storage
    _loadPreviousRoute();

    // Check if Google sign-in is in progress
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isGoogleSignInInProgress) {
        debugPrint(
            "LOGIN: Detected Google sign-in in progress during initialization");
        // Set flag that we're resuming from Google sign-in
        _secureStorage.write(key: _resumingFromGoogleSignInKey, value: 'true');
      }

      // Get current route and ensure it's the login page
      _ensureLoginPageIsCurrentRoute();

      // Check the query parameters for returnTo - this takes priority for back navigation
      try {
        // Extract any returnTo parameter from the current route
        final router = GoRouter.of(context);
        final returnTo = router.routerDelegate.currentConfiguration.uri
            .queryParameters['returnTo'];

        if (returnTo != null && returnTo.isNotEmpty) {
          // If we have a returnTo parameter, use that as the previous route
          setState(() {
            _previousRoute = Uri.decodeComponent(returnTo);
            _isBackNavigationAvailable = true;
          });
          debugPrint(
              "LOGIN: Using returnTo parameter for back navigation: $_previousRoute");

          // Save it for persistence
          _savePreviousRoute(_previousRoute!);
        }
      } catch (e) {
        debugPrint("LOGIN: Error parsing returnTo parameter: $e");
      }
    });
  }

  // Load the previous route before navigating to login
  Future<void> _loadPreviousRoute() async {
    try {
      final savedRoute = await _secureStorage.read(key: _previousRouteKey);
      if (savedRoute != null &&
          savedRoute.isNotEmpty &&
          savedRoute != '/login') {
        setState(() {
          _previousRoute = savedRoute;
          _isBackNavigationAvailable = true;
        });
        debugPrint("LOGIN: Loaded previous route: $_previousRoute");
      }
    } catch (e) {
      debugPrint("LOGIN: Error loading previous route: $e");
    }
  }

  // Save the route before navigating to login
  Future<void> _savePreviousRoute(String route) async {
    // Don't save login-related routes
    if (route == '/login' || route.startsWith('/verify-otp')) {
      return;
    }

    try {
      // IMPORTANT: Save the complete route including any query parameters
      await _secureStorage.write(key: _previousRouteKey, value: route);
      debugPrint("LOGIN: Saved previous route: $route");
    } catch (e) {
      debugPrint("LOGIN: Error saving previous route: $e");
    }
  }

  // Navigate back to previous route if available
  void _navigateBack() {
    if (_previousRoute != null && _isBackNavigationAvailable) {
      debugPrint("LOGIN: Navigating back to: $_previousRoute");

      // Check if we're returning to one of the tab routes
      final tabRoutes = ['/home', '/map', '/events', '/favorites', '/profile'];
      final isTabRoute = tabRoutes.any((route) => _previousRoute == route);

      if (isTabRoute) {
        // If returning to a tab route, make sure we set the correct tab
        debugPrint("LOGIN: Returning to tab route: $_previousRoute");
        context.go(_previousRoute!);
      } else {
        // For non-tab routes, just go to the route directly
        debugPrint("LOGIN: Returning to non-tab route: $_previousRoute");
        context.go(_previousRoute!);
      }
    } else {
      // Default to home if no previous route
      debugPrint("LOGIN: No previous route, going to home");
      context.go('/home');
    }
  }

  // Ensure the router reflects login page as the current URI
  void _ensureLoginPageIsCurrentRoute() {
    if (!mounted) return;

    try {
      final router = GoRouter.of(context);
      final currentLocation =
          router.routerDelegate.currentConfiguration.uri.toString();

      // If we're not on login page and not in Google sign-in, update router
      if (!currentLocation.startsWith('/login')) {
        debugPrint(
            "LOGIN: Current URI is not login ($currentLocation), updating router state");
        router.go('/login');
      }

      debugPrint(
          "LOGIN: Current route after check: ${router.routerDelegate.currentConfiguration.uri}");
    } catch (e) {
      debugPrint("LOGIN: Error checking/updating current route: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint("Log_Auth_flow: LOGIN - App lifecycle state changed to $state");
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (state == AppLifecycleState.resumed) {
      // App resumed from background
      debugPrint("Log_Auth_flow: LOGIN - App resumed from background");
      debugPrint(
          "Log_Auth_flow: LOGIN - Checking Google sign-in progress flag: ${authProvider.isGoogleSignInInProgress}");

      // Check if we're resuming from Google sign-in
      _secureStorage.read(key: _resumingFromGoogleSignInKey).then((value) {
        final isResumingFromGoogleSignIn = value == 'true';
        if (isResumingFromGoogleSignIn) {
          debugPrint(
              "LOGIN: Detected resume from Google sign-in, ensuring we're on login page");
          // Clear the flag
          _secureStorage.delete(key: _resumingFromGoogleSignInKey);

          // Make sure we're on the login page after resume
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _ensureLoginPageIsCurrentRoute();
          });
        }
      });

      if (authProvider.isGoogleSignInInProgress) {
        debugPrint(
            "Log_Auth_flow: LOGIN - Google sign-in still in progress after resume");

        // ENHANCEMENT: Add more robust check of current location
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          try {
            // Use a stronger approach to check and ensure we're on the login page
            final router = GoRouter.of(context);
            final currentLocation =
                router.routerDelegate.currentConfiguration.uri.toString();
            debugPrint(
                "Log_Auth_flow: LOGIN - Current route after resume: $currentLocation");

            // If somehow we're not on the login page, force navigation back to it
            if (!currentLocation.startsWith('/login')) {
              debugPrint(
                  "Log_Auth_flow: LOGIN - ⚠️ Not on login page after resume! Current: $currentLocation");
              debugPrint(
                  "Log_Auth_flow: LOGIN - Forcing navigation back to login page");

              // Use go to ensure we reflect the login URI
              router.go('/login');
            } else {
              debugPrint(
                  "Log_Auth_flow: LOGIN - ✅ Correctly on login page after resume");
            }
          } catch (e) {
            debugPrint(
                "Log_Auth_flow: LOGIN - Error checking/fixing navigation: $e");
          }
        });
      } else {
        // Not in Google sign-in, normal resume
        debugPrint(
            "Log_Auth_flow: LOGIN - Regular app resume, not in Google sign-in flow");
      }
    } else if (state == AppLifecycleState.paused) {
      // App going to background - likely for Google sign-in
      debugPrint("Log_Auth_flow: LOGIN - App paused/going to background");
      debugPrint(
          "Log_Auth_flow: LOGIN - Google sign-in in progress: ${authProvider.isGoogleSignInInProgress}");

      if (authProvider.isGoogleSignInInProgress) {
        // Set flag that we'll be resuming from Google sign-in
        _secureStorage.write(key: _resumingFromGoogleSignInKey, value: 'true');

        debugPrint(
            "Log_Auth_flow: LOGIN - 🔒 App backgrounding with active Google sign-in");
        debugPrint("Log_Auth_flow: LOGIN - Setting up post-resume protection");
      }
    } else if (state == AppLifecycleState.inactive) {
      debugPrint("Log_Auth_flow: LOGIN - App becoming inactive");

      // ENHANCEMENT: Handle inactive state which can precede backgrounding
      if (authProvider.isGoogleSignInInProgress) {
        debugPrint("Log_Auth_flow: LOGIN - App inactive during Google sign-in");
      }
    } else if (state == AppLifecycleState.detached) {
      debugPrint("Log_Auth_flow: LOGIN - App detached");
    }
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    _phoneController.dispose();
    super.dispose();
  }

  void _handlePhoneSignIn() async {
    final phoneNumber = _phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      setState(() {
        _phoneError = AppLocalizations.of(context)!.phoneNumberRequired;
      });
      return;
    }

    // Basic phone number validation
    if (phoneNumber.length < 10) {
      setState(() {
        _phoneError = AppLocalizations.of(context)!.enterValidPhoneNumber;
      });
      return;
    }

    setState(() {
      _phoneError = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Show loading overlay
    _showLoadingOverlay();

    final success = await authProvider.signInWithPhone(phoneNumber);

    // Hide loading overlay
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (success) {
      if (mounted) {
        // Navigate to OTP verification screen using GoRouter
        context.goNamed(
          'verifyOtp',
          queryParameters: {'phoneNumber': phoneNumber},
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              authProvider.error ?? AppLocalizations.of(context)!.loginFailed),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // Show loading overlay
  void _showLoadingOverlay() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Prevent closing with back button
          child: Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Custom loading animation
                    SizedBox(
                      width: 15.w,
                      height: 15.w,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer rotating circle
                          SizedBox(
                            width: 15.w,
                            height: 15.w,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary.withAlpha(179),
                              ),
                              strokeWidth: 3,
                            ),
                          ),
                          // Inner rotating circle (opposite direction)
                          SizedBox(
                            width: 10.w,
                            height: 10.w,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary,
                              ),
                              strokeWidth: 5,
                            ),
                          ),
                          // Center dot
                          Container(
                            width: 4.w,
                            height: 4.w,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 3.h),
                    // Loading text
                    Text(
                      AppLocalizations.of(context)!.authenticating,
                      style: GoogleFonts.montserrat(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    // Subtext
                    Text(
                      AppLocalizations.of(context)!.verifyingCredentials,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 11.sp,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Handle Google sign-in
  void _handleGoogleSignIn() async {
    // Prevent default actions that might interfere with the sign-in flow
    debugPrint(
        "Log_Auth_flow: LOGIN - Google sign-in button clicked - starting protected flow");

    // Important: Use a synchronous notification to immediately block router redirects
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    debugPrint(
        "Log_Auth_flow: LOGIN - Current route before Google sign-in: ${GoRouter.of(context).routerDelegate.currentConfiguration.uri}");

    try {
      // Set flag that we're starting Google sign-in
      await _secureStorage.write(
          key: _resumingFromGoogleSignInKey, value: 'true');

      // ENHANCEMENT: Store the current route to ensure we can return here
      final currentRoute = GoRouter.of(context)
          .routerDelegate
          .currentConfiguration
          .uri
          .toString();
      debugPrint("Log_Auth_flow: LOGIN - Saved current route: $currentRoute");

      // Call signInWithGoogle() which will:
      // 1. First synchronously block router redirects
      // 2. Then show Google account picker
      // 3. Show loading overlay during API call
      // 4. Navigate to OTP upon success
      debugPrint(
          "Log_Auth_flow: LOGIN - Starting Google sign-in process via AuthProvider");

      final success = await authProvider.signInWithGoogle();

      // Clear resuming flag since we're done
      await _secureStorage.write(
          key: _resumingFromGoogleSignInKey, value: 'false');

      debugPrint(
          "Log_Auth_flow: LOGIN - Google sign-in process returned: $success");

      if (!success && mounted) {
        debugPrint("Log_Auth_flow: LOGIN - Google sign-in failed");
        debugPrint(
            "Log_Auth_flow: LOGIN - Error message: ${authProvider.error}");

        // Make sure we're on the login page after failure
        _ensureLoginPageIsCurrentRoute();

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(authProvider.error ??
              AppLocalizations.of(context)!.googleSignInFailed),
          backgroundColor: Colors.red,
        ));
      } else if (success) {
        debugPrint(
            "Log_Auth_flow: LOGIN - Google sign-in succeeded, navigation handled by provider");
      }
      // Note: On success, navigation happens in the provider
    } catch (e) {
      debugPrint("Log_Auth_flow: LOGIN - Exception during Google sign-in: $e");

      // Clear resuming flag on error
      await _secureStorage.write(
          key: _resumingFromGoogleSignInKey, value: 'false');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              AppLocalizations.of(context)!.googleSignInError(e.toString())),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      debugPrint("Log_Auth_flow: LOGIN - Google sign-in handler completed");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Store the current route info but only once when widget first builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // Check the referring route from the router history
        final router = GoRouter.of(context);
        final location =
            router.routerDelegate.currentConfiguration.uri.toString();

        // Look for returnTo parameter which indicates where to go after successful login
        final returnTo = router.routerDelegate.currentConfiguration.uri
            .queryParameters['returnTo'];
        if (returnTo != null && returnTo.isNotEmpty && _previousRoute == null) {
          debugPrint("LOGIN: Found returnTo parameter: $returnTo");
          _savePreviousRoute(Uri.decodeComponent(returnTo));
          setState(() {
            _previousRoute = Uri.decodeComponent(returnTo);
            _isBackNavigationAvailable = true;
          });
        }

        debugPrint("LOGIN: Current location: $location");
      } catch (e) {
        debugPrint("LOGIN: Error getting navigation info: $e");
      }
    });

    // Get screen metrics for responsive layout
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    // Calculate header height - smaller when keyboard is visible
    final headerHeight = isKeyboardVisible
        ? screenHeight * 0.22 // Smaller header when keyboard is visible
        : screenHeight * 0.32; // Normal header height

    return WillPopScope(
      // Handle system back button to navigate to previous route
      onWillPop: () async {
        if (_isBackNavigationAvailable) {
          _navigateBack();
          return false; // Don't pop, we'll handle navigation
        }
        return true; // Allow default pop behavior
      },
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final colorScheme = Theme.of(context).colorScheme;
          return Scaffold(
            // Allow the screen to resize when keyboard appears
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: [
                // Main content
                Column(
                  children: [
                    // Green curved header with logo - adaptive height
                    ClipPath(
                      clipper: CurvedBottomClipper(),
                      child: Container(
                        color: colorScheme.primary, // Primary green color
                        height: headerHeight,
                        width: double.infinity,
                        child: SafeArea(
                          child: Stack(
                            children: [
                              // Back button
                              Positioned(
                                top: 10,
                                left: 10,
                                child: InkWell(
                                  onTap: _isBackNavigationAvailable
                                      ? _navigateBack
                                      : null,
                                  child: Container(
                                    padding: EdgeInsets.all(2.w),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isBackNavigationAvailable
                                          ? colorScheme.onPrimary
                                          : colorScheme.onPrimary
                                              .withOpacity(0.5),
                                    ),
                                    child: Icon(
                                      Icons.arrow_back_ios_new,
                                      color: _isBackNavigationAvailable
                                          ? colorScheme.onSurfaceVariant
                                          : colorScheme.onSurfaceVariant
                                              .withOpacity(0.5),
                                      size: 14.sp,
                                    ),
                                  ),
                                ),
                              ),
                              // Logo
                              Center(
                                child: LayoutBuilder(
                                    builder: (context, constraints) {
                                  // Calculate logo size based on available height
                                  final availableHeight =
                                      constraints.maxHeight - 4.h;
                                  final logoSize = math.min(
                                      isKeyboardVisible ? 20.w : 35.w,
                                      availableHeight);

                                  return Padding(
                                    padding: EdgeInsets.only(top: 1.h),
                                    child: Image.asset(
                                      'assets/images/auth/logo.png',
                                      height: logoSize,
                                      width: logoSize,
                                      fit: BoxFit.contain,
                                      // Use placeholder if logo not available
                                      errorBuilder: (ctx, obj, stack) => Icon(
                                        Icons.landscape,
                                        color: colorScheme.onPrimary,
                                        size: 18.w,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 1.h), // Reduced spacing after header
                    // Scrollable content area that adjusts for keyboard
                    Expanded(
                      child: GestureDetector(
                        // Dismiss keyboard when tapping outside input fields
                        onTap: () => FocusScope.of(context).unfocus(),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 1.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Sign in title
                              Text(
                                AppLocalizations.of(context)!.signIn,
                                style: GoogleFonts.montserrat(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 1.5.h),
                              // Subtitle
                              Text(
                                AppLocalizations.of(context)!.signInToContinue,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14.sp,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 3.h),

                              // Phone number field
                              Padding(
                                padding: EdgeInsets.all(1.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(left: 4.w),
                                      child: RichText(
                                        text: TextSpan(
                                          text: AppLocalizations.of(context)!
                                              .phoneNumber,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                            color: colorScheme.onSurface,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: '*',
                                              style: TextStyle(
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 1.h),
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceVariant,
                                        borderRadius:
                                            BorderRadius.circular(8.sp),
                                        border: _phoneError != null
                                            ? Border.all(
                                                color: colorScheme.error,
                                                width: 1.0)
                                            : null,
                                      ),
                                      child: TextField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        onChanged: (value) {
                                          // Clear error when user types
                                          if (_phoneError != null) {
                                            setState(() {
                                              _phoneError = null;
                                            });
                                          }
                                        },
                                        decoration: InputDecoration(
                                          hintText:
                                              AppLocalizations.of(context)!
                                                  .yourPhoneNumber,
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 5.w,
                                            vertical: 2.h,
                                          ),
                                          suffixIcon: _phoneController
                                                  .text.isNotEmpty
                                              ? IconButton(
                                                  icon: Icon(Icons.clear,
                                                      size: 14.sp),
                                                  onPressed: () {
                                                    setState(() {
                                                      _phoneController.clear();
                                                      _phoneError = null;
                                                    });
                                                  },
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Error message for phone number
                              if (_phoneError != null)
                                Padding(
                                  padding: EdgeInsets.only(left: 5.w),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _phoneError!,
                                      style: TextStyle(
                                        color: colorScheme.error,
                                        fontSize: 10.sp,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ),
                              SizedBox(height: 3.h),

                              // Continue button
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5.w),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 6.h,
                                  child: ElevatedButton(
                                    onPressed: _handlePhoneSignIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20.sp),
                                      ),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context)!
                                          .continueButton,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 3.h),

                              // Always show "Or continue with" section
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5.w),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: colorScheme.outline
                                            .withOpacity(0.5),
                                        thickness: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 4.w),
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .orContinueWith,
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: colorScheme.outline
                                            .withOpacity(0.5),
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 2.5.h),

                              // Google sign-in button - always visible
                              InkWell(
                                onTap: _handleGoogleSignIn,
                                child: Container(
                                  width: 55.w,
                                  height: 6.h,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(20.sp),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            colorScheme.shadow.withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    border: Border.all(
                                      color:
                                          colorScheme.outline.withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/auth/search.png',
                                        height: 5.w,
                                        width: 5.w,
                                      ),
                                      SizedBox(width: 3.w),
                                      Text(
                                        AppLocalizations.of(context)!.google,
                                        style: GoogleFonts.montserrat(
                                          color: colorScheme.onSurface,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Add extra padding at the bottom to ensure everything is visible
                              SizedBox(
                                height: keyboardHeight > 0
                                    ? keyboardHeight
                                    : MediaQuery.of(context).padding.bottom +
                                        2.h,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Loading overlay - only shown when authProvider.isLoading is true
                if (authProvider.isLoading)
                  Container(
                    color: colorScheme.scrim,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12.sp),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Custom loading animation
                            SizedBox(
                              width: 15.w,
                              height: 15.w,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer rotating circle
                                  SizedBox(
                                    width: 15.w,
                                    height: 15.w,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        colorScheme.primary.withAlpha(179),
                                      ),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                  // Inner rotating circle (opposite direction)
                                  SizedBox(
                                    width: 10.w,
                                    height: 10.w,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        colorScheme.primary,
                                      ),
                                      strokeWidth: 5,
                                    ),
                                  ),
                                  // Center dot
                                  Container(
                                    width: 4.w,
                                    height: 4.w,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 3.h),
                            // Loading text
                            Text(
                              AppLocalizations.of(context)!.authenticating,
                              style: GoogleFonts.montserrat(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                            SizedBox(height: 1.h),
                            // Subtext
                            Text(
                              AppLocalizations.of(context)!
                                  .verifyingCredentials,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 11.sp,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Custom clipper for the curved bottom
class CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Calculate curve height as a smaller percentage of container height (8%)
    final curveHeight = size.height * 0.08;
    // Ensure curve offset doesn't exceed container bounds
    final safeOffset = math.min(curveHeight, size.height * 0.12);

    // Start from top-left corner
    path.lineTo(0, size.height - safeOffset);

    // Use a gentler quadratic Bezier curve for the entire width
    path.quadraticBezierTo(
      size.width / 2, // Control point x at center
      size.height +
          (safeOffset *
              0.1), // Control point y slightly below for gentler curve
      size.width, // End point x at right edge
      size.height - safeOffset, // End point y same as start
    );

    // Complete the path
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
