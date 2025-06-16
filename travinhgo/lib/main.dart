import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/providers/auth_provider.dart';
import 'package:travinhgo/providers/card_provider.dart';
import 'package:travinhgo/providers/map_provider.dart';
import 'package:travinhgo/providers/setting_provider.dart';
import 'package:travinhgo/router/app_router.dart';
import 'package:travinhgo/providers/destination_type_provider.dart';
import 'package:travinhgo/providers/marker_provider.dart';
import 'package:travinhgo/providers/tag_provider.dart';
import 'package:travinhgo/screens/auth/login_screen.dart';
import 'package:travinhgo/screens/nav_bar_screen.dart';
import 'package:travinhgo/screens/splash/splash_screen.dart';
import 'package:travinhgo/utils/env_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment configuration
  await EnvConfig.initialize();

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
          ChangeNotifierProvider(create: (_) => SettingProvider()),
          ChangeNotifierProvider(create: (_) => MarkerProvider()),
          ChangeNotifierProvider(create: (_) => MapProvider()),
          ChangeNotifierProvider(create: (_) => DestinationTypeProvider()),
          ChangeNotifierProvider(create: (_) => TagProvider()),
        ],
        child: Builder(
          builder: (context) {
            final authProvider = Provider.of<AuthProvider>(context);
            final appRouter = AppRouter(authProvider);

            return MaterialApp.router(
              title: "TraVinhGo",
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme:
                    ColorScheme.fromSeed(seedColor: const Color(0xFF158247)),
                useMaterial3: true,
                textTheme: GoogleFonts.montserratTextTheme(),
              ),
              routerConfig: appRouter.router,
            );
          },
        ),
      );
}
