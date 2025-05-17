import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/providers/auth_provider.dart';
import 'package:travinhgo/services/auth_service.dart';
import 'package:travinhgo/widget/status_dialog.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? phoneNumber;
  final String? googleEmail;

  const OtpVerificationScreen({
    super.key,
    this.phoneNumber,
    this.googleEmail,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
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
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  Timer? _resendTimer;
  int _timeLeft = 300; // 5 minutes in seconds
  String? _otpError;

  @override
  void initState() {
    super.initState();
    // Show message popup when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showMessageSentPopup();
    });
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _showMessageSentPopup() {
    final bool isGoogleAuth = widget.googleEmail != null;
    final String recipient =
        isGoogleAuth ? widget.googleEmail! : widget.phoneNumber ?? '';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Green icon container
              Container(
                width: 64,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFF158247),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGoogleAuth ? Icons.email_outlined : Icons.message_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                isGoogleAuth ? 'Check your email' : 'Check your message',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                isGoogleAuth
                    ? 'We have sent OTP to $recipient. Please check your inbox.'
                    : 'We have sent OTP to confirm your phone number. Please check your inbox.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              // Close button
              SizedBox(
                  width: double.infinity,
                  height: 35,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Color(0xFF158247)),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
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
    final otpCode = _otpControllers.map((controller) => controller.text).join();

    // Check if OTP is empty or incomplete
    if (otpCode.isEmpty || otpCode.length < 6) {
      setState(() {
        _otpError = 'Please enter a valid OTP code';
      });
      return;
    }

    setState(() {
      _otpError = null;
      _isLoading = true;
    });

    try {
      final success = await _authService.verifyOtp(otpCode);

      if (success) {
        // Show success dialog before navigating to home screen
        if (mounted) {
          await StatusDialogs.showSuccessDialog(
            context: context,
            message: "You've reset your password!",
            onOkPressed: () {
              Navigator.of(context).pop(); // Dismiss dialog
              Navigator.of(context).pushReplacementNamed('/home');
            },
          );
        }
      } else {
        if (mounted) {
          await StatusDialogs.showErrorDialog(
            context: context,
            message: 'Password reset failed!',
            onOkPressed: () {
              Navigator.of(context).pop(); // Dismiss dialog
              setState(() {
                _otpError = 'Invalid OTP. Please try again.';
              });
            },
          );
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
            const SnackBar(
              content: Text('OTP code resent successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _otpError = 'Failed to resend OTP. Please try again.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      //   appBar: AppBar(
      //     backgroundColor: Colors.white,
      //     elevation: 0,
      //     leading: IconButton(
      //       icon: const Icon(Icons.arrow_back, color: Colors.black),
      //       onPressed: () => Navigator.of(context).pop(),
      //     ),
      //   ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipPath(
              clipper: CurvedBottomClipper(),
              child: Container(
                color: const Color(0xFF158247), // Primary green color
                height: 220,
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/auth/logo.png',
                              height: 170,
                              width: 170,
                              // Use placeholder if logo not available
                              errorBuilder: (ctx, obj, stack) => const Icon(
                                Icons.landscape,
                                color: Colors.white,
                                size: 70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: const Text(
                          'OTP Verification',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: const Text(
                          'Please Check Your Message To Confirm',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'OTP Code',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          6,
                          (index) => SizedBox(
                            width: 50,
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
                                          color: Color(0xFF158247), width: 1.0),
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
                              },
                            ),
                          ),
                        ),
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
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: (_isLoading || _isTimeExpired)
                              ? null
                              : _verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF158247),
                            disabledBackgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'Verify',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _timeLeft == 0 ? _resendCode : null,
                            child: Text(
                              'Resend code to',
                              style: TextStyle(
                                color: _timeLeft == 0
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom clipper for the curved bottom
class CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(
        0, size.height - 30); // Start from bottom-left with small offset

    // Use a single quadratic Bezier curve for the entire width
    path.quadraticBezierTo(
      size.width / 2, // Control point x at center
      size.height + 20, // Control point y below the bottom edge
      size.width, // End point x at right edge
      size.height - 30, // End point y same as start
    );

    // Complete the path
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
