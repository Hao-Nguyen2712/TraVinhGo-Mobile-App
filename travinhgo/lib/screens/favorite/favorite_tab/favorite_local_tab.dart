import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:travinhgo/widget/placeholder/empty_favorite_placeholder.dart';

import '../../../providers/favorite_provider.dart';
import '../../../widget/local_specialty_widget/local_specialty_item.dart';

class FavoriteLocalTab extends StatelessWidget {
  const FavoriteLocalTab({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = FavoriteProvider.of(context);
    final locals = favoriteProvider.localSpecialteList;

    if (locals.isEmpty) {
      return const EmptyFavoritesPlaceholder();
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.all(2.w),
      itemCount: locals.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio:
            MediaQuery.of(context).orientation == Orientation.landscape
                ? 3
                : 1.5,
      ),
      itemBuilder: (context, index) {
        return LocalSpecialtyItem(
          localSpecialty: locals[index],
          isAllowFavorite: true,
        );
      },
    );
  }
}
