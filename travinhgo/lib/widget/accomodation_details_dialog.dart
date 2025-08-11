import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:here_sdk/search.dart';

class AccomodationDetailsDialog extends StatelessWidget {
  final Place place;

  const AccomodationDetailsDialog({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        place.title,
        style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            _buildInfoRow(
              context,
              icon: Icons.location_on_outlined,
              label: appLocalizations.address,
              value: [
                place.address.houseNumOrName,
                place.address.street,
                place.address.district,
                place.address.city,
              ]
                  .where((element) => element != null && element.isNotEmpty)
                  .join(', '),
            ),
            _buildInfoRow(
              context,
              icon: Icons.map_outlined,
              label: appLocalizations.coordinates,
              value:
                  'Lat: ${place.geoCoordinates!.latitude.toStringAsFixed(5)}, Long: ${place.geoCoordinates!.longitude.toStringAsFixed(5)}',
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                child: Text(
                  appLocalizations.close,
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : colorScheme.primary),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  appLocalizations.heremapService,
                  style: textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required IconData icon, required String label, required String value}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: isDarkMode ? Colors.white : colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
