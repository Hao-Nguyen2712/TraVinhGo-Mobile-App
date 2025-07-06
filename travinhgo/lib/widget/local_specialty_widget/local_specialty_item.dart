import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travinhgo/models/local_specialties/local_specialties.dart';
import 'package:travinhgo/providers/favorite_provider.dart';

import '../../utils/string_helper.dart';
import '../../Models/interaction/item_type.dart';
import '../../providers/interaction_provider.dart';

class LocalSpecialtyItem extends StatelessWidget {
  final LocalSpecialties localSpecialty;

  const LocalSpecialtyItem({super.key, required this.localSpecialty});

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = FavoriteProvider.of(context);
    final interactionProvider = InteractionProvider.of(context);

    return GestureDetector(
      onTap: () {
        interactionProvider.addInterac(
            localSpecialty.id, ItemType.LocalSpecialties);
        context.pushNamed(
          'LocalSpecialtyDetail',
          pathParameters: {'id': localSpecialty.id},
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 4,
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            // Image with Favorite Icon
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Image.network(
                    localSpecialty.images.first,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        favoriteProvider
                            .toggleLocalSpecialtiesFavorite(localSpecialty);
                      },
                      child: Icon(
                        favoriteProvider.isExist(localSpecialty.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Theme.of(context).colorScheme.error,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Name + Icon
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Icon (ví dụ dùng icon cục gạch tạm)
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.ramen_dining,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Text
                  Expanded(
                    child: Text(
                      StringHelper.toTitleCase(localSpecialty.foodName),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
