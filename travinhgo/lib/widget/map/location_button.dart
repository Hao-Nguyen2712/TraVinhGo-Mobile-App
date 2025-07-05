import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/map_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Location buttons for current location and Tra Vinh center
class LocationButton extends StatelessWidget {
  const LocationButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.gps_fixed, color: Colors.blue),
                  onPressed: () => provider.getCurrentPosition(),
                  tooltip: AppLocalizations.of(context)!.myLocation,
                ),
              ),

              SizedBox(height: 10),

              // Tra Vinh center button
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.location_city,
                    // Change color based on marker visibility
                    color: provider.isCenterMarkerVisible
                        ? Colors.red
                        : Colors.green,
                  ),
                  onPressed: () {
                    // First move to Tra Vinh center
                    provider.refreshMap();
                    // Then toggle the center marker
                    provider.toggleCenterMarker();
                  },
                  tooltip: provider.isCenterMarkerVisible
                      ? AppLocalizations.of(context)!.removeCenterMarker
                      : AppLocalizations.of(context)!.showCenterMarker,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
