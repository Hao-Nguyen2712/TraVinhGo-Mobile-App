import 'package:flutter/material.dart';
import '../../providers/map_provider.dart' show TransportMode;

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
  static String formatDistance(int distanceInMeters) {
    if (distanceInMeters < 1000) {
      return "$distanceInMeters m";
    } else {
      double distanceInKm = distanceInMeters / 1000.0;
      return "${distanceInKm.toStringAsFixed(1)} km";
    }
  }

  /// Formats duration in seconds to a human-readable string
  static String formatDuration(int durationInSeconds) {
    int minutes = (durationInSeconds / 60).floor();
    int hours = (minutes / 60).floor();
    minutes = minutes % 60;

    // Ensure minimum duration is 1 minute
    if (hours == 0 && minutes == 0) {
      minutes = 1; // Round up to 1 minute minimum
    }

    if (hours > 0) {
      return "$hours h $minutes min";
    } else {
      return "$minutes min";
    }
  }

  /// Calculates and formats the estimated arrival time based on current time plus route duration
  static String getEstimatedArrivalTime(int durationInSeconds) {
    // Get current time
    final now = DateTime.now();

    // Add route duration to current time
    final arrivalTime = now.add(Duration(seconds: durationInSeconds));

    // Format arrival time
    String period = arrivalTime.hour >= 12 ? 'PM' : 'AM';
    int displayHour =
        arrivalTime.hour > 12 ? arrivalTime.hour - 12 : arrivalTime.hour;
    if (displayHour == 0) displayHour = 12; // Handle midnight (0 hour)

    // Format with leading zeros for minutes
    String minutes = arrivalTime.minute.toString().padLeft(2, '0');

    // Return formatted time with arrival text
    return "Đến nơi lúc $displayHour:$minutes $period";
  }

  /// Helper method to get transport mode label
  static String getTransportModeLabel(TransportMode mode) {
    switch (mode) {
      case TransportMode.car:
        return "Lái Xe";
      case TransportMode.motorcycle:
        return "Xe Máy";
      case TransportMode.pedestrian:
        return "Đi Bộ";
      case TransportMode.bicycle:
        return "Xe Đạp";
      case TransportMode.scooter:
        return "Xe Scooter";
      default:
        return "Lái Xe";
    }
  }

  /// Helper method to get transport mode icon
  static IconData getTransportModeIcon(TransportMode mode) {
    switch (mode) {
      case TransportMode.car:
        return Icons.directions_car;
      case TransportMode.motorcycle:
        return Icons.motorcycle;
      case TransportMode.pedestrian:
        return Icons.directions_walk;
      case TransportMode.bicycle:
        return Icons.directions_bike;
      case TransportMode.scooter:
        return Icons.electric_scooter;
      default:
        return Icons.directions_car;
    }
  }
}
