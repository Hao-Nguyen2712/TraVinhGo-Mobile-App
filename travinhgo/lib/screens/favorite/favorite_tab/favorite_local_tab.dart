import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.all(8.0), // padding ở đây
      itemCount: locals.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        return LocalSpecialtyItem(
          localSpecialty: locals[index],
        );
      },
    );
  }
}
