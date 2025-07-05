import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/providers/auth_provider.dart';
import 'package:travinhgo/services/auth_service.dart';
import 'package:travinhgo/widget/status_dialog.dart';
import 'package:travinhgo/router/app_router.dart'; // Import to access redirect path logic
import 'package:travinhgo/utils/constants.dart'; // Fix import path
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? phoneNumber;
  final String? googleEmail;

  const OtpVerificationScreen({
    super.key,
    this.phoneNumber,
    this.googleEmail,
  });

  @override
  // ignore: no_logic_in_create_state
  State<OtpVerificationScreen> createState() {
    debugPrint(
        "Log_Auth_flow: OTP - Creating OTP verification screen state with phoneNumber: $phoneNumber, googleEmail: $googleEmail");
    return _OtpVerificationScreenState();
  }
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  final TextEditingController _fullOtpController = TextEditingController();
  final FocusNode _fullOtpFocusNode = FocusNode();

  bool _isLoading = false;
  Timer? _resendTimer;
  int _timeLeft = 300; // 5 minutes in seconds
  String? _otpError;
  bool _otpSubmitted = false; // Track if OTP has been submitted
  Timer? _clipboardCheckTimer; // Timer for checking clipboard

  @override
  void initState() {
    super.initState();
    debugPrint(
        "Log_Auth_flow: OTP - Screen initialized with phoneNumber: ${widget.phoneNumber}, googleEmail: ${widget.googleEmail}");

    // Start timer immediately
    _startResendTimer();

    // Start clipboard monitoring
    _startClipboardMonitoring();

    // Listen for changes in the hidden full OTP field
    _fullOtpController.addListener(_handleFullOtpChange);

    // Move ALL context access to post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Now it's safe to access context
      debugPrint(
          "Log_Auth_flow: OTP - Current route: ${ModalRoute.of(context)?.settings.name ?? 'unknown'}");

      // Check if Google sign-in is in progress
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isGoogleInProgress = authProvider.isGoogleSignInInProgress;
      debugPrint(
          "Log_Auth_flow: OTP - Post-frame callback, Google sign-in in progress: $isGoogleInProgress");

      try {
        final router = GoRouter.of(context);
        final currentLocation =
            router.routerDelegate.currentConfiguration.uri.toString();
        debugPrint(
            "Log_Auth_flow: OTP - Current route from GoRouter: $currentLocation");
      } catch (e) {
        debugPrint("Log_Auth_flow: OTP - Error getting current route: $e");
      }

      // Show message popup
      _showMessageSentPopup();
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _fullOtpController.removeListener(_handleFullOtpChange);
    _fullOtpController.dispose();
    _fullOtpFocusNode.dispose();
    _resendTimer?.cancel();
    _clipboardCheckTimer?.cancel(); // Cancel clipboard timer
    super.dispose();
  }

  void _showMessageSentPopup() {
    // Check if widget is still mounted before showing dialog
    if (!mounted) {
      debugPrint("OTP: Widget not mounted, skipping message popup");
      return;
    }

    try {
      final bool isGoogleAuth = widget.googleEmail != null;
      final String recipient =
          isGoogleAuth ? widget.googleEmail! : widget.phoneNumber ?? '';

      debugPrint(
          "OTP: Showing message sent popup for ${isGoogleAuth ? 'email' : 'phone'}: $recipient");

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Green icon container
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF158247),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    isGoogleAuth
                        ? Icons.email_outlined
                        : Icons.message_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  isGoogleAuth
                      ? AppLocalizations.of(context)!.checkYourEmail
                      : AppLocalizations.of(context)!.checkYourMessage,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Text(
                        isGoogleAuth
                            ? AppLocalizations.of(context)!.otpSentTo
                            : AppLocalizations.of(context)!
                                .otpSentToConfirmPhone,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      if (isGoogleAuth) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            recipient,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context)!.checkInboxToContinue,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // OK button
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF158247),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.ok,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint("OTP: Error showing message popup: $e");
    }
  }

  void _startResendTimer() {
    _timeLeft = 300; // 5 minutes
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String _formatTimeLeft() {
    final minutes = (_timeLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool get _isTimeExpired => _timeLeft <= 0;

  Future<void> _verifyOtp() async {
    // Prevent double submission
    if (_otpSubmitted) {
      debugPrint("Log_Auth_flow: OTP - Ignoring duplicate submission");
      return;
    }

    final otpCode = _otpControllers.map((controller) => controller.text).join();
    debugPrint("Log_Auth_flow: OTP - Verifying OTP code: $otpCode");
    debugPrint(
        "Log_Auth_flow: OTP - Authentication type: ${widget.googleEmail != null ? 'Google Email' : 'Phone'}");

    // Check if OTP is empty or incomplete
    if (otpCode.isEmpty || otpCode.length < 6) {
      debugPrint("Log_Auth_flow: OTP - Invalid OTP code entered");
      setState(() {
        _otpError = AppLocalizations.of(context)!.enterValidOtp;
      });
      return;
    }

    // Get the auth provider for state management
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    debugPrint(
        "Log_Auth_flow: OTP - Current Google sign-in in progress flag: ${authProvider.isGoogleSignInInProgress}");

    setState(() {
      _otpError = null;
      _isLoading = true;
      _otpSubmitted = true; // Mark as submitted
    });
    debugPrint(
        "Log_Auth_flow: OTP - Set loading state and marked OTP as submitted");

    try {
      debugPrint(
          "Log_Auth_flow: OTP - Sending verification request via AuthProvider");
      final success = await authProvider.verifyOtp(otpCode);
      debugPrint("Log_Auth_flow: OTP - Verification result: $success");

      // Reset submission flag if still mounted (in case of errors)
      if (mounted) {
        setState(() {
          _otpSubmitted = false;
        });
        debugPrint("Log_Auth_flow: OTP - Reset submission flag");
      }

      if (success) {
        debugPrint(
            "Log_Auth_flow: OTP - Verification successful, preparing navigation");
        debugPrint(
            "Log_Auth_flow: OTP - Authentication status: ${authProvider.isAuthenticated}");
        debugPrint(
            "Log_Auth_flow: OTP - Google sign-in in progress: ${authProvider.isGoogleSignInInProgress}");

        // Show success dialog before navigating to home screen
        if (mounted) {
          debugPrint("OTP: Showing success dialog");
          await StatusDialogs.showSuccessDialog(
            context: context,
            message: AppLocalizations.of(context)!.authSuccessful,
            onOkPressed: () {
              debugPrint("OTP: Success dialog dismissed, navigating back");
              Navigator.of(context).pop(); // Dismiss dialog

              // Get the closest GoRouter to access the redirect path
              final router = GoRouter.of(context);

              // Try to find the app router instance to get the redirect path
              _navigateAfterSuccess(context);
            },
          );
        }
      } else {
        debugPrint("OTP: Verification failed");

        if (mounted) {
          debugPrint("OTP: Showing error dialog");
          await StatusDialogs.showErrorDialog(
            context: context,
            message:
                authProvider.error ?? AppLocalizations.of(context)!.authFailed,
            onOkPressed: () {
              debugPrint("OTP: Error dialog dismissed");
              Navigator.of(context).pop(); // Dismiss dialog
              setState(() {
                _otpError = AppLocalizations.of(context)!.invalidOtp;
              });
            },
          );
        }
      }
    } catch (e) {
      debugPrint("OTP: Verification error: $e");

      if (mounted) {
        setState(() {
          _otpError = AppLocalizations.of(context)!.errorPrefix(e.toString());
          _otpSubmitted = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to navigate after successful OTP verification
  void _navigateAfterSuccess(BuildContext context) {
    debugPrint(
        "Log_Auth_flow: OTP - Starting navigation after successful verification");

    // Check if there's a saved return path in URL parameters
    final uri = GoRouterState.of(context).uri;
    final returnTo = uri.queryParameters['returnTo'];
    debugPrint("Log_Auth_flow: OTP - Current URI: ${uri.toString()}");
    debugPrint("Log_Auth_flow: OTP - Return path from URL: $returnTo");

    // Store current context before navigation for showing snackbar later
    final navigatorKey = GlobalKey<NavigatorState>();

    // IMPROVED: Check if returnTo is valid and not a login or verify-otp path
    if (returnTo != null &&
        returnTo.isNotEmpty &&
        !returnTo.startsWith('/login') &&
        !returnTo.startsWith('/verify-otp')) {
      debugPrint(
          "Log_Auth_flow: OTP - Found valid returnTo parameter in URL: $returnTo");
      debugPrint("Log_Auth_flow: OTP - Navigating to returnTo path");

      try {
        // Use go to replace the current page in history and show success message
        // We'll add a small delay to ensure the success notification appears after navigation is complete
        context.go(returnTo);

        // Add a small delay before showing the notification to ensure navigation completes
        Future.delayed(const Duration(milliseconds: 300), () {
          if (navigatorKey.currentContext != null) {
            showAuthSuccessNotification(navigatorKey.currentContext!);
          } else if (context.mounted) {
            showAuthSuccessNotification(context);
          }
        });

        debugPrint("Log_Auth_flow: OTP - Successfully navigated to $returnTo");
        return;
      } catch (e) {
        debugPrint("Log_Auth_flow: OTP - Error navigating to returnTo: $e");
        // Continue to fallback navigation options
      }
    } else if (returnTo != null) {
      debugPrint(
          "Log_Auth_flow: OTP - Found invalid returnTo path: $returnTo, ignoring");
    }

    // Try getting returnTo from SharedPreferences as backup if not found in URL
    _tryFallbackNavigation(context);
  }

  void _tryFallbackNavigation(BuildContext context) {
    debugPrint("Log_Auth_flow: OTP - Trying fallback navigation options");

    // Try reading returnTo from secure storage
    _readSavedReturnPath().then((savedReturnTo) {
      if (savedReturnTo != null &&
          savedReturnTo.isNotEmpty &&
          !savedReturnTo.startsWith('/login') &&
          !savedReturnTo.startsWith('/verify-otp')) {
        debugPrint(
            "Log_Auth_flow: OTP - Using saved return path: $savedReturnTo");

        if (context.mounted) {
          context.go(savedReturnTo);

          // Show success message after navigation
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.mounted) {
              showAuthSuccessNotification(context);
            }
          });
          return;
        }
      }

      // If no saved path or couldn't use it, try standard fallbacks
      _standardFallbackNavigation(context);
    }).catchError((e) {
      debugPrint("Log_Auth_flow: OTP - Error reading saved return path: $e");
      if (context.mounted) {
        _standardFallbackNavigation(context);
      }
    });
  }

  // Read return path from secure storage
  Future<String?> _readSavedReturnPath() async {
    try {
      const storage = FlutterSecureStorage();
      final savedPath = await storage.read(key: 'previous_route_before_login');
      debugPrint("Log_Auth_flow: OTP - Read saved return path: $savedPath");
      return savedPath;
    } catch (e) {
      debugPrint("Log_Auth_flow: OTP - Error reading saved path: $e");
      return null;
    }
  }

  // Standard fallbacks when no saved return paths are available
  void _standardFallbackNavigation(BuildContext context) {
    // If there's no valid returnTo in URL, try going back to previous screen
    try {
      final canPop = context.canPop();
      debugPrint("Log_Auth_flow: OTP - Can pop to previous screen: $canPop");

      if (canPop) {
        debugPrint("Log_Auth_flow: OTP - Popping back to previous screen");
        // IMPROVED: Pop with result to indicate successful authentication
        context.pop();

        // Show success message after navigation back
        Future.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) {
            showAuthSuccessNotification(context);
          }
        });

        debugPrint("Log_Auth_flow: OTP - Successfully popped back");
        return;
      }
    } catch (e) {
      debugPrint("Log_Auth_flow: OTP - Error when trying to pop: $e");
    }

    // As a last resort, navigate to home
    debugPrint(
        "Log_Auth_flow: OTP - No valid return path found, going to home");
    try {
      debugPrint("Log_Auth_flow: OTP - Navigating to /home");
      context.go('/home');

      // Show success message on home screen
      Future.delayed(const Duration(milliseconds: 300), () {
        if (context.mounted) {
          showAuthSuccessNotification(context);
        }
      });

      debugPrint("Log_Auth_flow: OTP - Successfully navigated to home");
    } catch (e) {
      debugPrint("Log_Auth_flow: OTP - Error navigating to home: $e");
    }
  }

  Future<void> _resendCode() async {
    if (_timeLeft > 0) return;

    setState(() {
      _isLoading = true;
      _otpError = null;
    });

    try {
      bool success = false;
      final identifier = widget.googleEmail ?? widget.phoneNumber!;

      // Use the refreshOtp endpoint instead of the original authentication endpoints
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      success = await authProvider.refreshOtp(identifier);

      if (success) {
        _startResendTimer();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.otpResentSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _otpError = authProvider.error ??
                AppLocalizations.of(context)!.failedToResendOtp;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _otpError = 'Error: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Add a method to handle OTP pasting
  Future<void> _pasteOtp() async {
    try {
      // Get clipboard data
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final pastedText = clipboardData?.text;

      if (pastedText == null || pastedText.isEmpty) {
        _showPasteError(AppLocalizations.of(context)!.clipboardEmpty);
        return;
      }

      _processPastedOtp(pastedText);
    } catch (e) {
      debugPrint("OTP: Error pasting OTP: $e");
      _showPasteError(AppLocalizations.of(context)!.clipboardAccessError);
    }
  }

  // Show error toast when paste fails
  void _showPasteError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Start monitoring clipboard for OTP codes
  void _startClipboardMonitoring() {
    // Check clipboard every 2 seconds
    _clipboardCheckTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      // Don't check if we're already submitting an OTP
      if (_otpSubmitted || _isLoading) return;

      // Don't check if all fields are already filled
      bool allFilled =
          _otpControllers.every((controller) => controller.text.isNotEmpty);
      if (allFilled) return;

      try {
        final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
        final clipText = clipboardData?.text;

        if (clipText == null || clipText.isEmpty) return;

        // Look for 6-digit number in the clipboard text
        final otpRegex = RegExp(r'\b\d{6}\b');
        final match = otpRegex.firstMatch(clipText);

        if (match != null) {
          final otpCode = match.group(0);
          debugPrint("OTP: Found potential OTP in clipboard: $otpCode");

          // Check if this is different from what's already in the fields
          final currentOtp = _otpControllers.map((c) => c.text).join();
          if (currentOtp == otpCode) return; // Same OTP, no need to update

          // Fill the OTP fields
          if (otpCode != null && mounted) {
            setState(() {
              for (int i = 0; i < 6; i++) {
                _otpControllers[i].text = otpCode[i];
              }

              // Clear any errors
              if (_otpError != null) {
                _otpError = null;
              }
            });

            // Show a brief indicator that OTP was auto-filled
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.otpAutoFilled),
                backgroundColor: const Color(0xFF158247),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );

            // Auto-verify after a short delay
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && !_otpSubmitted && !_isLoading) {
                _verifyOtp();
              }
            });

            // Stop checking clipboard after successful auto-fill
            timer.cancel();
          }
        }
      } catch (e) {
        debugPrint("OTP: Error checking clipboard: $e");
        // Don't show errors for background clipboard checks
      }
    });
  }

  // Handle changes in the full OTP input field
  void _handleFullOtpChange() {
    final fullOtp = _fullOtpController.text;

    // Only process if we have input
    if (fullOtp.isEmpty) return;

    // Extract only digits
    final digitsOnly = fullOtp.replaceAll(RegExp(r'[^0-9]'), '');

    // Update individual OTP fields
    for (int i = 0; i < math.min(digitsOnly.length, 6); i++) {
      _otpControllers[i].text = digitsOnly[i];
    }

    // Clear the full OTP field to prepare for new input
    _fullOtpController.clear();

    // Check if we have all 6 digits and verify
    if (digitsOnly.length >= 6) {
      // Unfocus to hide keyboard
      FocusScope.of(context).unfocus();

      // Small delay to allow UI to update
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_otpSubmitted && !_isLoading) {
          _verifyOtp();
        }
      });
    }
  }

  // Add a method to specifically handle clipboard pasting
  void _processPastedOtp(String pastedText) {
    if (pastedText.isEmpty) return;

    // Extract only digits
    final digitsOnly = pastedText.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) return;

    // Update individual OTP fields
    for (int i = 0; i < math.min(digitsOnly.length, 6); i++) {
      _otpControllers[i].text = digitsOnly[i];
    }

    // Focus the next empty field or unfocus if all fields are filled
    if (digitsOnly.length < 6) {
      _focusNodes[math.min(digitsOnly.length, 5)].requestFocus();
    } else {
      FocusScope.of(context).unfocus();

      // Verify OTP if we have all 6 digits
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_otpSubmitted && !_isLoading) {
          _verifyOtp();
        }
      });
    }
  }

  // Add a method to clear all OTP fields
  void _clearOtpFields() {
    setState(() {
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _otpError = null;
    });

    // Focus the first field
    _focusNodes[0].requestFocus();

    // Also focus the hidden field to capture keyboard input
    _fullOtpFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen metrics for responsive layout
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    // Calculate header height - smaller when keyboard is visible
    final headerHeight = isKeyboardVisible
        ? screenHeight * 0.22 // Smaller header when keyboard is visible
        : screenHeight * 0.32; // Normal header height

    return Scaffold(
      backgroundColor: Colors.white,
      // Remove resizeToAvoidBottomInset: true to prevent screen jumping
      body: Stack(
        children: [
          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Green curved header with logo - adaptive height
              ClipPath(
                clipper: CurvedBottomClipper(),
                child: Container(
                  color: const Color(0xFF158247), // Primary green color
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
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.black54,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        // Logo
                        Center(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Calculate logo size based on available height
                              final availableHeight = constraints.maxHeight -
                                  40; // Account for padding
                              final logoSize = math.min(
                                  isKeyboardVisible ? 80.0 : 120.0,
                                  availableHeight);

                              return Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Image.asset(
                                  'assets/images/auth/logo.png',
                                  height: logoSize,
                                  width: logoSize,
                                  fit: BoxFit.contain,
                                  // Use placeholder if logo not available
                                  errorBuilder: (ctx, obj, stack) => Icon(
                                    Icons.landscape,
                                    color: Colors.white,
                                    size: 70,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10), // Reduced spacing after header

              // Scrollable content area that adjusts for keyboard
              Expanded(
                child: GestureDetector(
                  // Dismiss keyboard when tapping outside input fields
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Title
                        Text(
                          AppLocalizations.of(context)!.otpVerification,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Subtitle
                        Text(
                          widget.googleEmail != null
                              ? AppLocalizations.of(context)!.checkEmailForOtp
                              : AppLocalizations.of(context)!
                                  .checkMessageForOtp,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 30),

                        // OTP Code label and action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.otpCode,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            // Action buttons
                            Row(
                              children: [
                                // Paste button
                                IconButton(
                                  onPressed: _pasteOtp,
                                  icon: const Icon(
                                    Icons.content_paste,
                                    size: 20,
                                    color: Color(0xFF158247),
                                  ),
                                  tooltip:
                                      AppLocalizations.of(context)!.pasteOtp,
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(8),
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(width: 8),
                                // Clear button
                                IconButton(
                                  onPressed: _clearOtpFields,
                                  icon: const Icon(
                                    Icons.refresh,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                  tooltip: AppLocalizations.of(context)!.clear,
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(8),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // OTP input fields
                        Stack(
                          children: [
                            // Visible OTP fields
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                6,
                                (index) => SizedBox(
                                  width: 45,
                                  height: 50,
                                  child: TextField(
                                    controller: _otpControllers[index],
                                    focusNode: _focusNodes[index],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 20),
                                    maxLength: 1,
                                    decoration: InputDecoration(
                                      counterText: '',
                                      filled: true,
                                      fillColor: Colors.grey.shade100,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: _otpError != null
                                            ? const BorderSide(
                                                color: Colors.red, width: 1.0)
                                            : BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: _otpError != null
                                            ? const BorderSide(
                                                color: Colors.red, width: 1.0)
                                            : BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: _otpError != null
                                            ? const BorderSide(
                                                color: Colors.red, width: 1.0)
                                            : const BorderSide(
                                                color: Color(0xFF158247),
                                                width: 1.0),
                                      ),
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    onChanged: (value) {
                                      // Clear error when user types
                                      if (_otpError != null) {
                                        setState(() {
                                          _otpError = null;
                                        });
                                      }

                                      // Auto focus to next field
                                      if (value.isNotEmpty && index < 5) {
                                        _focusNodes[index + 1].requestFocus();
                                      }

                                      // Auto-submit when all fields are filled
                                      if (index == 5 && value.isNotEmpty) {
                                        bool allFilled = _otpControllers.every(
                                            (controller) =>
                                                controller.text.isNotEmpty);

                                        if (allFilled) {
                                          // Unfocus keyboard
                                          FocusScope.of(context).unfocus();
                                          // Small delay to allow UI to update
                                          Future.delayed(
                                              const Duration(milliseconds: 100),
                                              () {
                                            _verifyOtp();
                                          });
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),

                            // Hidden full OTP input field - only used for clipboard pasting
                            Opacity(
                              opacity: 0,
                              child: Offstage(
                                offstage: true,
                                child: TextField(
                                  controller: _fullOtpController,
                                  focusNode: _fullOtpFocusNode,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Error message
                        if (_otpError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                            child: Text(
                              _otpError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 40),

                        // Verify button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: (_isLoading || _otpSubmitted)
                                  ? null
                                  : _verifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF158247),
                                disabledBackgroundColor: Colors.grey.shade400,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5))
                                  : Text(
                                      AppLocalizations.of(context)!.verify,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        // Resend code row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: (_timeLeft == 0 && !_isLoading)
                                  ? _resendCode
                                  : null,
                              child: Text(
                                AppLocalizations.of(context)!.resendCode,
                                style: TextStyle(
                                  color: (_timeLeft == 0 && !_isLoading)
                                      ? const Color(0xFF158247)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            Text(
                              _formatTimeLeft(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        // Add extra padding at the bottom to ensure everything is visible
                        SizedBox(
                          height: keyboardHeight > 0
                              ? keyboardHeight
                              : MediaQuery.of(context).padding.bottom + 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Loading overlay - only shown when isLoading & otpSubmitted are both true
          if (_isLoading && _otpSubmitted)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
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
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF158247).withAlpha(179),
                          ),
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Loading text
                      Text(
                        AppLocalizations.of(context)!.verifying,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF158247),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtext
                      Text(
                        AppLocalizations.of(context)!.verifyingYourCode,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Floating paste button for easier access
        ],
      ),
    );
  }
}

// Custom clipper for the curved bottom - matches login page exactly
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
