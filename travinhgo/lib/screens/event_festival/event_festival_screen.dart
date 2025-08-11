import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../providers/event_festival_provider.dart';
import '../../utils/constants.dart';
import '../../widget/event_festival_widget/event_festival_item.dart';

class EventFestivalScreen extends StatelessWidget {
  const EventFestivalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EventFestivalProvider(),
      child: const _EventFestivalView(),
    );
  }
}

class _EventFestivalView extends StatefulWidget {
  const _EventFestivalView();

  @override
  State<_EventFestivalView> createState() => _EventFestivalViewState();
}

class _EventFestivalViewState extends State<_EventFestivalView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventFestivalProvider>(context, listen: false)
          .fetchEventFestivals(isRefresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final provider = Provider.of<EventFestivalProvider>(context, listen: false);
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !provider.isLoadingMore &&
        provider.hasMore) {
      provider.fetchEventFestivals();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final provider =
          Provider.of<EventFestivalProvider>(context, listen: false);
      provider.applySearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: theme.colorScheme.primary,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          top: false,
          child: Consumer<EventFestivalProvider>(
            builder: (context, provider, child) {
              return RefreshIndicator(
                onRefresh: () => provider.fetchEventFestivals(isRefresh: true),
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverAppBar(
                      floating: true,
                      snap: true,
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      title: Text(
                        AppLocalizations.of(context)!.eventAndFestival,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      centerTitle: true,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildSearchBar(context),
                    ),
                    if (provider.isLoading && provider.eventFestivals.isEmpty)
                      const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      )
                    else if (provider.errorMessage != null)
                      SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                                AppLocalizations.of(context)!
                                    .errorPrefix(provider.errorMessage!),
                                style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black)),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            childAspectRatio: 1.4,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return EventFestivalItem(
                                eventAndFestival:
                                    provider.eventFestivals[index],
                              );
                            },
                            childCount: provider.eventFestivals.length,
                          ),
                        ),
                      ),
                    if (provider.isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchEventOrFestival,
          hintStyle:
              TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey),
          prefixIcon: Icon(Icons.search,
              color: isDarkMode ? Colors.white70 : Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(60),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDarkMode
              ? theme.colorScheme.surfaceVariant
              : kSearchBackgroundColor,
        ),
      ),
    );
  }
}
