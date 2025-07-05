import 'package:flutter/material.dart';
import 'package:travinhgo/widget/category_item.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
        children: [
          CategoryItem(
            iconName: "coconut-tree",
            ColorName: 0xFFFFDAB9,
            title: AppLocalizations.of(context)!.introduce,
            index: 5,
          ),
          CategoryItem(
            iconName: "plantingtree",
            ColorName: 0xFFD4F4DD,
            title: AppLocalizations.of(context)!.ocop,
            index: 4,
          ),
          CategoryItem(
            iconName: "lightbulb",
            ColorName: 0xFFD6EFFF,
            title: AppLocalizations.of(context)!.tipTravel,
            index: 0,
          ),
          CategoryItem(
            iconName: "destination",
            ColorName: 0xFFFFE4E1,
            title: AppLocalizations.of(context)!.destination,
            index: 1,
          ),
          CategoryItem(
            iconName: "food",
            ColorName: 0xFFFFFACD,
            title: AppLocalizations.of(context)!.localSpecialty,
            index: 2,
          ),
          CategoryItem(
            iconName: "hotel",
            ColorName: 0xFFE0FFFF,
            title: AppLocalizations.of(context)!.event,
            index: 3,
          ),
          CategoryItem(
            iconName: "dragon-boat",
            ColorName: 0xFFE6E6FA,
            title: AppLocalizations.of(context)!.tipTravel,
            index: 0,
          ),
          CategoryItem(
            iconName: "resource-allocation",
            ColorName: 0xFFF5F5DC,
            title: AppLocalizations.of(context)!.utilities,
            index: 0,
          ),
        ],
      ),
    );
  }
}
