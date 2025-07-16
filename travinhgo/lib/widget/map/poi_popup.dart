import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:here_sdk/core.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/providers/map_provider.dart';
import 'package:travinhgo/widget/ocop_product_widget/rating_star_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// POI information popup widget
class PoiPopup extends StatelessWidget {
  const PoiPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);

    if (!mapProvider.showPoiPopup || mapProvider.lastPoiCoordinates == null) {
      return const SizedBox.shrink();
    }

    final metadata = mapProvider.lastPoiMetadata;
    final String name = mapProvider.lastPoiName ??
        AppLocalizations.of(context)!.unknownLocation;
    final double rating =
        double.tryParse(metadata?.getString('product_rating') ?? '0.0') ?? 0.0;
    final imagesString = metadata?.getString('product_images');
    final List<String> images = imagesString != null && imagesString.isNotEmpty
        ? imagesString.split(',')
        : [];
    final String address = metadata?.getString('place_address') ??
        '${mapProvider.lastPoiCoordinates!.latitude.toStringAsFixed(5)}, ${mapProvider.lastPoiCoordinates!.longitude.toStringAsFixed(5)}';

    final bool isOcop = metadata?.getString("is_ocop_product") == "true";
    final String? ocopProductId = metadata?.getString("product_id");
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      bottom: 20,
      left: 10,
      right: 10,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color:
                isDarkMode ? colorScheme.surfaceVariant : colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (rating > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  if (isOcop)
                                    RatingStarWidget(rating.round())
                                  else
                                    // Generic star rating for non-OCOP
                                    ...List.generate(5, (index) {
                                      return Icon(
                                        index < rating.floor()
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: colorScheme.secondary,
                                        size: 16,
                                      );
                                    }),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 40), // Space for close button
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            context,
                            Icons.directions,
                            AppLocalizations.of(context)!.direct,
                            false,
                            () {
                              if (mapProvider.lastPoiCoordinates != null) {
                                mapProvider.startRouting(
                                  mapProvider.lastPoiCoordinates!,
                                  name,
                                );
                                mapProvider.closePoiPopup();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            context,
                            Icons.info_outline,
                            AppLocalizations.of(context)!.detail,
                            false,
                            () {
                              if (isOcop && ocopProductId != null) {
                                GoRouter.of(context).push(
                                    '/ocop-product-detail/$ocopProductId');
                                mapProvider.closePoiPopup();
                              }
                              // Handle other detail navigations if needed
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            context,
                            Icons.share,
                            AppLocalizations.of(context)!.share,
                            false,
                            () {
                              final textToShare = AppLocalizations.of(context)!
                                  .shareText(name, address);
                              Share.share(textToShare);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Image Gallery
                  if (images.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: images[index],
                                width: 160,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 160,
                                  height: 120,
                                  color: colorScheme.surfaceVariant,
                                  child: const Center(
                                      child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 160,
                                  height: 120,
                                  color: colorScheme.surfaceVariant,
                                  child: Icon(Icons.error,
                                      color: colorScheme.error),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  _buildInfoRow(context, Icons.location_on_outlined, address),
                  _buildInfoRow(context, Icons.map_outlined,
                      '${mapProvider.lastPoiCoordinates!.latitude.toStringAsFixed(5)}, ${mapProvider.lastPoiCoordinates!.longitude.toStringAsFixed(5)}'),
                  if (mapProvider.lastPoiCategory != null)
                    _buildInfoRow(context, Icons.category_outlined,
                        mapProvider.lastPoiCategory!),
                ],
              ),
            ),
          ),
          // Close Button
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.close, color: colorScheme.onSurface),
                iconSize: 20,
                onPressed: () => mapProvider.closePoiPopup(),
                splashRadius: 20,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label,
      bool isPrimary, VoidCallback onPressed) {
    return FilledButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        foregroundColor: isPrimary
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSecondaryContainer,
        backgroundColor: isPrimary
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
