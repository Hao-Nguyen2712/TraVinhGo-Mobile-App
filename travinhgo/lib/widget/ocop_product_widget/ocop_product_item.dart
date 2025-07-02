import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travinhgo/models/ocop/ocop_product.dart';
import 'package:travinhgo/widget/ocop_product_widget/rating_star_widget.dart';

import '../../providers/favorite_provider.dart';
import '../../utils/constants.dart';
import '../../utils/string_helper.dart';

class OcopProductItem extends StatelessWidget {
  final OcopProduct ocopProduct;

  const OcopProductItem({super.key, required this.ocopProduct});

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = FavoriteProvider.of(context);

    return GestureDetector(
      onTap: () {
        context.pushNamed(
          'OcopProductDetail',
          pathParameters: {'id': ocopProduct.id},
        );
      },
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: kcontentColor,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(0, 4),
                  )
                ]),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Stack(
                    children: [
                      Center(
                        child: Container(
                          width: 175,
                          height: 190,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              image: DecorationImage(
                                  image: NetworkImage(ocopProduct.productImage[0]),
                                  fit: BoxFit.cover)),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 12,
                        child: GestureDetector(
                          onTap: () {
                            favoriteProvider
                                .toggleOcopFavorite(ocopProduct);
                          },
                          child: Icon(
                            favoriteProvider.isExist(ocopProduct.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.red,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    StringHelper.toTitleCase(ocopProduct.productName),
                    maxLines: 2,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kprimaryColor,
                        fontSize: 16,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  RatingStarWidget(ocopProduct.ocopPoint),
                  const SizedBox(
                    height: 2,
                  ),
                  Row(
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: StringHelper.formatCurrency(
                                  ocopProduct.productPrice),
                              style: const TextStyle(
                                  fontSize: 16, color: kpriceColor),
                            ),
                            const TextSpan(
                              text: ' vnd',
                              style: TextStyle(
                                fontSize: 14,
                                color: kpriceColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        "Buy at",
                        style: TextStyle(fontSize: 14, color: kprimaryColor),
                      ),
                      const SizedBox(width: 4),
                      Image.asset(
                        "assets/images/navigations/external-link.png",
                        scale: 0.7,
                        fit: BoxFit.contain,
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
