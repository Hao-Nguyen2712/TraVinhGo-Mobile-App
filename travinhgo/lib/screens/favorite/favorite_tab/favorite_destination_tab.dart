import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../providers/favorite_provider.dart';
import '../../../widget/destination_widget/destination_item.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FavoriteDestinationTab extends StatelessWidget {
  const FavoriteDestinationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = FavoriteProvider.of(context);
    final destinations = favoriteProvider.destinationList;

    if (destinations.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.noFavoriteDestinations),
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
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
        );
      },
    );
  }
}
