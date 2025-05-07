import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:travinhgo/screens/home/widget/category_item.dart';
import 'package:travinhgo/screens/home/widget/image_slider.dart';

import '../../sampledata/samplelist.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
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
                                  SizedBox(width: 5),
                                  Text(
                                    "Vie",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF7D8FAB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 5),
                            Text(
                              "|",
                              style: TextStyle(color: Color(0xFF7D8FAB)),
                            ),
                            SizedBox(width: 5),
                            GestureDetector(
                              onTap: () {},
                              child: Row(
                                children: [
                                  Image.asset(
                                    "assets/images/navigations/circle.png",
                                    width: 20,
                                    height: 20,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
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
                        SizedBox(width: 20),
                        SizedBox(
                          width: 55,
                          height: 50,
                          child: Stack(
                            children: [
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xffffff),
                                  border: Border.all(
                                    color: Color(0xFFA29C9C),
                                    width: 2,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    "assets/images/navigations/bell.png",
                                    scale: 10,
                                    color: Color(0xFFA29C9C),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFDD2334),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "9+",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "How you feel today ?",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 15,),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 5),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search here",
                          hintStyle: TextStyle(fontSize: 20, color: Color(0xFFA29C9C)),
                          border: InputBorder.none,
                          icon: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Image.asset("assets/images/navigations/search.png", scale: 25, color: Color(0xFFA29C9C),),
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
              SizedBox(height: 10,),
              ImageSlider(imageList: imageListHome),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CategoryItem(iconName: "coconut-tree",ColorName: 0xFFFFDAB9,title: "Introduce",index: 0,),
                        CategoryItem(iconName: "plantingtree",ColorName: 0xFFD4F4DD,title: "Ocop",index: 0,),
                        CategoryItem(iconName: "lightbulb",ColorName: 0xFFD6EFFF,title: "Tip Travel",index: 0,),
                        CategoryItem(iconName: "destination",ColorName: 0xFFFFE4E1,title: "Destination",index: 0,),
                      ],
                    ),
                    SizedBox(height: 20,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CategoryItem(iconName: "food",ColorName: 0xFFFFFACD,title: "Local specialty",index: 0,),
                        CategoryItem(iconName: "hotel",ColorName: 0xFFE0FFFF,title: "Stay",index: 0,),
                        CategoryItem(iconName: "dragon-boat",ColorName: 0xFFE6E6FA,title: "Tip Travel",index: 0,),
                        CategoryItem(iconName: "resource-allocation",ColorName: 0xFFF5F5DC,title: "Utilities",index: 0,),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
