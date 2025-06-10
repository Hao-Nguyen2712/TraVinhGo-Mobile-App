import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/providers/auth_provider.dart';
import 'package:travinhgo/providers/card_provider.dart';
import 'package:travinhgo/providers/destination_type_provider.dart';
import 'package:travinhgo/providers/marker_provider.dart';
import 'package:travinhgo/providers/tag_provider.dart';
import 'package:travinhgo/screens/auth/login_screen.dart';
import 'package:travinhgo/screens/nav_bar_screen.dart';
import 'package:travinhgo/screens/splash/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CardProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => MarkerProvider()),
          ChangeNotifierProvider(create: (_) => DestinationTypeProvider()),
          ChangeNotifierProvider(create: (_) => TagProvider()),
        ],
        child: MaterialApp(
          title: "TraVinhGo",
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xFF158247)),
            useMaterial3: true,
            textTheme: GoogleFonts.montserratTextTheme(),
          ),
          home: const SplashScreen(),
          routes: {
            '/home': (context) => const BottomNavBar(),
            LoginScreen.routeName: (context) => const LoginScreen(),
          },
        ),
      );
}
