import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/routing.dart' as here_sdk;
import 'package:here_sdk/search.dart';
import 'dart:developer' as developer;

import 'base_map_provider.dart';
import 'marker_map_provider.dart';
import 'search_map_provider.dart';
import 'location_map_provider.dart';
import '../map_provider.dart';

/// Transport mode options for routing
enum TransportMode { car, pedestrian, bicycle, scooter, motorcycle }

/// NavigationMapProvider handles all navigation and routing related functionality
class NavigationMapProvider {
  // Reference to other providers
  final BaseMapProvider baseMapProvider;
  final MarkerMapProvider markerMapProvider;
  final LocationMapProvider locationMapProvider;
  late SearchMapProvider _searchMapProvider;

  // Routing related variables
  here_sdk.RoutingEngine? _routingEngine;
  here_sdk.Route? _currentRoute;
  List<MapPolyline> _routePolylines = [];

  // Callback when route calculation is completed
  Function? onRouteCalculated;

  // Transport mode options
  TransportMode _selectedTransportMode = TransportMode.car;
  TransportMode get selectedTransportMode => _selectedTransportMode;

  // Store route durations for each transport mode
  final Map<TransportMode, int> _routeDurations = {};
  Map<TransportMode, int> get routeDurations => _routeDurations;

  // Routing state
  bool isRoutingMode = false;
  bool isShowingDepartureInput = false;
  bool isCalculatingRoute = false;
  String? routeErrorMessage;

  // Routing points
  GeoCoordinates? departureCoordinates;
  String? departureName;
  String? departureAddress;
  GeoCoordinates? destinationCoordinates;
  String? destinationName;
  String? destinationAddress;

  // Route info
  int? routeLengthInMeters;
  int? routeDurationInSeconds;

  // Get mapController from baseMapProvider
  HereMapController? get mapController => baseMapProvider.mapController;

  // Constants
  static const double traVinhLat = 9.9349;
  static const double traVinhLon = 106.3452;

  // Constructor
  NavigationMapProvider(
      this.baseMapProvider, this.markerMapProvider, this.locationMapProvider) {
    initializeRoutingEngine();
    _searchMapProvider = SearchMapProvider(baseMapProvider, markerMapProvider);
  }

  /// Initialize the routing engine
  void initializeRoutingEngine() {
    try {
      _routingEngine = here_sdk.RoutingEngine();
      developer.log('Routing engine initialized',
          name: 'NavigationMapProvider');
    } catch (e) {
      developer.log('Failed to initialize routing engine: $e',
          name: 'NavigationMapProvider');
    }
  }

  /// Sets the transport mode for routing
  void setTransportMode(TransportMode mode) {
    // If the mode hasn't changed, do nothing
    if (_selectedTransportMode == mode) return;

    _selectedTransportMode = mode;

    // Recalculate route if both points are set
    if (departureCoordinates != null && destinationCoordinates != null) {
      // Clear any existing route error
      routeErrorMessage = null;

      // Calculate new route with the selected transport mode
      calculateRoute();
    }
  }

  /// Sets up the routing mode
  void startRouting(GeoCoordinates coordinates, String name) {
    destinationCoordinates = coordinates;
    destinationName = name;
    isRoutingMode = true;
    isShowingDepartureInput = false; // Skip departure input, use default

    // Clear any existing route polylines
    clearRoutePolylines();

    // Clear any existing custom markers
    markerMapProvider.clearMarkers([MarkerMapProvider.MARKER_TYPE_CUSTOM]);

    // Also clear location marker when entering routing mode
    if (markerMapProvider.currentLocationMarker != null) {
      mapController?.mapScene
          .removeMapMarker(markerMapProvider.currentLocationMarker!);
      markerMapProvider.currentLocationMarker = null;
    }

    // Add destination marker
    addDestinationMarker(coordinates);

    // Get address for destination using reverse geocoding
    updateAddressFromCoordinates(coordinates, false);

    // Prioritize user's current location as departure.
    // Fallback to Tra Vinh Center if location is not available.
    if (locationMapProvider.currentPosition != null) {
      final currentPos = locationMapProvider.currentPosition!;
      final departureCoords =
          GeoCoordinates(currentPos.latitude, currentPos.longitude);
      addDepartureMarker(departureCoords, "Your Location");
    } else {
      useTraVinhCenterAsDeparture();
    }
  }

  /// Cancels the routing mode
  void cancelRouting() {
    isRoutingMode = false;
    isShowingDepartureInput = false;
    isCalculatingRoute = false;
    routeErrorMessage = null;

    // Clear routing data
    departureCoordinates = null;
    departureName = null;
    departureAddress = null;
    destinationCoordinates = null;
    destinationName = null;
    destinationAddress = null;

    // Clear route info
    routeLengthInMeters = null;
    routeDurationInSeconds = null;

    // Clear route polylines
    clearRoutePolylines();

    // Remove markers
    markerMapProvider.clearMarkers([
      MarkerMapProvider.MARKER_TYPE_DEPARTURE,
      MarkerMapProvider.MARKER_TYPE_ROUTE_DESTINATION
    ]);
  }

  /// Adds a destination marker for routing
  void addDestinationMarker(GeoCoordinates coordinates) {
    markerMapProvider.addMarker(
        coordinates, MarkerMapProvider.MARKER_TYPE_ROUTE_DESTINATION,
        customAsset: 'assets/images/markers/destination_point.png');
  }

  /// Adds a departure marker for routing
  void addDepartureMarker(GeoCoordinates coordinates, String name) {
    // Remove old departure marker before adding a new one
    markerMapProvider.clearMarkers([MarkerMapProvider.MARKER_TYPE_DEPARTURE]);

    // Remove Tra Vinh center marker if it is visible
    if (baseMapProvider is MapProvider) {
      final mapProvider = baseMapProvider as dynamic;
      if (mapProvider.centerMarker != null) {
        markerMapProvider.removeMarker(mapProvider.centerMarker!);
        mapProvider.centerMarker = null;
        mapProvider.isCenterMarkerVisible = false;
      }
    }

    // Format coordinates for display if name is "Selected location"
    if (name == "Selected location") {
      name =
          "Location: ${coordinates.latitude.toStringAsFixed(5)}, ${coordinates.longitude.toStringAsFixed(5)}";

      // Asynchronously update with real address
      updateAddressFromCoordinates(coordinates, true);
    }

    // Set departure point data
    departureCoordinates = coordinates;
    departureName = name;

    // Add the marker
    markerMapProvider.addMarker(
        coordinates, MarkerMapProvider.MARKER_TYPE_DEPARTURE,
        customAsset: 'assets/images/markers/departure_point.png');

    // Once we have both departure and destination, calculate the route
    if (destinationCoordinates != null) {
      calculateRoute();
    }

    // Hide departure input mode
    isShowingDepartureInput = false;
  }

  /// Use Tra Vinh center as departure point
  void useTraVinhCenterAsDeparture() {
    GeoCoordinates coordinates = GeoCoordinates(traVinhLat, traVinhLon);
    addDepartureMarker(coordinates, "Tra Vinh Center");
  }

  /// Use user's current location as departure point
  Future<void> useCurrentLocationAsDeparture() async {
    // First, ensure we have the latest position
    await locationMapProvider.getCurrentPosition();

    if (locationMapProvider.currentPosition != null) {
      final currentPos = locationMapProvider.currentPosition!;
      final departureCoords =
          GeoCoordinates(currentPos.latitude, currentPos.longitude);
      addDepartureMarker(departureCoords, "Vị trí của bạn");
    } else {
      // Handle case where location is still not available
      developer.log('Could not get current location to set as departure.',
          name: 'NavigationMapProvider');
    }
  }

  /// Calculate a route between departure and destination points
  void calculateRoute() {
    if (_routingEngine == null ||
        departureCoordinates == null ||
        destinationCoordinates == null) {
      return;
    }

    try {
      isCalculatingRoute = true;
      routeErrorMessage = null;

      // Clear previous route if any
      clearRoutePolylines();

      // Create waypoints
      here_sdk.Waypoint startWaypoint =
          here_sdk.Waypoint.withDefaults(departureCoordinates!);
      here_sdk.Waypoint destinationWaypoint =
          here_sdk.Waypoint.withDefaults(destinationCoordinates!);

      // Calculate routes for all transport modes
      // First calculate for the selected transport mode
      _calculateRouteForMode(
          _selectedTransportMode, startWaypoint, destinationWaypoint, true);

      // Then calculate for all other transport modes in the background
      for (TransportMode mode in TransportMode.values) {
        if (mode != _selectedTransportMode) {
          _calculateRouteForMode(
              mode, startWaypoint, destinationWaypoint, false);
        }
      }
    } catch (e) {
      isCalculatingRoute = false;
      routeErrorMessage = "Error calculating route: ${e.toString()}";
      developer.log(routeErrorMessage!, name: 'NavigationMapProvider');
    }
  }

  /// Calculate route for a specific transport mode
  void _calculateRouteForMode(
      TransportMode mode,
      here_sdk.Waypoint startWaypoint,
      here_sdk.Waypoint destinationWaypoint,
      bool isMainRoute) {
    try {
      switch (mode) {
        case TransportMode.car:
          // Car options
          here_sdk.CarOptions carOptions = here_sdk.CarOptions();
          carOptions.routeOptions.enableTolls = true;
          carOptions.routeOptions.optimizationMode =
              here_sdk.OptimizationMode.fastest;

          _routingEngine!.calculateCarRoute(
              [startWaypoint, destinationWaypoint],
              carOptions,
              (error, routes) => _handleRouteCalculationResult(
                  error, routes, mode, isMainRoute));
          break;

        case TransportMode.pedestrian:
          // Pedestrian options
          here_sdk.PedestrianOptions pedestrianOptions =
              here_sdk.PedestrianOptions();
          pedestrianOptions.routeOptions.optimizationMode =
              here_sdk.OptimizationMode.fastest;

          _routingEngine!.calculatePedestrianRoute(
              [startWaypoint, destinationWaypoint],
              pedestrianOptions,
              (error, routes) => _handleRouteCalculationResult(
                  error, routes, mode, isMainRoute));
          break;

        case TransportMode.bicycle:
          // Bicycle options
          here_sdk.BicycleOptions bicycleOptions = here_sdk.BicycleOptions();
          bicycleOptions.routeOptions.optimizationMode =
              here_sdk.OptimizationMode.fastest;

          _routingEngine!.calculateBicycleRoute(
              [startWaypoint, destinationWaypoint],
              bicycleOptions,
              (error, routes) => _handleRouteCalculationResult(
                  error, routes, mode, isMainRoute));
          break;

        case TransportMode.scooter:
          // Scooter options
          here_sdk.ScooterOptions scooterOptions = here_sdk.ScooterOptions();
          scooterOptions.routeOptions.optimizationMode =
              here_sdk.OptimizationMode.fastest;

          _routingEngine!.calculateScooterRoute(
              [startWaypoint, destinationWaypoint],
              scooterOptions,
              (error, routes) => _handleRouteCalculationResult(
                  error, routes, mode, isMainRoute));
          break;

        case TransportMode.motorcycle:
          // For motorcycles, we'll use car options as a fallback
          here_sdk.CarOptions motorOptions = here_sdk.CarOptions();
          motorOptions.routeOptions.optimizationMode =
              here_sdk.OptimizationMode.fastest;

          _routingEngine!.calculateCarRoute(
              [startWaypoint, destinationWaypoint],
              motorOptions,
              (error, routes) => _handleRouteCalculationResult(
                  error, routes, mode, isMainRoute));
          break;
      }
    } catch (e) {
      developer.log(
          'Failed to calculate route for ${mode.toString()}: ${e.toString()}',
          name: 'NavigationMapProvider');
      // Only update UI state for main route errors
      if (isMainRoute) {
        isCalculatingRoute = false;
        routeErrorMessage = "Error calculating route: ${e.toString()}";
      }
    }
  }

  /// Handle route calculation results
  void _handleRouteCalculationResult(here_sdk.RoutingError? routingError,
      List<here_sdk.Route>? routes, TransportMode mode, bool isMainRoute) {
    // Only update isCalculatingRoute flag for the main route
    if (isMainRoute) {
      isCalculatingRoute = false;
    }

    if (routingError != null) {
      if (isMainRoute) {
        routeErrorMessage =
            "Error calculating route: ${routingError.toString()}";
        developer.log(routeErrorMessage!, name: 'NavigationMapProvider');
      } else {
        developer.log(
            "Error calculating route for ${mode.toString()}: ${routingError.toString()}",
            name: 'NavigationMapProvider');
      }
      return;
    }

    if (routes == null || routes.isEmpty) {
      if (isMainRoute) {
        routeErrorMessage = "No route found";
        developer.log(routeErrorMessage!, name: 'NavigationMapProvider');
      } else {
        developer.log("No route found for ${mode.toString()}",
            name: 'NavigationMapProvider');
      }
      return;
    }

    // Get the fastest route
    here_sdk.Route fastestRoute = routes.first;

    // Store route info
    int routeLength = fastestRoute.lengthInMeters;
    int routeDuration = fastestRoute.duration.inSeconds;

    // Store the duration for this transport mode
    _routeDurations[mode] = routeDuration;

    developer.log(
        'Route calculated for ${mode.toString()}: ${routeDuration} seconds',
        name: 'NavigationMapProvider');

    // Only update the current route and UI for the main (selected) transport mode
    if (isMainRoute) {
      _currentRoute = fastestRoute;
      routeLengthInMeters = routeLength;
      routeDurationInSeconds = routeDuration;

      // Draw the route
      drawRoute(fastestRoute);

      // Zoom to show the entire route
      _zoomToRoute();

      // Call the callback to notify MapProvider to update UI
      if (onRouteCalculated != null) {
        onRouteCalculated!();
      }
    }
  }

  /// Draw route on the map with custom styling
  void drawRoute(here_sdk.Route route) {
    if (mapController == null) return;

    try {
      // Get route geometry
      GeoPolyline? routeGeoPolyline = route.geometry;

      if (routeGeoPolyline == null) {
        developer.log('Route geometry is null', name: 'NavigationMapProvider');
        return;
      }

      // Define line width in pixels - increased for better visibility
      MapMeasureDependentRenderSize renderSize =
          MapMeasureDependentRenderSize.withSingleSize(
              RenderSizeUnit.pixels, 8);

      // Create outline for the route with a drop shadow effect
      MapMeasureDependentRenderSize outlineSize =
          MapMeasureDependentRenderSize.withSingleSize(
              RenderSizeUnit.pixels, 11);

      // Create solid line representation for the route with color based on transport mode
      Color routeColor;
      Color outlineColor;
      switch (_selectedTransportMode) {
        case TransportMode.car:
          routeColor = Color.fromARGB(245, 100, 176, 0); // Brighter teal color
          outlineColor =
              Color.fromARGB(198, 92, 128, 0); // Semi-transparent teal
          break;
        case TransportMode.pedestrian:
          routeColor = Color.fromARGB(255, 211, 219, 52); // Blue color
          outlineColor =
              Color.fromARGB(120, 41, 128, 185); // Semi-transparent blue
          break;
        case TransportMode.bicycle:
          routeColor = Color.fromARGB(255, 155, 89, 182); // Purple color
          outlineColor =
              Color.fromARGB(120, 142, 68, 173); // Semi-transparent purple
          break;
        case TransportMode.scooter:
          routeColor = Color.fromARGB(255, 231, 76, 60); // Red color
          outlineColor =
              Color.fromARGB(120, 192, 57, 43); // Semi-transparent red
          break;
        case TransportMode.motorcycle:
          routeColor = Color.fromARGB(255, 243, 156, 18); // Orange color
          outlineColor =
              Color.fromARGB(120, 211, 84, 0); // Semi-transparent dark orange
          break;
      }

      // First create and add an outline polyline for better visibility
      MapPolylineSolidRepresentation outlineRepresentation =
          MapPolylineSolidRepresentation(
              outlineSize, outlineColor, LineCap.round);

      MapPolyline outlinePolyline = MapPolyline.withRepresentation(
          routeGeoPolyline, outlineRepresentation);

      // Add the outline polyline first (it will be drawn below the main route)
      mapController!.mapScene.addMapPolyline(outlinePolyline);

      // Create the main route polyline with higher draw order
      MapPolylineSolidRepresentation representation =
          MapPolylineSolidRepresentation(renderSize, routeColor, LineCap.round);

      MapPolyline routeMapPolyline =
          MapPolyline.withRepresentation(routeGeoPolyline, representation);

      // Set a higher draw order for the main route polyline
      routeMapPolyline.drawOrder = 100;

      // Add the main polyline to the map
      mapController!.mapScene.addMapPolyline(routeMapPolyline);

      // Store the polylines for later removal
      _routePolylines.add(outlinePolyline);
      _routePolylines.add(routeMapPolyline);
    } catch (e) {
      developer.log('Failed to draw route: $e', name: 'NavigationMapProvider');
    }
  }

  /// Clear all route polylines
  void clearRoutePolylines() {
    if (mapController == null) return;

    try {
      for (MapPolyline polyline in _routePolylines) {
        mapController!.mapScene.removeMapPolyline(polyline);
      }

      _routePolylines.clear();
      _currentRoute = null;
    } catch (e) {
      developer.log('Failed to clear route polylines: $e',
          name: 'NavigationMapProvider');
    }
  }

  /// Zoom to show the entire route
  void _zoomToRoute() {
    if (mapController == null ||
        departureCoordinates == null ||
        destinationCoordinates == null) {
      return;
    }

    try {
      // Calculate the midpoint between departure and destination
      double midLat =
          (departureCoordinates!.latitude + destinationCoordinates!.latitude) /
              2;
      double midLon = (departureCoordinates!.longitude +
              destinationCoordinates!.longitude) /
          2;

      // Calculate distance between points (rough approximation)
      double distance = _calculateDistance(
          departureCoordinates!.latitude,
          departureCoordinates!.longitude,
          destinationCoordinates!.latitude,
          destinationCoordinates!.longitude);

      // Add some padding (multiply by 1.5 to show some area around the route)
      distance = distance * 1.5;

      // Use the moveCamera method from baseMapProvider
      baseMapProvider.moveCamera(GeoCoordinates(midLat, midLon), distance);
    } catch (e) {
      developer.log('Failed to zoom to route: $e',
          name: 'NavigationMapProvider');
    }
  }

  /// Calculate distance between two geo points in meters
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Swaps the departure and destination locations
  void swapDepartureAndDestination() {
    // Only swap if both locations are set
    if (departureCoordinates != null && destinationCoordinates != null) {
      // Swap coordinates
      GeoCoordinates tempCoords = departureCoordinates!;
      departureCoordinates = destinationCoordinates;
      destinationCoordinates = tempCoords;

      // Swap names
      String? tempName = departureName;
      departureName = destinationName;
      destinationName = tempName;

      // Swap addresses
      String? tempAddress = departureAddress;
      departureAddress = destinationAddress;
      destinationAddress = tempAddress;

      // Clear markers
      markerMapProvider.clearMarkers([
        MarkerMapProvider.MARKER_TYPE_DEPARTURE,
        MarkerMapProvider.MARKER_TYPE_ROUTE_DESTINATION
      ]);

      // Add new markers with swapped positions
      addDepartureMarker(
          departureCoordinates!, departureName ?? "Selected location");
      addDestinationMarker(destinationCoordinates!);

      // Clear any existing route error
      routeErrorMessage = null;

      // Recalculate the route with fresh ETA
      calculateRoute();
    }
  }

  /// Hide departure input mode
  void hideDepartureInput() {
    isShowingDepartureInput = false;
  }

  /// Show departure input mode
  void showDepartureInput() {
    isShowingDepartureInput = true;
  }

  /// Cleanup navigation resources
  void cleanupNavigationResources() {
    // Clear routing data
    clearRoutePolylines();

    // Clear all markers related to navigation
    markerMapProvider.clearMarkers([
      MarkerMapProvider.MARKER_TYPE_DEPARTURE,
      MarkerMapProvider.MARKER_TYPE_ROUTE_DESTINATION
    ]);

    developer.log('Navigation resources cleaned up',
        name: 'NavigationMapProvider');
  }

  /// Update addresses for both departure and destination points using reverse geocoding
  Future<void> updateAddressesFromCoordinates() async {
    if (departureCoordinates != null) {
      await updateAddressFromCoordinates(departureCoordinates!, true);
    }

    if (destinationCoordinates != null) {
      await updateAddressFromCoordinates(destinationCoordinates!, false);
    }
  }

  /// Update address for a single point (departure or destination) using reverse geocoding
  Future<void> updateAddressFromCoordinates(
      GeoCoordinates coordinates, bool isDeparture) async {
    try {
      String? address =
          await _searchMapProvider.getAddressFromCoordinates(coordinates);

      if (address != null && address.isNotEmpty) {
        developer.log('Got address from coordinates: $address',
            name: 'NavigationMapProvider');

        if (isDeparture) {
          departureAddress = address;
        } else {
          destinationAddress = address;
        }

        // Notify listeners that address has been updated
        if (onRouteCalculated != null) {
          onRouteCalculated!();
        }
      }
    } catch (e) {
      developer.log('Error getting address from coordinates: $e',
          name: 'NavigationMapProvider');
    }
  }
}
