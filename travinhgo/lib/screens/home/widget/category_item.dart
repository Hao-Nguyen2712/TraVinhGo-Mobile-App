import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../introduction/introduction_page.dart';

class CategoryItem extends StatelessWidget {
  final String iconName;
  final int ColorName;
  final String title;
  final int index;

  const CategoryItem({
    super.key,
    required this.iconName,
    required this.ColorName,
    required this.title,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    List screen = const [IntroductionPage()];
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen[index]),
        );
      },
      child: Column(
        children: [
          Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              color: Color(ColorName),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset(
                "assets/images/navigations/" + iconName + ".png",
                scale: 10,
              ),
            ),
          ),
          Text(title, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
