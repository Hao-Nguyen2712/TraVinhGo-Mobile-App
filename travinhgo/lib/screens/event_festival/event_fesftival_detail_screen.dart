import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travinhgo/models/event_festival/event_and_festival.dart';
import 'package:travinhgo/services/event_festival_service.dart';

import '../../providers/tag_provider.dart';
import '../../utils/constants.dart';
import '../../utils/string_helper.dart';
import '../../widget/event_festival_widget/event_festival_image_slider_tab.dart';
import '../../widget/event_festival_widget/description_event_tab.dart';
import '../../widget/event_festival_widget/event_festival_information_tab.dart';

class EventFesftivalDetailScreen extends StatefulWidget {
  final String id;

  const EventFesftivalDetailScreen({super.key, required this.id});

  @override
  State<EventFesftivalDetailScreen> createState() =>
      _EventFesftivalDetailScreenState();
}

class _EventFesftivalDetailScreenState
    extends State<EventFesftivalDetailScreen> {
  late EventAndFestival eventAndFestival;
  int currentIndexTab = 0;
  bool _isLoading = true;

  late List<Widget> screensTab;

  @override
  void initState() {
    fetchEventFestival(widget.id);
    super.initState();
  }

  Future<void> preloadImages(List<String> urls) async {
    await Future.wait(urls.map(
      (url) => precacheImage(CachedNetworkImageProvider(url), context),
    ));
  }

  Future<void> fetchEventFestival(String id) async {
    final data = await EventFestivalService().getDestinationById(id);

    if (data == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No event and festival found')),
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
        eventAndFestival = data;
        screensTab = [
          EventFestivalInformationTab(
            eventAndFestival: eventAndFestival,
          ),
          DescriptionEventTab(description: eventAndFestival.description),
          EventFestivalImageSliderTab(
            onChange: (index) {},
            imageList: eventAndFestival.images,
          ),
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagProvider = TagProvider.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 300,
                        child: Stack(
                          children: [
                            ClipRRect(
                              child: CachedNetworkImage(
                                imageUrl: eventAndFestival.images.first,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withOpacity(1),
                                    ],
                                  ),
                                ),
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
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Column(
                          children: [
                            Align(
                                alignment: Alignment.center,
                                child: Text(
                                  StringHelper.toTitleCase(
                                      eventAndFestival.nameEvent),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: kprimaryColor),
                                )),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Image.network(
                                  tagProvider
                                      .getTagById(eventAndFestival.tagId)
                                      .image,
                                  width: 36,
                                  height: 36,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  StringHelper.toTitleCase(
                                      eventAndFestival.category),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 50),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      this.currentIndexTab = 0;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 1),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(13),
                                        bottomRight: Radius.circular(13),
                                      ),
                                    ),
                                    side: BorderSide(
                                        color: Colors.grey.withOpacity(0.3)),
                                    backgroundColor: this.currentIndexTab == 0
                                        ? kprimaryColor
                                        : Colors.white,
                                  ),
                                  child: Text(
                                    "Information",
                                    style: TextStyle(
                                        color: this.currentIndexTab == 0
                                            ? Colors.white
                                            : kprimaryColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900),
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      this.currentIndexTab = 1;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 1),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(13),
                                        bottomRight: Radius.circular(13),
                                      ),
                                    ),
                                    side: BorderSide(
                                        color: Colors.grey.withOpacity(0.3)),
                                    backgroundColor: this.currentIndexTab == 1
                                        ? kprimaryColor
                                        : Colors.white,
                                  ),
                                  child: Text(
                                    "Content",
                                    style: TextStyle(
                                        color: this.currentIndexTab == 1
                                            ? Colors.white
                                            : kprimaryColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900),
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      this.currentIndexTab = 2;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 18),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(13),
                                        bottomRight: Radius.circular(13),
                                      ),
                                    ),
                                    side: BorderSide(
                                        color: Colors.grey.withOpacity(0.3)),
                                    backgroundColor: this.currentIndexTab == 2
                                        ? kprimaryColor
                                        : Colors.white,
                                  ),
                                  child: Text(
                                    "Pictures",
                                    style: TextStyle(
                                        color: this.currentIndexTab == 2
                                            ? Colors.white
                                            : kprimaryColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                                margin: const EdgeInsets.only(top: 3),
                                color: Colors.grey.withOpacity(0.3),
                                height: 1.3),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      screensTab[currentIndexTab],
                    ],
                  ),
                )),
    );
  }
}
