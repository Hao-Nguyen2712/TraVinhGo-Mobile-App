import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travinhgo/models/local_specialties/local_specialties.dart';

import '../../providers/favorite_provider.dart';
import '../../providers/interaction_log_provider.dart';
import '../../providers/tag_provider.dart';
import '../../services/local_specialtie_service.dart';
import '../../utils/constants.dart';
import '../../Models/interaction/item_type.dart';
import '../../widget/description_fm.dart';
import '../../widget/destination_widget/destination_detail_image_slider.dart';

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

  late String desc;

  Timer? _interactionTimer;

  @override
  void initState() {
    super.initState();
    fetchocalSpecialty(widget.id);

    // Đặt timer 8 giây để log interaction
    _interactionTimer = Timer(Duration(seconds: 8), () {
      // Gọi provider để add log
      final interactionLogProvider = InteractionLogProvider.of(context, listen: false);
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

    if (data == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No destination found')),
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
                                          onPressed: () {
                                            context.pop();
                                          },
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
                                    .toggleLocalSpecialtiesFavorite(localSpecialtyDetail);
                              },
                              child: Icon(
                                favoriteProvider.isExist(localSpecialtyDetail.id)
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
                                      .getTagById(localSpecialtyDetail.tagId)
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
                                  localSpecialtyDetail.foodName,
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: kprimaryColor),
                                )),
                            const SizedBox(
                              height: 8,
                            ),
                            if(localSpecialtyDetail.description != null)
                              DescriptionFm(
                                description: localSpecialtyDetail.description,
                                isExpanded: _isExpanded,
                                onToggle: _toggleExpanded,
                              ),
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Selling Locations',
                                  style: TextStyle(
                                      fontSize: 24, color: kprimaryColor),
                                )),
                          ],
                        ),
                      )
                    ],
                  ),
                )),
    );
  }
}
