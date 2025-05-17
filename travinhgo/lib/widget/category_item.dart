import 'package:flutter/material.dart';
import 'package:travinhgo/screens/introduction/introduction_page.dart';

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
    List<Widget> screen = const [IntroductionPage()];
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen[index]),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Color(ColorName),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Image.asset(
                "assets/images/navigations/$iconName.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 70,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
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
