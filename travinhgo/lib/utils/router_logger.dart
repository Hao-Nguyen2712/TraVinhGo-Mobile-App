import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// A logger for Go Router navigation events that extends the standard NavigatorObserver.
///
/// This class provides detailed logging of navigation events throughout the app,
/// including route names, parameters, and transition details.
class RouterLogger extends NavigatorObserver {
  // Enable/disable logging
  final bool enableLogging;
  // Enable detailed parameter logging
  final bool logParameters;
  // Tag prefix for all log messages
  final String logTag;

  RouterLogger({
    this.enableLogging = true,
    this.logParameters = true,
    this.logTag = 'NAVIGATION',
  });

  // Special method to log Google Sign-in related navigation events
  void logGoogleSignInNavigation(
      Route<dynamic>? route, BuildContext? context, String event) {
    if (!enableLogging) return;

    final routeName = route?.settings.name ?? 'unknown';
    String message = '🔐 GOOGLE_SIGNIN: $event on route: $routeName';

    // If context is provided, check the Google sign-in state
    if (context != null) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isGoogleSignInInProgress = authProvider.isGoogleSignInInProgress;
        message += ', isGoogleSignInInProgress: $isGoogleSignInInProgress';
      } catch (e) {
        message += ', (error accessing auth provider: $e)';
      }
    }

    debugPrint(message);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!enableLogging) return;

    final routeName = route.settings.name ?? 'unknown';
    final prevRouteName = previousRoute?.settings.name ?? 'none';

    String message = '$logTag: PUSHED route: $routeName from $prevRouteName';

    if (logParameters && route.settings.arguments != null) {
      message +=
          '\n   Arguments: ${_formatArguments(route.settings.arguments)}';
    }

    // Check if this might be related to Google sign-in
    if (routeName.contains('login') ||
        routeName.contains('otp') ||
        prevRouteName.contains('login') ||
        prevRouteName.contains('otp')) {
      message += ' 🔐 (potential auth flow)';
    }

    debugPrint(message);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!enableLogging) return;

    final routeName = route.settings.name ?? 'unknown';
    final prevRouteName = previousRoute?.settings.name ?? 'none';

    String message =
        '$logTag: POPPED route: $routeName, returning to $prevRouteName';

    // Check if this might be related to Google sign-in navigation
    if (routeName.contains('login') ||
        routeName.contains('otp') ||
        prevRouteName.contains('login') ||
        prevRouteName.contains('otp')) {
      message += ' 🔐 (potential auth flow)';
    }

    debugPrint(message);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!enableLogging) return;

    final routeName = route.settings.name ?? 'unknown';
    String message = '$logTag: REMOVED route: $routeName';

    // Check if this might be related to Google sign-in
    if (routeName.contains('login') || routeName.contains('otp')) {
      message += ' 🔐 (potential auth flow)';
    }

    debugPrint(message);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (!enableLogging) return;

    final newRouteName = newRoute?.settings.name ?? 'unknown';
    final oldRouteName = oldRoute?.settings.name ?? 'unknown';

    String message = '$logTag: REPLACED route: $oldRouteName -> $newRouteName';

    if (logParameters && newRoute?.settings.arguments != null) {
      message +=
          '\n   Arguments: ${_formatArguments(newRoute!.settings.arguments)}';
    }

    // Check if this might be related to Google sign-in
    if (newRouteName.contains('login') ||
        newRouteName.contains('otp') ||
        oldRouteName.contains('login') ||
        oldRouteName.contains('otp')) {
      message += ' 🔐 (potential auth flow)';
    }

    debugPrint(message);
  }

  @override
  void didStartUserGesture(
      Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!enableLogging) return;

    final routeName = route.settings.name ?? 'unknown';
    debugPrint('$logTag: Started navigation gesture on route: $routeName');
  }

  @override
  void didStopUserGesture() {
    if (!enableLogging) return;

    debugPrint('$logTag: Stopped navigation gesture');
  }

  /// Helper method to format route arguments for logging
  String _formatArguments(dynamic arguments) {
    if (arguments is Map<String, dynamic>) {
      return arguments.entries
          .map((e) => '${e.key}: ${_truncateValue(e.value)}')
          .join(', ');
    }
    return _truncateValue(arguments).toString();
  }

  /// Truncate long values for better log readability
  dynamic _truncateValue(dynamic value) {
    if (value is String && value.length > 100) {
      return '${value.substring(0, 100)}...';
    }
    return value;
  }
}

/// GoRouter state observer for logging route transitions
class GoRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('GoRouter: PUSHED ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('GoRouter: POPPED ${route.settings.name}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('GoRouter: REMOVED ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    debugPrint(
        'GoRouter: REPLACED ${oldRoute?.settings.name} WITH ${newRoute?.settings.name}');
  }
}
