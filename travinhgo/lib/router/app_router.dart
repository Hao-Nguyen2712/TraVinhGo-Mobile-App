import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/screens/notification/message_screen.dart';
import 'package:travinhgo/providers/auth_provider.dart';
import 'package:travinhgo/screens/auth/login_screen.dart';
import 'package:travinhgo/screens/auth/otp_verification_screen.dart';
import 'package:travinhgo/screens/nav_bar_screen.dart';
import 'package:travinhgo/screens/splash/splash_screen.dart';

import '../main.dart';
import '../screens/destination/destination_detail_screen.dart';
import '../screens/event_festival/event_fesftival_detail_screen.dart';
import '../screens/local_specialty/local_specialty_detail_screen.dart';
import '../screens/ocop_product/ocop_product_detail_screen.dart';
import '../widget/auth_required_screen.dart';

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: authProvider,
    // Refresh when auth state changes
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
      GoRoute(
        path: '/local-specialty-detail/:id',
        name: 'LocalSpecialtyDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return LocalSpecialtyDetailScreen(
            id: id,
          );
        },
      ),
      GoRoute(
        path: '/event-festival-detail/:id',
        name: 'EventFestivalDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EventFesftivalDetailScreen(
            id: id,
          );
        },
      ),
      GoRoute(
        path: '/ocop-product-detail/:id',
        name: 'OcopProductDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OcopProductDetailScreen(
            id: id,
          );
        },
      ),
      GoRoute(
        path: '/notification',
        name: 'Notification',
        builder: (context, state) => MessageScreen(),
      ),
      GoRoute(
        path: '/tourist-destination-detail/:id',
        name: 'TouristDestinationDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DestinationDetailScreen(
            id: id,
          );
        },
      ),
      // Main app
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => BottomNavBar(),
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
        state.matchedLocation == '/home' ||
        state.matchedLocation.startsWith('/local-specialty-detail/') ||
        state.matchedLocation.startsWith('/event-festival-detail/') ||
        state.matchedLocation.startsWith('/ocop-product-detail/') ||
        state.matchedLocation.startsWith('/tourist-destination-detail/') ||
        state.matchedLocation.startsWith('/notification')) {
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
