import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/providers/auth_provider.dart';
import 'package:travinhgo/sampledata/samplelist.dart';
import 'package:travinhgo/widget/category_grid.dart';
import 'package:travinhgo/widget/category_item.dart';
import 'package:travinhgo/widget/home_header.dart';
import 'package:travinhgo/widget/image_slider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;

    // No longer using ProtectedScreen - allowing access to all users
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: true, // Ensure bottom safe area is respected
        child: Column(
          children: [
            // Custom header with language switch and notification/login button
            const HomeHeader(),
            // Main content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // Ensure the content has enough space to scroll
                    minHeight: screenHeight -
                        MediaQuery.of(context).padding.top -
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
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(60),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 5),
                              ],
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: "Search here",
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
          ],
        ),
      ),
    );
  }
}
