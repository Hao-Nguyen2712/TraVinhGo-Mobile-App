import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:travinhgo/models/Tag/Tag.dart';
import 'package:travinhgo/models/destination/destination.dart';
import 'package:travinhgo/providers/tag_provider.dart';
import 'package:travinhgo/services/destination_service.dart';

import '../../utils/constants.dart';
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

  @override
  void initState() {
    fetchDestination(widget.id);
    super.initState();
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

    if (mounted) {
      setState(() {
        destinationDetail = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagProvider = TagProvider.of(context);
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                                if (index + 1 <
                                    destinationDetail.images.length) {
                                  precacheImage(
                                      CachedNetworkImageProvider(
                                          destinationDetail.images[index + 1]),
                                      context);
                                }
                                if (index - 1 >= 0) {
                                  precacheImage(
                                      CachedNetworkImageProvider(
                                          destinationDetail.images[index - 1]),
                                      context);
                                }
                              },
                              imageList: destinationDetail.images,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 8,
                        right: 8,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                              destinationDetail.images.length,
                              (index) => AnimatedContainer(
                                    duration: const Duration(microseconds: 300),
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
                                  fontSize: 25, fontWeight: FontWeight.bold),
                            )),
                        const SizedBox(
                          height: 8,
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
