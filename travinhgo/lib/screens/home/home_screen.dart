import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/widget/category_item.dart';
import 'package:travinhgo/widget/image_slider.dart';

import '../../providers/auth_provider.dart';
import '../../sampledata/samplelist.dart';
import '../../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isAuthenticated;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: true, // Ensure bottom safe area is respected
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // Ensure the content has enough space to scroll
              minHeight: screenHeight -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                  bottom: 30.0), // Increased bottom padding
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              "HI, ALEX",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {},
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        "assets/images/navigations/vietnam.png",
                                        width: 20,
                                        height: 20,
                                      ),
                                      const SizedBox(width: 5),
                                      const Text(
                                        "Vie",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF7D8FAB),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  "|",
                                  style: TextStyle(color: Color(0xFF7D8FAB)),
                                ),
                                const SizedBox(width: 5),
                                GestureDetector(
                                  onTap: () {},
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        "assets/images/navigations/circle.png",
                                        width: 20,
                                        height: 20,
                                      ),
                                      const SizedBox(width: 5),
                                      const Text(
                                        "Eng",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF7D8FAB),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/signin');
                              },
                              child: Container(
                                width: 100,
                                decoration: BoxDecoration(
                                    shape: BoxShape.rectangle,
                                    color: kprimaryColor,
                                    borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                child: Center(
                                  child: Text(
                                    "Login",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            )
                            // SizedBox(
                            //   width: 50,
                            //   height: 50,
                            //   child: Stack(
                            //     children: [
                            //       Container(
                            //         width: 45,
                            //         height: 45,
                            //         decoration: BoxDecoration(
                            //           shape: BoxShape.circle,
                            //           border: Border.all(
                            //             color: const Color(0xFFA29C9C),
                            //             width: 2,
                            //           ),
                            //         ),
                            //         child: Padding(
                            //           padding: const EdgeInsets.all(8.0),
                            //           child: Image.asset(
                            //             "assets/images/navigations/bell.png",
                            //             scale: 10,
                            //             color: const Color(0xFFA29C9C),
                            //           ),
                            //         ),
                            //       ),
                            //       Positioned(
                            //         top: 0,
                            //         right: 0,
                            //         child: Container(
                            //           width: 22,
                            //           height: 22,
                            //           decoration: const BoxDecoration(
                            //             shape: BoxShape.circle,
                            //             color: Color(0xFFDD2334),
                            //           ),
                            //           child: const Center(
                            //             child: Text(
                            //               "9+",
                            //               style: TextStyle(
                            //                 fontSize: 10,
                            //                 fontWeight: FontWeight.w900,
                            //                 color: Colors.white,
                            //               ),
                            //             ),
                            //           ),
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                          ],
                        ),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "How you feel today ?",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        Container(
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  ImageSlider(imageList: imageListHome),
                  const SizedBox(height: 15),
                  // Categories grid using GridView
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 0.8,
                      // Increased for more vertical space
                      mainAxisSpacing: 10,
                      // Reduced spacing
                      crossAxisSpacing: 5,
                      children: const [
                        // First row
                        CategoryItem(
                          iconName: "coconut-tree",
                          ColorName: 0xFFFFDAB9,
                          title: "Introduce",
                          index: 0,
                        ),
                        CategoryItem(
                          iconName: "plantingtree",
                          ColorName: 0xFFD4F4DD,
                          title: "Ocop",
                          index: 0,
                        ),
                        CategoryItem(
                          iconName: "lightbulb",
                          ColorName: 0xFFD6EFFF,
                          title: "Tip Travel",
                          index: 0,
                        ),
                        CategoryItem(
                          iconName: "destination",
                          ColorName: 0xFFFFE4E1,
                          title: "Destination",
                          index: 1,
                        ),
                        // Second row
                        CategoryItem(
                          iconName: "food",
                          ColorName: 0xFFFFFACD,
                          title: "Local specialty",
                          index: 0,
                        ),
                        CategoryItem(
                          iconName: "hotel",
                          ColorName: 0xFFE0FFFF,
                          title: "Stay",
                          index: 0,
                        ),
                        CategoryItem(
                          iconName: "dragon-boat",
                          ColorName: 0xFFE6E6FA,
                          title: "Tip Travel",
                          index: 0,
                        ),
                        CategoryItem(
                          iconName: "resource-allocation",
                          ColorName: 0xFFF5F5DC,
                          title: "Utilities",
                          index: 0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
