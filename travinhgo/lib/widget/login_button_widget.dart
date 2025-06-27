import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travinhgo/utils/constants.dart';

class LoginButtonWidget extends StatelessWidget {
  final String message;
  final double buttonWidth;
  final double buttonHeight;

  const LoginButtonWidget({
    super.key,
    this.message = 'Please login to access this feature',
    this.buttonWidth = 200,
    this.buttonHeight = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.isNotEmpty) ...[
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
          ],
          SizedBox(
            width: buttonWidth,
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: () {
                // Get current route to return to after login
                final currentLocation =
                    GoRouterState.of(context).uri.toString();
                // Navigate to login with returnTo parameter
                context.go(
                    '/login?returnTo=${Uri.encodeComponent(currentLocation)}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kprimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
        ],
      ),
    );
  }
}
