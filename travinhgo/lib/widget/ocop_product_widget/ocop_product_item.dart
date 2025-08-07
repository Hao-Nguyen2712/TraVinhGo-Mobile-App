import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import 'package:travinhgo/models/ocop/ocop_product.dart';
import 'package:travinhgo/widget/ocop_product_widget/rating_star_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travinhgo/widget/success_dialog.dart';

import '../../Models/interaction/item_type.dart';
import '../../providers/favorite_provider.dart';
import '../../utils/constants.dart';
import '../../providers/interaction_provider.dart';
import '../../utils/string_helper.dart';

class OcopProductItem extends StatelessWidget {
  final OcopProduct ocopProduct;
  final bool isAllowFavorite;

  const OcopProductItem(
      {super.key, required this.ocopProduct, required this.isAllowFavorite});

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = FavoriteProvider.of(context);
    final interactionProvider = InteractionProvider.of(context);

    return GestureDetector(
      onTap: () {
        interactionProvider.addInterac(ocopProduct.id, ItemType.OcopProduct);
        context.pushNamed(
          'OcopProductDetail',
          pathParameters: {'id': ocopProduct.id},
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.sp),
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
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
              Stack(
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 18.h,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.sp),
                          image: DecorationImage(
                              image: NetworkImage(ocopProduct.productImage[0]),
                              fit: BoxFit.cover)),
                    ),
                  ),
                  if (isAllowFavorite)
                    Positioned(
                      top: 1.h,
                      right: 3.w,
                      child: GestureDetector(
                        onTap: () {
                          final isFavorite =
                              favoriteProvider.isExist(ocopProduct.id);
                          final localizations = AppLocalizations.of(context)!;
                          favoriteProvider.toggleOcopFavorite(ocopProduct);
                          showDialog(
                            context: context,
                            builder: (context) => SuccessDialog(
                              message: isFavorite
                                  ? localizations.removeFavoriteSuccess
                                  : localizations.addFavoriteSuccess,
                            ),
                          );
                        },
                        child: Icon(
                          favoriteProvider.isExist(ocopProduct.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Theme.of(context).colorScheme.error,
                          size: 20.sp,
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 1.h),
                    Text(
                      StringHelper.toTitleCase(ocopProduct.productName),
                      maxLines: 2,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Theme.of(context).colorScheme.primary,
                          fontSize: 15.sp,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const Spacer(),
                    RatingStarWidget(ocopProduct.ocopPoint),
                    SizedBox(height: 0.5.h),
                    Builder(builder: (context) {
                      final price =
                          double.tryParse(ocopProduct.productPrice ?? '');
                      return Row(
                        children: [
                          if (price != null && price > 0)
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: StringHelper.formatCurrency(
                                        ocopProduct.productPrice!),
                                    style: TextStyle(
                                        fontSize: 16.sp,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error),
                                  ),
                                  TextSpan(
                                    text: ' vnd',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Text(
                              AppLocalizations.of(context)!.notUpdated,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          const Spacer(),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
