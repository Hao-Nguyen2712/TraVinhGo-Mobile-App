import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import 'package:travinhgo/models/ocop/ocop_product.dart';
import 'package:travinhgo/services/ocop_product_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../Models/selling_link/selling_link.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/interaction_log_provider.dart';
import '../../providers/tag_provider.dart';
import '../../services/auth_service.dart';
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

  late bool isAuthen;

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
    var sessionId =  await AuthService().getSessionId();
    setState(() {
      _sellingLinks = data;
      isAuthen = sessionId != null;
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
                            top: 2.h,
                            left: 2.w,
                            right: 2.w,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 2.w),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                      width: 10.w,
                                      height: 10.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(1.w),
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
                                    width: 10.w,
                                    height: 10.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(0.5.w),
                                      child: IconButton(
                                          iconSize: 18.sp,
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
                            top: 23.h,
                            left: 2.w,
                            right: 2.w,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                  ocopProductDetail.productImage.length,
                                  (index) => AnimatedContainer(
                                        duration:
                                            const Duration(microseconds: 300),
                                        width: 5.w,
                                        height: 1.h,
                                        margin: EdgeInsets.only(right: 1.w),
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
                          if (isAuthen) Positioned(
                            top: 19.h,
                            right: 4.w,
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
                                size: 24.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 1.h,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Image.network(
                                  tagProvider
                                      .getTagById(ocopProductDetail.tagId)
                                      .image,
                                  width: 9.w,
                                  height: 9.w,
                                ),
                                SizedBox(
                                  width: 2.w,
                                ),
                                Text(
                                  AppLocalizations.of(context)!.ocopProduct,
                                  style: TextStyle(fontSize: 12.sp),
                                ),
                                const Spacer(),
                              ],
                            ),
                            SizedBox(
                              height: 1.h,
                            ),
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  StringHelper.toTitleCase(
                                      ocopProductDetail.productName),
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18.sp,
                                          color: isDarkMode
                                              ? Colors.white
                                              : colorScheme.primary),
                                )),
                            SizedBox(
                              height: 1.h,
                            ),
                            if (ocopProductDetail.productDescription != null)
                              DescriptionFm(
                                description:
                                    ocopProductDetail.productDescription,
                                isExpanded: _isExpanded,
                                onToggle: _toggleExpanded,
                              ),
                            SizedBox(height: 2.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!
                                      .placeOfProduction,
                                  style: TextStyle(fontSize: 14.sp),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: 50.w,
                                  child: Text(
                                    StringHelper.toUpperCase(
                                        ocopProductDetail.company.name),
                                    style: TextStyle(
                                        fontSize: 14.sp,
                                        color: colorScheme.primary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              ],
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.referencePrice,
                                  style: TextStyle(fontSize: 14.sp),
                                ),
                                const Spacer(),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: StringHelper.formatCurrency(
                                            ocopProductDetail.productPrice),
                                        style: TextStyle(
                                            fontSize: 14.sp,
                                            color: colorScheme.onBackground,
                                            fontWeight: FontWeight.w800),
                                      ),
                                      TextSpan(
                                        text: AppLocalizations.of(context)!
                                            .currencyVnd,
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          color: colorScheme.onBackground,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                Text(
                                  'Ocop Point',
                                  style: TextStyle(fontSize: 15.sp),
                                ),
                                const Spacer(),
                                RatingStarWidget(ocopProductDetail.ocopPoint)
                              ],
                            ),
                            SizedBox(height: 2.h),
                            DataFieldRow(
                              title: AppLocalizations.of(context)!.ocopType,
                              value: ocopProductDetail.ocopType!.ocopTypeName,
                            ),
                            SizedBox(height: 2.h),
                            DataFieldRow(
                              title: AppLocalizations.of(context)!.yearRelease,
                              value:
                                  ocopProductDetail.ocopYearRelease.toString(),
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Selling links',
                                  style: TextStyle(fontSize: 15.sp),
                                ),
                                const Spacer(),
                                SellingLinkList(sellingLinks: _sellingLinks),
                              ],
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
