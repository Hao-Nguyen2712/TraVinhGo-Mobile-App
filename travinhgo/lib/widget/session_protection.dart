import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/providers/auth_provider.dart';

class ProtectedScreen extends StatefulWidget {
  final Widget child;

  const ProtectedScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<ProtectedScreen> createState() => _ProtectedScreenState();
}

class _ProtectedScreenState extends State<ProtectedScreen> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    if (!mounted) return;

    setState(() => _isChecking = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isValid = await authProvider.checkSession(context);

    if (!mounted) return;

    setState(() => _isChecking = false);

    if (!isValid) {
      // Session is invalid, the dialog will be shown by checkSession
      // We don't need to do anything else here
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      // Show loading spinner while checking session
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

// Usage example:
// ProtectedScreen(
//   child: YourActualScreen(), 
// ), 