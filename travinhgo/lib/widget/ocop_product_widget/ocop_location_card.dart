import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import 'package:travinhgo/models/ocop/ocop_product.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travinhgo/widget/ocop_product_widget/ocop_location_detail_dialog.dart';

class OcopLocationCard extends StatelessWidget {
  final SellLocation location;
  final String tagImage;

  const OcopLocationCard({
    super.key,
    required this.location,
    required this.tagImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12.sp),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.network(
                    tagImage,
                    width: 28,
                    height: 28,
                  ),
                  SizedBox(width: 2.w),
                  Text(AppLocalizations.of(context)!.ocop),
                ],
              ),
              SizedBox(height: 1.h),
              Text(
                location.locationName ?? 'N/A',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on,
                  color: colorScheme.secondary, size: 16.sp),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  location.locationAddress ?? 'N/A',
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (location.location?.coordinates != null &&
                        location.location!.coordinates!.length >= 2) {
                      context.go(
                        '/map',
                        extra: {
                          'latitude': location.location!.coordinates![1],
                          'longitude': location.location!.coordinates![0],
                          'name': location.locationName,
                        },
                      );
                    }
                  },
                  icon: const Icon(Icons.directions),
                  label: Text(AppLocalizations.of(context)!.directions),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 1.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return OcopLocationDetailDialog(
                          location: location,
                          tagImage: tagImage,
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.info_outline),
                  label: Text(AppLocalizations.of(context)!.details),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
