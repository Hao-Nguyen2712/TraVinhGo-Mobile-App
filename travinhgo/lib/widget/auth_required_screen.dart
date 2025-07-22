import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
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
                  padding: EdgeInsets.all(6.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Lock icon
                      Container(
                        padding: EdgeInsets.all(5.w),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: 18.w,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 3.h),

                      // Title
                      Text(
                        'Authentication Required',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 1.5.h),

                      // Message
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4.h),

                      // Login button
                      SizedBox(
                        width: 55.w,
                        height: 6.h,
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
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.sp),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),

                      // Back to home button
                      TextButton(
                        onPressed: () {
                          context.go('/home');
                        },
                        child: Text(
                          'Back to Home',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 14.sp,
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
