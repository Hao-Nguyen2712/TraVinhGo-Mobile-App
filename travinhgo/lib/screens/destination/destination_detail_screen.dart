import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:travinhgo/models/destination/destination.dart';
import 'package:travinhgo/providers/tag_provider.dart';
import 'package:travinhgo/services/destination_service.dart';
import 'package:travinhgo/widget/data_field_row.dart';
import 'package:travinhgo/widget/description_fm.dart';

import '../../providers/destination_type_provider.dart';
import '../../Models/interaction/item_type.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/interaction_log_provider.dart';
import '../../utils/constants.dart';
import '../../utils/string_helper.dart';
import '../../widget/destination_widget/destination_detail_image_slider.dart';

class DestinationDetailScreen extends StatefulWidget {
  final String id;

  const DestinationDetailScreen({super.key, required this.id});

  @override
  State<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  int currentImage = 0;
  int cuttentIndex = 0;
  late Destination destinationDetail;
  bool _isLoading = true;
  bool _isExpanded = false;

  late String desc;
  late String history;

  late List<String> allImageDestination;

  Timer? _interactionTimer;

  var ratingData = [
    {'stars': 5, 'percent': 88},
    {'stars': 4, 'percent': 47},
    {'stars': 3, 'percent': 20},
    {'stars': 2, 'percent': 8},
    {'stars': 1, 'percent': 3},
  ];

  @override
  void initState() {
    super.initState();
    fetchDestination(widget.id);

    // Đặt timer 8 giây để log interaction
    _interactionTimer = Timer(Duration(seconds: 8), () {
      // Gọi provider để add log
      final interactionLogProvider = InteractionLogProvider.of(context, listen: false);
      interactionLogProvider.addInteracLog(
        widget.id,
        ItemType.Destination,
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

  Future<void> fetchDestination(String id) async {
    final data = await DestinationService().getDestinationById(id);
    if (data == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No destination found')),
        );
        Navigator.pop(context);
      }
      return;
    }

    preloadImages(data.images);
    if (data.historyStory != null &&
        data.historyStory?.images?.isNotEmpty == true) {
      preloadImages(data.historyStory!.images!);
    }

    if (mounted) {
      setState(() {
        destinationDetail = data;
        desc = (destinationDetail.description ?? '').trim();
        history = (destinationDetail.historyStory?.content ?? '').trim();
        allImageDestination = [
          ...destinationDetail.images,
          ...?destinationDetail.historyStory?.images
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinationTypeProvider = DestinationTypeProvider.of(context);
    final favoriteProvider = FavoriteProvider.of(context);

    void _toggleExpanded() {
      setState(() {
        _isExpanded = !_isExpanded;
      });
    }

    final tagProvider = TagProvider.of(context);
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
                        SingleChildScrollView(
                          child: Column(
                            children: [
                              DestinationDetailImageSlider(
                                onChange: (index) {
                                  setState(() {
                                    currentImage = index;
                                  });
                                  // Preload ảnh liền kề để tránh load chậm khi vuốt nhanh
                                  if (index + 1 < allImageDestination.length) {
                                    precacheImage(
                                        CachedNetworkImageProvider(
                                            allImageDestination[index + 1]),
                                        context);
                                  }
                                  if (index - 1 >= 0) {
                                    precacheImage(
                                        CachedNetworkImageProvider(
                                            allImageDestination[index - 1]),
                                        context);
                                  }
                                },
                                imageList: allImageDestination,
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 8,
                          right: 8,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                              Navigator.pop(context);
                                            },
                                            icon: Image.asset(
                                                'assets/images/navigations/leftarrowwhile.png')),
                                      ),
                                    )),
                                // Text(
                                //   'Destination Detail',
                                //   style: const TextStyle(
                                //       color: Colors.white,
                                //       fontSize: 18,
                                //       fontWeight: FontWeight.bold),
                                // ),
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
                                          Navigator.pop(context);
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
                                allImageDestination.length,
                                (index) => AnimatedContainer(
                                      duration:
                                          const Duration(microseconds: 300),
                                      width: 20,
                                      height: 8,
                                      margin: EdgeInsets.only(right: 3),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
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
                                  .toggleDestinationFavorite(destinationDetail);
                            },
                            child: Icon(
                              favoriteProvider.isExist(destinationDetail.id)
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
                                    .getTagById(destinationDetail.tagId)
                                    .image,
                                width: 36,
                                height: 36,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Text(
                                "Destination",
                                style: TextStyle(fontSize: 16),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.favorite_sharp,
                                color: Colors.red,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Text(
                                "82",
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(
                                width: 6,
                              ),
                              Text(
                                "favorite",
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                destinationDetail.name,
                                style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    color: kprimaryColor),
                              )),
                          const SizedBox(
                            height: 8,
                          ),
                          if (desc.isNotEmpty || history.isNotEmpty)
                            DescriptionFm(
                              description: [desc, history]
                                  .where((e) => e.isNotEmpty)
                                  .join('<br>'),
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
                                "Opening hours",
                                style: TextStyle(fontSize: 16),
                              ),
                              Spacer(),
                              Text(
                                "Opening",
                                style: TextStyle(
                                    fontSize: 16, color: kprimaryColor),
                              ),
                              const SizedBox(
                                width: 6,
                              ),
                              if (destinationDetail.openingHours != null)
                                Text(
                                  '${destinationDetail.openingHours?.openTime.toString() ?? 'N/A'} - ${destinationDetail.openingHours?.closeTime.toString() ?? 'N/A'}',
                                  style: TextStyle(fontSize: 16),
                                )
                              else
                                Text(
                                  "N/A",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                            ],
                          ),
                          Divider(
                            color: Colors.grey.withOpacity(0.1),
                            thickness: 0.4,
                            height: 10,
                          ),
                          DataFieldRow(
                            title: 'Ticket',
                            value: StringHelper.normalizeName(
                                    destinationDetail.ticket) ??
                                "N/A",
                          ),
                          DataFieldRow(
                            title: 'Type',
                            value: StringHelper.toTitleCase(
                                destinationTypeProvider
                                    .getDestinationtypeById(
                                        destinationDetail.destinationTypeId)
                                    .name),
                          ),
                          DataFieldRow(
                            title: 'Address',
                            value: destinationDetail.address,
                          ),
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Location',
                                style: TextStyle(
                                    fontSize: 24, color: kprimaryColor),
                              )),
                          Divider(
                            color: Colors.grey.withOpacity(0.1),
                            thickness: 0.4,
                            height: 10,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Rating (${destinationDetail.avarageRating})',
                                style: TextStyle(
                                    fontSize: 24, color: kprimaryColor),
                              )),
                          Column(
                            children: ratingData.map((data) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    Text('${data['stars']}'),
                                    const SizedBox(width: 4),
                                    Icon(Icons.star,
                                        color: Colors.amber, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Container(
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade300,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                          FractionallySizedBox(
                                            widthFactor:
                                                (data['percent']! as int) / 100,
                                            child: Container(
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: Colors.amber,
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${data['percent']}%'),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
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
