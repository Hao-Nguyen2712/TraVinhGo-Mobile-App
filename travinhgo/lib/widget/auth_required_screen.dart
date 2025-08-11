import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:travinhgo/providers/auth_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AuthRequiredScreen extends StatelessWidget {
  final Widget child;
  final String? message;

  const AuthRequiredScreen({
    super.key,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayMessage = message ?? l10n.loginToUseFeature;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Debug print to verify the AuthRequiredScreen is being displayed
    debugPrint(
        "AUTH REQUIRED SCREEN: Building screen with message: $displayMessage");

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show login UI if not authenticated
        if (!authProvider.isAuthenticated) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
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
                      SizedBox(height: 2.h),

                      // Title
                      Text(
                        l10n.authRequiredTitle,
                        style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 1.5.h),

                      // Message
                      Text(
                        displayMessage,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: isDarkMode
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 3.h),

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
                            l10n.signIn,
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkMode ? Colors.white : Colors.white),
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
                          l10n.backToHomeButton,
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.white
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
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
