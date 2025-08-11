import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import 'package:travinhgo/models/local_specialties/local_specialties.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travinhgo/widget/success_dialog.dart';

import '../../providers/favorite_provider.dart';
import '../../providers/interaction_log_provider.dart';
import '../../providers/tag_provider.dart';
import '../../services/auth_service.dart';
import '../../services/local_specialtie_service.dart';
import '../../utils/constants.dart';
import '../../Models/interaction/item_type.dart';
import '../../widget/description_fm.dart';
import '../../widget/destination_widget/destination_detail_image_slider.dart';
import '../../widget/local_specialty_widget/local_specialty_location_card.dart';

class LocalSpecialtyDetailScreen extends StatefulWidget {
  final String id;

  const LocalSpecialtyDetailScreen({super.key, required this.id});

  @override
  State<LocalSpecialtyDetailScreen> createState() =>
      _LocalSpecialtyDetailScreenState();
}

class _LocalSpecialtyDetailScreenState
    extends State<LocalSpecialtyDetailScreen> {
  int currentImage = 0;
  int cuttentIndex = 0;
  late LocalSpecialties localSpecialtyDetail;
  bool _isLoading = true;
  bool _isExpanded = false;

  late bool isAuthen;

  late String desc;

  Timer? _interactionTimer;

  @override
  void initState() {
    super.initState();
    fetchocalSpecialty(widget.id);

    // Đặt timer 8 giây để log interaction
    _interactionTimer = Timer(Duration(seconds: 8), () {
      // Gọi provider để add log
      final interactionLogProvider =
          InteractionLogProvider.of(context, listen: false);
      interactionLogProvider.addInteracLog(
        widget.id,
        ItemType.LocalSpecialties,
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

  Future<void> fetchocalSpecialty(String id) async {
    final data = await LocalSpecialtieService().getLocalSpecialtieById(id);
    var sessionId = await AuthService().getSessionId();
    if (data == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.noLocalSpecialtyFound)),
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.pop();
          }
        });
      }
      return;
    }

    await preloadImages(data.images);

    if (mounted) {
      setState(() {
        isAuthen = sessionId != null;
        localSpecialtyDetail = data;
        desc = (localSpecialtyDetail.description ?? '').trim();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagProvider = TagProvider.of(context);
    final favoriteProvider = FavoriteProvider.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
                                  localSpecialtyDetail.images.length) {
                                precacheImage(
                                    CachedNetworkImageProvider(
                                        localSpecialtyDetail.images[index + 1]),
                                    context);
                              }
                              if (index - 1 >= 0) {
                                precacheImage(
                                    CachedNetworkImageProvider(
                                        localSpecialtyDetail.images[index - 1]),
                                    context);
                              }
                            },
                            imageList: localSpecialtyDetail.images,
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
                                                context.pop();
                                              },
                                              icon: Image.asset(
                                                  'assets/images/navigations/leftarrowwhile.png')),
                                        ),
                                      )),
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
                                  localSpecialtyDetail.images.length,
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
                          if (isAuthen)
                            Positioned(
                              top: 19.h,
                              right: 4.w,
                              child: GestureDetector(
                                onTap: () {
                                  final isCurrentlyFavorited = favoriteProvider
                                      .isExist(localSpecialtyDetail.id);
                                  favoriteProvider
                                      .toggleLocalSpecialtiesFavorite(
                                          localSpecialtyDetail);
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return SuccessDialog(
                                        message: isCurrentlyFavorited
                                            ? AppLocalizations.of(context)!
                                                .favoriteRemoveMessage
                                            : AppLocalizations.of(context)!
                                                .favoriteAddMessage,
                                      );
                                    },
                                  );
                                },
                                child: Icon(
                                  favoriteProvider
                                          .isExist(localSpecialtyDetail.id)
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
                            const SizedBox(
                              height: 8,
                            ),
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  localSpecialtyDetail.foodName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                )),
                            const SizedBox(
                              height: 10,
                            ),
                            if (localSpecialtyDetail.description != null)
                              DescriptionFm(
                                description: localSpecialtyDetail.description,
                                isExpanded: _isExpanded,
                                onToggle: _toggleExpanded,
                              ),
                            const SizedBox(
                              height: 10,
                            ),
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .sellingLocations,
                                  style: TextStyle(
                                      fontSize: 24,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Theme.of(context)
                                              .colorScheme
                                              .primary),
                                )),
                            const SizedBox(height: 16),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: localSpecialtyDetail.locations.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 18,
                                mainAxisSpacing: 18,
                                childAspectRatio: 0.7,
                              ),
                              itemBuilder: (context, index) {
                                final location =
                                    localSpecialtyDetail.locations[index];
                                return LocalSpecialtyLocationCard(
                                  location: location,
                                  tagImage: tagProvider
                                      .getTagById(localSpecialtyDetail.tagId)
                                      .image,
                                );
                              },
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
