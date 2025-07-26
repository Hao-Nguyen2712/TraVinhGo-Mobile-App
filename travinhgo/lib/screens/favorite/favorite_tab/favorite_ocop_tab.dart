import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:travinhgo/widget/placeholder/empty_favorite_placeholder.dart';

import '../../../providers/favorite_provider.dart';
import '../../../widget/ocop_product_widget/ocop_product_item.dart';

class FavoriteOcopTab extends StatelessWidget {
  const FavoriteOcopTab({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = FavoriteProvider.of(context);
    final ocops = favoriteProvider.ocopProductList;

    if (ocops.isEmpty) {
      return const EmptyFavoritesPlaceholder();
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.all(2.w),
      itemCount: ocops.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4.w,
        mainAxisSpacing: 4.w,
        childAspectRatio:
            MediaQuery.of(context).orientation == Orientation.landscape
                ? 0.9
                : 0.58,
      ),
      itemBuilder: (context, index) {
        return OcopProductItem(
          ocopProduct: ocops[index],
          isAllowFavorite: true,
        );
      },
    );
  }
}
