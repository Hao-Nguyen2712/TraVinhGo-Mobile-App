import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/map_provider.dart' show TransportMode;
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';

/// Utility class for map UI related helper methods
class MapUiUtils {
  /// Detect if text contains Vietnamese accents or is in composition mode
  static bool isVietnameseComposing(String text) {
    // Regular expression for Vietnamese diacritics
    final vietnamesePattern = RegExp(
        r'[àáạảãăắằẳẵặâấầẩẫậèéẹẻẽêếềểễệìíịỉĩòóọỏõôốồổỗộơớờởỡợùúụủũưứừửữựỳýỵỷỹđ]');

    return vietnamesePattern.hasMatch(text.toLowerCase());
  }

  /// Get appropriate debounce duration based on text content
  static Duration getDebounceDuration(String text) {
    // Longer debounce for Vietnamese text to allow IME composition
    return isVietnameseComposing(text)
        ? const Duration(milliseconds: 800) // Vietnamese text
        : const Duration(milliseconds: 400); // English/unaccented text
  }

  /// Formats distance in meters to a human-readable string
  static String formatDistance(int meters) {
    if (meters < 1000) {
      return '$meters m';
    } else {
      final kilometers = (meters / 1000).toStringAsFixed(1);
      return '$kilometers km';
    }
  }

  /// Formats duration in seconds to a human-readable string
  static String formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours hr ${minutes > 0 ? '$minutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }

  /// Calculates and formats the estimated arrival time based on current time plus route duration
  static String getEstimatedArrivalTime(
      int durationInSeconds, BuildContext context) {
    final now = DateTime.now();
    final arrivalTime = now.add(Duration(seconds: durationInSeconds));
    return TimeOfDay.fromDateTime(arrivalTime).format(context);
  }

  /// Helper method to get transport mode label
  static String getTransportModeLabel(
      TransportMode mode, AppLocalizations l10n) {
    switch (mode) {
      case TransportMode.car:
        return l10n.transportCar;
      case TransportMode.motorcycle:
        return l10n.transportMotorcycle;
      case TransportMode.pedestrian:
        return l10n.transportWalk;
      case TransportMode.bicycle:
        return l10n.transportBicycle;
      case TransportMode.scooter:
        return l10n.transportScooter;
      default:
        return l10n.transportCar;
    }
  }

  /// Helper method to get transport mode icon
  static IconData getTransportModeIcon(TransportMode mode) {
    switch (mode) {
      case TransportMode.car:
        return Icons.directions_car;
      case TransportMode.pedestrian:
        return Icons.directions_walk;
      case TransportMode.bicycle:
        return Icons.directions_bike;
      case TransportMode.scooter:
        return Icons.electric_scooter;
      case TransportMode.motorcycle:
        return Icons.motorcycle;
      default:
        return Icons.directions_car;
    }
  }
}

class LocationPreview extends StatelessWidget {
  final GeoCoordinates location;
  final VoidCallback onTap;

  const LocationPreview({Key? key, required this.location, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: HereMap(
          onMapCreated: (HereMapController controller) async {
            final mapScheme =
                isDarkMode ? MapScheme.normalNight : MapScheme.normalDay;
            controller.mapScene.loadSceneForMapScheme(mapScheme, (error) async {
              if (error == null) {
                final mapImage = await MapImage.withFilePathAndWidthAndHeight(
                    'assets/images/markers/marker.png', 70, 70);
                controller.camera.lookAtPoint(location);
                controller.mapScene.addMapMarker(MapMarker(location, mapImage));
              }
            });
          },
        ),
      ),
    );
  }
}
