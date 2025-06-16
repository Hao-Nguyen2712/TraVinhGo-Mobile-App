import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/providers/auth_provider.dart';
import 'package:travinhgo/screens/auth/login_screen.dart';
import 'package:travinhgo/screens/auth/otp_verification_screen.dart';
import 'package:travinhgo/screens/nav_bar_screen.dart';
import 'package:travinhgo/screens/splash/splash_screen.dart';

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: authProvider, // Refresh when auth state changes
    redirect: _handleRedirect,
    routes: [
      // Splash screen
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        name: 'verifyOtp',
        builder: (context, state) {
          final phoneNumber = state.uri.queryParameters['phoneNumber'];
          final googleEmail = state.uri.queryParameters['googleEmail'];
          return OtpVerificationScreen(
            phoneNumber: phoneNumber,
            googleEmail: googleEmail,
          );
        },
      ),

      // Main app
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const BottomNavBar(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );

  String? _handleRedirect(BuildContext context, GoRouterState state) {
    // Don't redirect on splash, auth routes, or home screen
    if (state.matchedLocation == '/' ||
        state.matchedLocation.startsWith('/login') ||
        state.matchedLocation.startsWith('/verify-otp') ||
        state.matchedLocation == '/home') {
      return null;
    }

    // Only redirect protected routes (not the home screen)
    final isLoggedIn = authProvider.isAuthenticated;
    if (!isLoggedIn) {
      return '/login';
    }

    // No redirect needed
    return null;
  }
}
