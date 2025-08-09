import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/map_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Location buttons for current location and Tra Vinh center
class LocationButton extends StatelessWidget {
  const LocationButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<MapProvider>(
      builder: (context, provider, _) {
        // Don't show location button in routing mode
        if (provider.isRoutingMode) {
          return SizedBox.shrink();
        }

        return Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 160,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current location button
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.gps_fixed, color: colorScheme.primary),
                  onPressed: () => provider.getCurrentPosition(),
                  tooltip: AppLocalizations.of(context)!.myLocation,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
