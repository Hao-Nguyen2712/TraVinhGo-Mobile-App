import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';

import '../../models/destination/destination.dart';
import '../../providers/destination_provider.dart';
import '../../widget/destination_widget/destination_item.dart';

class DestinationScreen extends StatefulWidget {
  const DestinationScreen({super.key});

  @override
  State<DestinationScreen> createState() => _DestinationScreenState();
}

class _DestinationScreenState extends State<DestinationScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedDestinationTypeId;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DestinationProvider>(context, listen: false);
      provider.fetchDestinations(isRefresh: true);
      provider.fetchDestinationTypes();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = Provider.of<DestinationProvider>(context, listen: false);
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !provider.isLoadingMore &&
        provider.hasMore) {
      provider.fetchDestinations();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final provider = Provider.of<DestinationProvider>(context, listen: false);
      provider.applySearchQuery(query);
    });
  }

  void _onFilter(String? typeId) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    setState(() {
      _selectedDestinationTypeId = typeId;
    });
    Provider.of<DestinationProvider>(context, listen: false)
        .applyCategoryFilter(typeId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Consumer<DestinationProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              onRefresh: () => provider.fetchDestinations(
                isRefresh: true,
              ),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    backgroundColor: theme.colorScheme.primary,
                    title: Text(
                      AppLocalizations.of(context)!.destination,
                      style: const TextStyle(color: Colors.white),
                    ),
                    centerTitle: true,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!
                                  .searchDestination,
                              prefixIcon: Icon(Icons.search,
                                  color: theme.colorScheme.onSurfaceVariant),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.sp),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceVariant
                                  .withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      height: 5.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: provider.destinationTypes.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildFilterChip(
                              context: context,
                              label: AppLocalizations.of(context)!.all,
                              isSelected: _selectedDestinationTypeId == null,
                              onTap: () => _onFilter(null),
                              icon: Icons.apps,
                            );
                          }
                          final type = provider.destinationTypes[index - 1];
                          return _buildFilterChip(
                            context: context,
                            label: type.name,
                            isSelected: type.id == _selectedDestinationTypeId,
                            onTap: () => _onFilter(type.id),
                            imageUrl: type.marker?.image,
                          );
                        },
                        separatorBuilder: (context, index) =>
                            SizedBox(width: 2.5.w),
                      ),
                    ),
                  ),
                  if (provider.isLoading && provider.destinations.isEmpty)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.all(4.w),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isTablet ? 3 : 2,
                          crossAxisSpacing: 4.w,
                          mainAxisSpacing: 4.w,
                          childAspectRatio: isTablet ? 0.7 : 0.58,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= provider.destinations.length) {
                              return const SizedBox.shrink();
                            }
                            return DestinationItem(
                              destination: provider.destinations[index],
                            );
                          },
                          childCount: provider.destinations.length,
                        ),
                      ),
                    ),
                  if (provider.isLoadingMore)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    String? imageUrl,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(15.sp),
        ),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        child: Row(
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 15.sp,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            if (imageUrl != null)
              Image.network(
                imageUrl,
                width: 15.sp,
                height: 15.sp,
              ),
            SizedBox(width: 1.w),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
