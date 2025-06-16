import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/providers/auth_provider.dart';
import 'package:travinhgo/widget/login_button_widget.dart';

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
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show login button if not authenticated
        if (!authProvider.isAuthenticated) {
          return Scaffold(
            body: LoginButtonWidget(message: message),
          );
        }

        // Show the actual screen content if authenticated
        return child;
      },
    );
  }
}
