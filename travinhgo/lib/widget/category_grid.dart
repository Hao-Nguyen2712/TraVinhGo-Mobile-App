import 'package:flutter/material.dart';
import 'package:travinhgo/widget/category_item.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.8,
        mainAxisSpacing: 10,
        crossAxisSpacing: 5,
        children: const [
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
          CategoryItem(
            iconName: "food",
            ColorName: 0xFFFFFACD,
            title: "Local specialty",
            index: 2,
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
    );
  }
}
