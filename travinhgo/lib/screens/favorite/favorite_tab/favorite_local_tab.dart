import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../providers/favorite_provider.dart';
import '../../../widget/local_specialty_widget/local_specialty_item.dart';

class FavoriteLocalTab extends StatelessWidget {
  const FavoriteLocalTab({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = FavoriteProvider.of(context);
    final locals = favoriteProvider.localSpecialteList;

    if (locals.isEmpty) {
      return const Center(
        child: Text('There are no favorite local specialte.'),
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
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
