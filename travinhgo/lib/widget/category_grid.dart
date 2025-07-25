import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:travinhgo/widget/category_item.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColors = [
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
      colorScheme.errorContainer,
      colorScheme.primaryContainer.withOpacity(0.7),
      colorScheme.secondaryContainer.withOpacity(0.7),
      colorScheme.tertiaryContainer.withOpacity(0.7),
      colorScheme.errorContainer.withOpacity(0.7),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.8,
        mainAxisSpacing: 1.h,
        crossAxisSpacing: 2.w,
        children: [
          CategoryItem(
            iconName: "Introduction",
            title: AppLocalizations.of(context)!.introduce,
            index: 0,
          ),
          CategoryItem(
            iconName: "Ocop",
            title: AppLocalizations.of(context)!.ocop,
            index: 4,
          ),
          CategoryItem(
            iconName: "Tips",
            title: AppLocalizations.of(context)!.tipTravel,
            index: 6,
          ),
          CategoryItem(
            iconName: "Destination",
            title: AppLocalizations.of(context)!.destination,
            index: 1,
          ),
          CategoryItem(
            iconName: "Specialities",
            title: AppLocalizations.of(context)!.localSpecialty,
            index: 2,
          ),
          CategoryItem(
            iconName: "Stay",
            title: AppLocalizations.of(context)!.accommodation,
            index: 0,
          ),
          CategoryItem(
            iconName: "EventAndFestival",
            title: AppLocalizations.of(context)!.eventAndFestival,
            index: 3,
          ),
          CategoryItem(
            iconName: "Utilities",
            title: AppLocalizations.of(context)!.utilities,
            index: 0,
          ),
        ],
      ),
    );
  }
}
