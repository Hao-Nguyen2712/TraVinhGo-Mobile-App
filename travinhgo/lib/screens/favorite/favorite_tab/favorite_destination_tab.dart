import 'package:flutter/material.dart';
import 'package:travinhgo/widget/placeholder/empty_favorite_placeholder.dart';

import '../../../providers/favorite_provider.dart';
import '../../../widget/destination_widget/destination_item.dart';

class FavoriteDestinationTab extends StatelessWidget {
  const FavoriteDestinationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = FavoriteProvider.of(context);
    final destinations = favoriteProvider.destinationList;

    if (destinations.isEmpty) {
      return const EmptyFavoritesPlaceholder();
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(8.0), // padding ở đây
      itemCount: destinations.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.58,
      ),
      itemBuilder: (context, index) {
        return DestinationItem(
          destination: destinations[index],
          isAllowFavorite: true,
        );
      },
    );
  }
}
