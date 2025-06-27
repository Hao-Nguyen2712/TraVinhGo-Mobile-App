import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/providers/auth_provider.dart';
import 'package:travinhgo/widget/login_button_widget.dart';
import 'package:travinhgo/utils/constants.dart';

class AuthRequiredScreen extends StatelessWidget {
  final Widget child;
  final String message;

  const AuthRequiredScreen({
    super.key,
    required this.child,
    this.message = 'Please login to access this feature',
  });

  @override
  Widget build(BuildContext context) {
    // Debug print to verify the AuthRequiredScreen is being displayed
    debugPrint("AUTH REQUIRED SCREEN: Building screen with message: $message");

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show login UI if not authenticated
        if (!authProvider.isAuthenticated) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Lock icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kprimaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: 60,
                          color: kprimaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      const Text(
                        'Authentication Required',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Message
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Login button
                      SizedBox(
                        width: 220,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            // Get current route to return to after login
                            final currentRoute =
                                GoRouterState.of(context).uri.toString();

                            // Navigate to login with returnTo parameter
                            context.go(
                                '/login?returnTo=${Uri.encodeComponent(currentRoute)}');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kprimaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Back to home button
                      TextButton(
                        onPressed: () {
                          context.go('/home');
                        },
                        child: Text(
                          'Back to Home',
                          style: TextStyle(
                            color: kprimaryColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Show the actual screen content if authenticated
        return child;
      },
    );
  }
}
