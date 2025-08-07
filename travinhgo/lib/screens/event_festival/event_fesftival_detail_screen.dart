import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:go_router/go_router.dart';
import 'package:travinhgo/models/event_festival/event_and_festival.dart';
import 'package:travinhgo/providers/favorite_provider.dart';
import 'package:travinhgo/services/event_festival_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../providers/tag_provider.dart';
import '../../utils/constants.dart';
import '../../utils/string_helper.dart';
import '../../widget/event_festival_widget/event_festival_content_tab.dart';
import '../../widget/event_festival_widget/event_festival_image_slider_tab.dart';
import '../../widget/event_festival_widget/event_festival_information_tab.dart';
import '../../widget/success_dialog.dart';

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
                      expandedHeight: 30.h,
                      floating: false,
                      pinned: true,
                      stretch: true,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      leading: Container(
                        margin: EdgeInsets.all(2.w),
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
                        Consumer<FavoriteProvider>(
                          builder: (context, favoriteProvider, child) {
                            final isFavorite =
                                favoriteProvider.isExist(eventAndFestival.id);
                            return Container(
                              margin: EdgeInsets.all(2.w),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : Colors.white,
                                ),
                                onPressed: () {
                                  final isFavorite = favoriteProvider
                                      .isExist(eventAndFestival.id);
                                  final localizations =
                                      AppLocalizations.of(context)!;
                                  favoriteProvider.toggleEventFestivalFavorite(
                                      eventAndFestival);
                                  showDialog(
                                    context: context,
                                    builder: (context) => SuccessDialog(
                                      message: isFavorite
                                          ? localizations.removeFavoriteSuccess
                                          : localizations.addFavoriteSuccess,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
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
                        padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 2.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 65.w,
                                  child: Text(
                                    StringHelper.toTitleCase(
                                        eventAndFestival.nameEvent),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                _buildStatusBadge(),
                              ],
                            ),
                            SizedBox(height: 0.5.h),
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

  Widget _buildStatusBadge() {
    final now = DateTime.now();
    final localizations = AppLocalizations.of(context)!;
    String statusText;
    Color statusColor;

    final nowDate = DateUtils.dateOnly(now);
    final startDate = DateUtils.dateOnly(eventAndFestival.startDate);
    final endDate = DateUtils.dateOnly(eventAndFestival.endDate);

    if (nowDate.isAfter(endDate)) {
      statusText = localizations.eventStatusEnded;
      statusColor = Colors.red;
    } else if (!nowDate.isBefore(startDate) && !nowDate.isAfter(endDate)) {
      statusText = localizations.eventStatusOngoing;
      statusColor = Colors.green;
    } else {
      statusText = localizations.eventStatusUpcoming;
      statusColor = Colors.blueAccent;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(15.sp),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
        child: Row(
          children: [
            SizedBox(width: 2.w),
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                onPressed: () {
                  final location = eventAndFestival.location.location;
                  if (location.coordinates != null &&
                      location.coordinates!.length == 2) {
                    final lat = location.coordinates![1];
                    final lng = location.coordinates![0];
                    context.goNamed('map_shell', extra: {
                      'latitude': lat,
                      'longitude': lng,
                      'name': eventAndFestival.nameEvent
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(AppLocalizations.of(context)!
                              .locationNotAvailable)),
                    );
                  }
                },
                icon: const Icon(Icons.directions),
                label: Text(
                  AppLocalizations.of(context)!.directions,
                  style: TextStyle(fontSize: 16.sp),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF39B54A),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.sp),
                  ),
                ),
              ),
            ),
            SizedBox(width: 2.w),
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
