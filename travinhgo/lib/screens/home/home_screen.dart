import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/providers/auth_provider.dart';
import 'package:travinhgo/sampledata/samplelist.dart';
import 'package:travinhgo/widget/category_grid.dart';
import 'package:travinhgo/widget/category_item.dart';
import 'package:travinhgo/widget/home_header.dart';
import 'package:travinhgo/widget/image_slider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _handledInitialMessage = false;

  @override
  void initState() {
    super.initState();
    // Set the status bar color to match our header
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // transparent status bar
      statusBarIconBrightness: Brightness.light, // light status bar icons
    ));

    // _handleNotificationNavigation();
    pushNotificationService.firebaseInit(context);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;

    // No longer using ProtectedScreen - allowing access to all users
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      body: Container(
        color: const Color(0xFF158247),
        child: Column(
          children: [
            // Empty space for status bar with green background
            SizedBox(height: statusBarHeight),
            // Header already has green background
            const HomeHeader(),
            // Main content with white background
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(0),
                    topRight: Radius.circular(0),
                  ),
                ),
                child: SafeArea(
                  top: false, // Header already accounts for top padding
                  bottom: true, // Keep bottom safe area
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        // Ensure the content has enough space to scroll
                        minHeight: screenHeight -
                            statusBarHeight -
                            MediaQuery.of(context).padding.bottom -
                            80, // Account for header
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 30.0),
                        child: Column(
                          children: [
                            // Welcome message
                            const SizedBox(height: 15),
                            // Search bar
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(60),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black26, blurRadius: 5),
                                  ],
                                ),
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!
                                        .searchHere,
                                    hintStyle: const TextStyle(
                                        fontSize: 20, color: Color(0xFFA29C9C)),
                                    border: InputBorder.none,
                                    icon: Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Image.asset(
                                        "assets/images/navigations/search.png",
                                        scale: 25,
                                        color: const Color(0xFFA29C9C),
                                      ),
                                    ),
                                  ),
                                  onSubmitted: (value) {
                                    print("địa chỉ được nhập là " + value);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            // Image slider
                            ImageSlider(imageList: imageListHome),
                            const SizedBox(height: 20),
                            // Categories grid - now using the CategoryGrid widget
                            const CategoryGrid(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
