import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travinhgo/models/ocop/ocop_product.dart';
import 'package:travinhgo/services/ocop_product_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../Models/selling_link/selling_link.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/interaction_log_provider.dart';
import '../../providers/tag_provider.dart';
import '../../services/selling_link_service.dart';
import '../../utils/constants.dart';
import '../../Models/interaction/item_type.dart';
import '../../utils/string_helper.dart';
import '../../widget/data_field_row.dart';
import '../../widget/description_fm.dart';
import '../../widget/destination_widget/destination_detail_image_slider.dart';
import '../../widget/ocop_product_widget/rating_star_widget.dart';
import '../../widget/selling_link_widget/selling_link_list.dart';

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
  late List<SellingLink> _sellingLinks;

  Timer? _interactionTimer;

  @override
  void initState() {
    super.initState();
    // fetchOcopProduct(widget.id);
    loadData();
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

  Future<void> loadData() async {
    await Future.wait([
      fetchOcopProduct(widget.id),
      fetchOcopSellingLink(widget.id),
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchOcopSellingLink(String id) async {
    final data = await SellingLinkService().getSellingLinkByOcopId(id);
    setState(() {
      _sellingLinks = data;
    });
  }

  Future<void> fetchOcopProduct(String id) async {
    final data = await OcopProductService().getOcopProductById(id);

    if (data == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.noOcopProductFound)),
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagProvider = TagProvider.of(context);
    final favoriteProvider = FavoriteProvider.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    void _toggleExpanded() {
      setState(() {
        _isExpanded = !_isExpanded;
      });
    }

    return Scaffold(
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
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Center(
                                          child: IconButton(
                                              onPressed: () {
                                                if (context.canPop()) {
                                                  context.pop();
                                                } else {
                                                  context.go('/home');
                                                }
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
                                      color: Colors.black.withOpacity(0.3),
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
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.3),
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
                                color: Theme.of(context).colorScheme.error,
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
                                  AppLocalizations.of(context)!.localSpecialty,
                                  style: const TextStyle(fontSize: 16),
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
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode
                                              ? Colors.white
                                              : colorScheme.primary),
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
                              color: theme.dividerColor,
                              thickness: 0.4,
                              height: 10,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!
                                      .placeOfProduction,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: 190,
                                  child: Text(
                                    StringHelper.toUpperCase(
                                        ocopProductDetail.company.name),
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: colorScheme.primary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              ],
                            ),
                            Divider(
                              color: theme.dividerColor,
                              thickness: 0.4,
                              height: 10,
                            ),
                            Row(
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.referencePrice,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Spacer(),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: StringHelper.formatCurrency(
                                            ocopProductDetail.productPrice),
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: colorScheme.onBackground,
                                            fontWeight: FontWeight.w800),
                                      ),
                                      TextSpan(
                                        text: AppLocalizations.of(context)!
                                            .currencyVnd,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colorScheme.onBackground,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                              color: theme.dividerColor,
                              thickness: 0.4,
                              height: 10,
                            ),
                            Row(
                              children: [
                                Text(
                                  'Ocop Point',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Spacer(),
                                RatingStarWidget(ocopProductDetail.ocopPoint)
                              ],
                            ),
                            Divider(
                              color: theme.dividerColor,
                              thickness: 0.4,
                              height: 10,
                            ),
                            DataFieldRow(
                              title: 'Ocop type',
                              value: ocopProductDetail.ocopType!.ocopTypeName,
                            ),
                            DataFieldRow(
                              title: AppLocalizations.of(context)!.yearRelease,
                              value:
                                  ocopProductDetail.ocopYearRelease.toString(),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Selling links',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Spacer(),
                                SellingLinkList(sellingLinks: _sellingLinks),
                              ],
                            ),
                            Divider(
                              color: Colors.grey.withOpacity(0.1),
                              thickness: 0.4,
                              height: 10,
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
