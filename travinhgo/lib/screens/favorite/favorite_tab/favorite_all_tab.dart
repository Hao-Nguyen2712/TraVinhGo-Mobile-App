import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:travinhgo/widget/placeholder/empty_favorite_placeholder.dart';

import '../../../providers/favorite_provider.dart';
import '../../../widget/destination_widget/destination_item.dart';
import '../../../widget/local_specialty_widget/local_specialty_item.dart';
import '../../../widget/ocop_product_widget/ocop_product_item.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FavoriteAllTab extends StatefulWidget {
  const FavoriteAllTab({super.key});

  @override
  State<FavoriteAllTab> createState() => _FavoriteAllTabState();
}

class _FavoriteAllTabState extends State<FavoriteAllTab> {
  bool showAllDestinations = false;
  bool showAllOcop = false;
  bool showAllLocals = false;

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = FavoriteProvider.of(context);
    final destinations = favoriteProvider.destinationList;
    final ocops = favoriteProvider.ocopProductList;
    final locals = favoriteProvider.localSpecialteList;

    if (destinations.isEmpty && ocops.isEmpty && locals.isEmpty) {
      return const EmptyFavoritesPlaceholder();
    }

    final destinationPerRow =
        MediaQuery.of(context).orientation == Orientation.landscape ? 3 : 2;
    const int ocopPerRow = 2;
    const int localPerRow = 1;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Destinations Section
          if (destinations.isNotEmpty)
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.destination,
              itemCount: destinations.length,
              items: destinations,
              itemBuilder: (context, index) =>
                  DestinationItem(destination: destinations[index], isAllowFavorite: true,),
              crossAxisCount: destinationPerRow,
              childAspectRatio: 0.58,
              showAll: showAllDestinations,
              onToggleShowAll: () {
                setState(() => showAllDestinations = !showAllDestinations);
              },
            ),

          // OCOP Products Section
          if (ocops.isNotEmpty)
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.ocop,
              itemCount: ocops.length,
              items: ocops,
              itemBuilder: (context, index) =>
                  OcopProductItem(ocopProduct: ocops[index], isAllowFavorite: true,),
              crossAxisCount: ocopPerRow,
              childAspectRatio: 0.58,
              showAll: showAllOcop,
              onToggleShowAll: () {
                setState(() => showAllOcop = !showAllOcop);
              },
            ),

          // Local Specialties Section
          if (locals.isNotEmpty)
            _buildSection(
              context,
              title: AppLocalizations.of(context)!.local,
              itemCount: locals.length,
              items: locals,
              itemBuilder: (context, index) =>
                  LocalSpecialtyItem(localSpecialty: locals[index], isAllowFavorite: true,),
              crossAxisCount: localPerRow,
              childAspectRatio: 1.5,
              showAll: showAllLocals,
              onToggleShowAll: () {
                setState(() => showAllLocals = !showAllLocals);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required int itemCount,
    required List<dynamic> items,
    required Widget Function(BuildContext, int) itemBuilder,
    required int crossAxisCount,
    required double childAspectRatio,
    required bool showAll,
    required VoidCallback onToggleShowAll,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
        ),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: showAll
              ? itemCount
              : (itemCount > crossAxisCount ? crossAxisCount : itemCount),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 4.w,
            mainAxisSpacing: 4.w,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: itemBuilder,
        ),
        if (itemCount > crossAxisCount)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onToggleShowAll,
              child: Text(
                showAll ? l10n.less : l10n.more,
                style: TextStyle(
                    color: theme.colorScheme.primary, fontSize: 12.sp),
              ),
            ),
          ),
        SizedBox(height: 2.h),
      ],
    );
  }
}
