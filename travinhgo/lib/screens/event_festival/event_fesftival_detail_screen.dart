import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travinhgo/models/event_festival/event_and_festival.dart';
import 'package:travinhgo/services/event_festival_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../providers/tag_provider.dart';
import '../../utils/constants.dart';
import '../../utils/string_helper.dart';
import '../../widget/event_festival_widget/event_festival_content_tab.dart';
import '../../widget/event_festival_widget/event_festival_image_slider_tab.dart';
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
  bool _isLoading = true;

  late List<Widget> screensTab;

  @override
  void initState() {
    super.initState();
    fetchEventFestival(widget.id);
  }

  Future<void> preloadImages(List<String> urls) async {
    if (!mounted) return;
    await Future.wait(urls.map(
      (url) => precacheImage(CachedNetworkImageProvider(url), context),
    ));
  }

  Future<void> fetchEventFestival(String id) async {
    final data = await EventFestivalService().getDestinationById(id);

    if (data == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.noEventFound)),
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
          EventFestivalContentTab(description: eventAndFestival.description),
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      expandedHeight: 250.0,
                      floating: false,
                      pinned: true,
                      stretch: true,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      leading: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                      ),
                      actions: [
                        Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.favorite_border,
                                color: Colors.white),
                            onPressed: () {},
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.share, color: Colors.white),
                            onPressed: () {},
                          ),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: PageView.builder(
                          itemCount: eventAndFestival.images.length,
                          itemBuilder: (context, index) {
                            return CachedNetworkImage(
                              imageUrl: eventAndFestival.images[index],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            );
                          },
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              StringHelper.toTitleCase(
                                  eventAndFestival.nameEvent),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Image.network(
                                  tagProvider
                                      .getTagById(eventAndFestival.tagId)
                                      .image,
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  StringHelper.toTitleCase(
                                      eventAndFestival.category),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          labelColor: Theme.of(context).colorScheme.primary,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Theme.of(context).colorScheme.primary,
                          tabs: [
                            Tab(
                                text:
                                    AppLocalizations.of(context)!.information),
                            Tab(text: AppLocalizations.of(context)!.content),
                            Tab(text: AppLocalizations.of(context)!.pictures),
                          ],
                        ),
                      ),
                      pinned: true,
                    ),
                  ];
                },
                body: TabBarView(
                  children: screensTab,
                ),
              ),
        bottomNavigationBar: _isLoading ? null : _buildBottomButtons(context),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.event_available, color: Colors.white),
                label: const Text(
                  "Tham gia sự kiện",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF39B54A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.directions),
                label: const Text("Chỉ đường"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
