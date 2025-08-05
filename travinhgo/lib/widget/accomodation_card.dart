import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:here_sdk/search.dart';
import 'package:sizer/sizer.dart';
import 'package:travinhgo/widget/accomodation_details_dialog.dart';

class AccomodationCard extends StatelessWidget {
  final Place place;

  const AccomodationCard({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              place.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.5.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  size: 16.sp,
                  color: colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 1.2.w),
                Expanded(
                  child: Text(
                    [
                      place.address.houseNumOrName,
                      place.address.street,
                      place.address.district,
                      place.address.city,
                    ]
                        .where(
                            (element) => element != null && element.isNotEmpty)
                        .join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AccomodationDetailsDialog(place: place);
                      },
                    );
                  },
                  icon: Icon(Icons.info_outline, color: Colors.blue.shade700),
                  label: Text(
                    AppLocalizations.of(context)!.detail,
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
                ElevatedButton.icon(
                  onPressed: () {
                    if (place.geoCoordinates != null) {
                      GoRouter.of(context).goNamed(
                        'map_shell',
                        extra: {
                          'latitude': place.geoCoordinates!.latitude,
                          'longitude': place.geoCoordinates!.longitude,
                          'name': place.title,
                        },
                      );
                    }
                  },
                  icon: Icon(Icons.directions, color: Colors.green.shade700),
                  label: Text(
                    AppLocalizations.of(context)!.direct,
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
