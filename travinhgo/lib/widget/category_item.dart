import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:travinhgo/screens/accomodation/accomodation_screen.dart';
import 'package:travinhgo/screens/introduction/introduction_page.dart';
import 'package:travinhgo/screens/utilities/utilities_screen.dart';

import '../screens/notification/message_screen.dart';
import '../screens/destination/destination_screen.dart';
import '../screens/event_festival/event_festival_screen.dart';
import '../screens/local_specialty/local_specialty_screen.dart';
import '../screens/ocop_product/ocop_product_screen.dart';
import '../screens/tip/tip_screen.dart';

class CategoryItem extends StatelessWidget {
  final String iconName;
  final Color color;
  final String title;

  const CategoryItem({
    super.key,
    required this.iconName,
    this.color = Colors.transparent,
    required this.title,
  });

  void _navigateToScreen(BuildContext context) {
    Widget? screen;
    switch (iconName) {
      case "Introduction":
        screen = const IntroductionPage();
        break;
      case "Destination":
        screen = const DestinationScreen();
        break;
      case "Specialities":
        screen = const LocalSpecialtyScreen();
        break;
      case "EventAndFestival":
        screen = const EventFestivalScreen();
        break;
      case "Ocop":
        screen = const OcopProductScreen();
        break;
      case "Message":
        screen = const MessageScreen();
        break;
      case "Tips":
        screen = const TipScreen();
        break;
      case "Stay":
        screen = const AccomodationScreen();
        break;
      case "Utilities":
        screen = const UtilitiesScreen();
        break;
    }
    if (screen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToScreen(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18.w,
            height: 18.w,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15.sp),
            ),
            child: Padding(
              padding: const EdgeInsets.all(0.0),
              child: Image.asset(
                "assets/images/home/$iconName.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            width: 18.w,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
