import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import 'package:travinhgo/models/destination/destination.dart';
import 'package:travinhgo/widget/success_dialog.dart';
import 'package:travinhgo/providers/destination_type_provider.dart';
import 'package:travinhgo/screens/destination/destination_detail_screen.dart';
import 'package:travinhgo/utils/constants.dart';

import '../../Models/interaction/item_type.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/interaction_provider.dart';
import '../../utils/string_helper.dart';

class DestinationItem extends StatelessWidget {
  final Destination destination;
  final bool isAllowFavorite;

  const DestinationItem({super.key, required this.destination, required this.isAllowFavorite});

  void _showFavoriteDialog(BuildContext context, bool isFavorite) {
    final message = isFavorite
        ? AppLocalizations.of(context)!.addFavoriteSuccess
        : AppLocalizations.of(context)!.removeFavoriteSuccess;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SuccessDialog(message: message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final destinationTypeProvider = DestinationTypeProvider.of(context);
    final favoriteProvider = FavoriteProvider.of(context);
    final interactionProvider = InteractionProvider.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        interactionProvider.addInterac(destination.id, ItemType.Destination);
        context.push('/tourist-destination-detail/${destination.id}');
      },
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.sp),
                color: isDarkMode
                    ? colorScheme.surfaceVariant
                    : colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(0, 4),
                  )
                ]),
            child: Padding(
              padding: EdgeInsets.all(2.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 18.h,
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            width: 40.w,
                            height: 20.h,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15.sp),
                                image: DecorationImage(
                                    image: NetworkImage(destination.images[0]),
                                    fit: BoxFit.cover)),
                          ),
                        ),
                        if (isAllowFavorite) Positioned(
                          top: 1.h,
                          right: 2.w,
                          child: GestureDetector(
                            onTap: () {
                              final isCurrentlyFavorite =
                                  favoriteProvider.isExist(destination.id);
                              favoriteProvider
                                  .toggleDestinationFavorite(destination);
                              _showFavoriteDialog(
                                  context, !isCurrentlyFavorite);
                            },
                            child: Icon(
                              favoriteProvider.isExist(destination.id)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: colorScheme.error,
                              size: 16.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 0.5.h,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          StringHelper.toTitleCase(destination.name),
                          maxLines: 2,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? Colors.white
                                  : colorScheme.primary,
                              fontSize: 16.sp,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Row(
                          children: [
                            Text(
                              destination.avarageRating.toStringAsFixed(1),
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  color: isDarkMode ? Colors.white70 : null),
                            ),
                            SizedBox(width: 1.w),
                            ...List.generate(5, (index) {
                              double rating = destination.avarageRating;
                              if (index < rating.floor()) {
                                return Icon(Icons.star,
                                    color: colorScheme.secondary, size: 14.sp);
                              } else if (index < rating &&
                                  rating - index >= 0.5) {
                                return Icon(Icons.star_half,
                                    color: colorScheme.secondary, size: 14.sp);
                              } else {
                                return Icon(Icons.star_border,
                                    color: colorScheme.secondary, size: 14.sp);
                              }
                            }),
                          ],
                        ),
                        Row(
                          children: [
                            Image.network(
                              destinationTypeProvider
                                      .getDestinationtypeById(
                                          destination.destinationTypeId)
                                      .marker
                                      ?.image ??
                                  '',
                              width: 6.w,
                              height: 6.w,
                            ),
                            SizedBox(
                              width: 1.5.w,
                            ),
                            Expanded(
                              child: Text(
                                destination.address.toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                                style: TextStyle(
                                    fontSize: 14.sp,
                                    color: isDarkMode ? Colors.white70 : null),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
