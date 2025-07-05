import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travinhgo/models/ocop/ocop_product.dart';
import 'package:travinhgo/services/ocop_product_service.dart';

import '../../providers/favorite_provider.dart';
import '../../providers/interaction_log_provider.dart';
import '../../providers/tag_provider.dart';
import '../../utils/constants.dart';
import '../../Models/interaction/item_type.dart';
import '../../utils/string_helper.dart';
import '../../widget/data_field_row.dart';
import '../../widget/description_fm.dart';
import '../../widget/destination_widget/destination_detail_image_slider.dart';
import '../../widget/ocop_product_widget/rating_star_widget.dart';

class OcopProductDetailScreen extends StatefulWidget {
  final String id;

  const OcopProductDetailScreen({super.key, required this.id});

  @override
  State<OcopProductDetailScreen> createState() =>
      _OcopProductDetailScreenState();
}

class _OcopProductDetailScreenState extends State<OcopProductDetailScreen> {
  int currentImage = 0;
  int cuttentIndex = 0;
  late OcopProduct ocopProductDetail;
  bool _isLoading = true;
  bool _isExpanded = false;

  Timer? _interactionTimer;

  @override
  void initState() {
    super.initState();
    fetchOcopProduct(widget.id);

    // Đặt timer 8 giây để log interaction
    _interactionTimer = Timer(Duration(seconds: 8), () {
      // Gọi provider để add log
      final interactionLogProvider =
          InteractionLogProvider.of(context, listen: false);
      interactionLogProvider.addInteracLog(
        widget.id,
        ItemType.OcopProduct,
        8,
      );
    });
  }

  @override
  void dispose() {
    _interactionTimer?.cancel();
    super.dispose();
  }

  Future<void> preloadImages(List<String> urls) async {
    await Future.wait(urls.map(
      (url) => precacheImage(CachedNetworkImageProvider(url), context),
    ));
  }

  Future<void> fetchOcopProduct(String id) async {
    final data = await OcopProductService().getOcopProductById(id);

    if (data == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No ocop product found')),
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.pop();
          }
        });
      }
      return;
    }

    await preloadImages(data.productImage);

    if (mounted) {
      setState(() {
        ocopProductDetail = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagProvider = TagProvider.of(context);
    final favoriteProvider = FavoriteProvider.of(context);
    void _toggleExpanded() {
      setState(() {
        _isExpanded = !_isExpanded;
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          DestinationDetailImageSlider(
                            onChange: (index) {
                              setState(() {
                                currentImage = index;
                              });
                              // Preload ảnh liền kề để tránh load chậm khi vuốt nhanh
                              if (index + 1 <
                                  ocopProductDetail.productImage.length) {
                                precacheImage(
                                    CachedNetworkImageProvider(ocopProductDetail
                                        .productImage[index + 1]),
                                    context);
                              }
                              if (index - 1 >= 0) {
                                precacheImage(
                                    CachedNetworkImageProvider(ocopProductDetail
                                        .productImage[index - 1]),
                                    context);
                              }
                            },
                            imageList: ocopProductDetail.productImage,
                          ),
                          Positioned(
                            top: 12,
                            left: 8,
                            right: 8,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey.withOpacity(0.5),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Center(
                                          child: IconButton(
                                              onPressed: () {
                                                context.pop();
                                              },
                                              icon: Image.asset(
                                                  'assets/images/navigations/leftarrowwhile.png')),
                                        ),
                                      )),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.withOpacity(0.5),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: IconButton(
                                          iconSize: 18,
                                          onPressed: () {},
                                          icon: Image.asset(
                                              'assets/images/navigations/share.png')),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 230,
                            left: 8,
                            right: 8,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                  ocopProductDetail.productImage.length,
                                  (index) => AnimatedContainer(
                                        duration:
                                            const Duration(microseconds: 300),
                                        width: 20,
                                        height: 8,
                                        margin: EdgeInsets.only(right: 3),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: currentImage == index
                                              ? Colors.white
                                              : Colors.grey,
                                        ),
                                      )),
                            ),
                          ),
                          Positioned(
                            top: 210,
                            right: 16,
                            child: GestureDetector(
                              onTap: () {
                                favoriteProvider
                                    .toggleOcopFavorite(ocopProductDetail);
                              },
                              child: Icon(
                                favoriteProvider.isExist(ocopProductDetail.id)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Image.network(
                                  tagProvider
                                      .getTagById(ocopProductDetail.tagId)
                                      .image,
                                  width: 36,
                                  height: 36,
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  "Local Specialty",
                                  style: TextStyle(fontSize: 16),
                                ),
                                const Spacer(),
                              ],
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  StringHelper.toTitleCase(
                                      ocopProductDetail.productName),
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: kprimaryColor),
                                )),
                            const SizedBox(
                              height: 8,
                            ),
                            if (ocopProductDetail.productDescription != null)
                              DescriptionFm(
                                description:
                                    ocopProductDetail.productDescription,
                                isExpanded: _isExpanded,
                                onToggle: _toggleExpanded,
                              ),
                            Divider(
                              color: Colors.grey.withOpacity(0.1),
                              thickness: 0.4,
                              height: 10,
                            ),
                            Row(
                              children: [
                                Text(
                                  "Place of production",
                                  style: TextStyle(fontSize: 16),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: 200,
                                  child: Text(
                                    StringHelper.toUpperCase(
                                        "cty tnhh tra vinh farm"),
                                    style: TextStyle(
                                        fontSize: 18, color: kprimaryColor),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              ],
                            ),
                            Divider(
                              color: Colors.grey.withOpacity(0.1),
                              thickness: 0.4,
                              height: 10,
                            ),
                            Row(
                              children: [
                                Text(
                                  "Reference Price",
                                  style: TextStyle(fontSize: 16),
                                ),
                                const Spacer(),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: StringHelper.formatCurrency(
                                            ocopProductDetail.productPrice),
                                        style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w800),
                                      ),
                                      const TextSpan(
                                        text: ' vnd',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                              color: Colors.grey.withOpacity(0.1),
                              thickness: 0.4,
                              height: 10,
                            ),
                            Row(
                              children: [
                                Text(
                                  "Reference Price",
                                  style: TextStyle(fontSize: 16),
                                ),
                                const Spacer(),
                                RatingStarWidget(ocopProductDetail.ocopPoint)
                              ],
                            ),
                            Divider(
                              color: Colors.grey.withOpacity(0.1),
                              thickness: 0.4,
                              height: 10,
                            ),
                            DataFieldRow(
                              title: 'Year Release',
                              value:
                                  ocopProductDetail.ocopYearRelease.toString(),
                            ),
                            DataFieldRow(
                              title: 'Year Release',
                              value:
                                  ocopProductDetail.ocopYearRelease.toString(),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                )),
    );
  }
}
