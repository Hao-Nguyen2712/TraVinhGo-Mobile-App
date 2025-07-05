import 'dart:async';

import 'package:flutter/material.dart';
import 'package:here_sdk/mapview.dart'
    show HereMap, HereMapController, MapMarker, MapPickResult;
import 'package:here_sdk/gestures.dart' show TapListener;
import 'package:here_sdk/core.dart'
    show GeoCoordinates, Point2D, Rectangle2D, Size2D;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:developer' as developer;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../Models/Maps/top_favorite_destination.dart';
import '../../providers/map_provider.dart';
import '../../providers/map/marker_map_provider.dart';
import '../../widget/map/search_bar.dart' as map_search;
import '../../widget/map/location_button.dart';
import '../../widget/map/category_buttons.dart';
import '../../widget/map/poi_popup.dart';
import '../../widget/map/favorite_destinations_slider.dart';
import '../../widget/map/error_view.dart';
import '../../widget/map/routing_ui.dart';

/// Map Screen that displays HERE maps with POIs and user location
class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  // PageController for the destination carousel
  final PageController _pageController = PageController(viewportFraction: 0.85);

  // Late initialized provider
  late MapProvider _mapProvider;

  // Track last shown POI to avoid showing duplicate snackbars
  String? _lastShownPoiName;

  // Text editing controllers for search and departure inputs
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _departureController = TextEditingController();
  final FocusNode _departureFocusNode = FocusNode();
  Timer? _debounceTimer;

  // Vietnamese text input optimization
  String? _lastSearchTerm;
  String? _composingText;
  bool _isComposing = false;
  int _lastSearchTimestamp = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize the provider after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapProvider = Provider.of<MapProvider>(context, listen: false);
      // SDK is already initialized in main.dart, no need to initialize again
      _mapProvider.loadTopDestinations();
    });
  }

  @override
  void dispose() {
    // Don't access Provider in dispose - use the previously cached instance
    if (_mapProvider != null) {
      // Use the reference cached during initState
      _mapProvider.cleanupMapResources();

      // Clear markers before disposing
      _mapProvider.clearMarkers([
        MarkerMapProvider.MARKER_TYPE_LOCATION,
        MarkerMapProvider.MARKER_TYPE_DESTINATION,
        MarkerMapProvider.MARKER_TYPE_CUSTOM
      ]);
    }

    _debounceTimer?.cancel();
    _searchController.dispose();
    _departureController.dispose();
    _departureFocusNode.dispose();
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.resumed) {
      // Refresh the map when app is resumed
      _mapProvider.refreshMap();

      // Clear any previous markers that may have been cached
      _mapProvider.cleanupMapResources();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // Clean up resources when app is paused, inactive or detached
      _mapProvider.cleanupMapResources();
    }
  }

  /// Detect if text contains Vietnamese accents or is in composition mode
  bool _isVietnameseComposing(String text) {
    // Regular expression for Vietnamese diacritics
    final vietnamesePattern = RegExp(
        r'[àáạảãăắằẳẵặâấầẩẫậèéẹẻẽêếềểễệìíịỉĩòóọỏõôốồổỗộơớờởỡợùúụủũưứừửữựỳýỵỷỹđ]');

    return vietnamesePattern.hasMatch(text.toLowerCase());
  }

  /// Get appropriate debounce duration based on text content
  Duration _getDebounceDuration(String text) {
    // Longer debounce for Vietnamese text to allow IME composition
    return _isVietnameseComposing(text)
        ? const Duration(milliseconds: 800) // Vietnamese text
        : const Duration(milliseconds: 400); // English/unaccented text
  }

  /// Update departure controller text when departure name changes
  void _updateDepartureControllerText(MapProvider provider) {
    // When showing departure input mode, only clear if we're just entering input mode
    // Don't clear if the user is actively typing (has focus and non-empty text)
    if (provider.isShowingDepartureInput) {
      // Only clear when first showing the input field and it contains the provider's value
      // This prevents clearing while typing
      if (_departureController.text == provider.departureName) {
        _departureController.clear();
      }
    } else {
      // Outside of input mode, keep in sync with provider
      if (provider.departureName != null &&
          _departureController.text != provider.departureName) {
        _departureController.text = provider.departureName!;
      } else if (provider.departureName == null &&
          _departureController.text.isNotEmpty) {
        // Reset controller if provider has no departure name but controller has text
        _departureController.text = '';
      }
    }
  }

  /// Handles search input changes with smart debounce for Vietnamese typing experience
  void _onSearchChanged(String text, MapProvider provider) {
    // Cancel any previous timer
    _debounceTimer?.cancel();

    if (text.isEmpty) {
      provider.clearSearchResults();
      _lastSearchTerm = null;
      return;
    }

    // Skip if text too short
    if (text.length < 2) return;

    // Simple debounce approach - let IME handle composition naturally
    final debounceDuration = _getDebounceDuration(text);

    _debounceTimer = Timer(debounceDuration, () {
      _performSearch(text, provider);
    });
  }

  /// Perform search with duplicate prevention and performance tracking
  void _performSearch(String searchTerm, MapProvider provider) {
    final trimmedTerm = searchTerm.trim();

    // Avoid duplicate searches
    if (_lastSearchTerm == trimmedTerm) {
      developer.log('Skipping duplicate search: "$trimmedTerm"',
          name: 'Search');
      return;
    }

    // Performance tracking
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeSinceLastSearch =
        _lastSearchTimestamp > 0 ? now - _lastSearchTimestamp : 0;
    _lastSearchTimestamp = now;

    _lastSearchTerm = trimmedTerm;

    developer.log(
        'Performing search: "$trimmedTerm" (${timeSinceLastSearch}ms since last)',
        name: 'Search');

    provider.searchLocations(trimmedTerm);
  }

  /// Shows a snackbar with a message
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Called when a POI is selected to show its details
  void _showPOIDetails(TopFavoriteDestination destination) {
    // Move map to the selected destination
    if (destination.id != null) {
      _mapProvider.moveToDestination(destination.id!);
    }
  }

  /// Called when a category filter is selected
  void _onCategorySelected(int index, bool selected) {
    if (selected) {
      _mapProvider.updateSelectedCategory(index);
    }
  }

  /// Called when the destination carousel is swiped
  void _onDestinationPageChanged(int index) {
    _mapProvider.updateCurrentDestination(index);
  }

  /// Called when the map is created
  void _onMapCreated(HereMapController hereMapController) {
    try {
      developer.log('Map controller created successfully', name: 'MapScreen');
      _mapProvider.initMapScene(hereMapController);

      // Set up tap listener for map interactions
      hereMapController.gestures.tapListener =
          TapListener((Point2D touchPoint) {
        var geoCoords = hereMapController.viewToGeoCoordinates(touchPoint);
        if (geoCoords != null) {
          // Let the map provider handle all tap interactions
          _mapProvider.handleMapTap(touchPoint, geoCoords);
        }
      });
    } catch (e) {
      developer.log('Error initializing map scene: $e', name: 'MapScreen');
      _mapProvider.errorMessage = "Map initialization failed: ${e.toString()}";
      _mapProvider.isLoading = false;
      _mapProvider.notifyListeners();
    }
  }

  /// Shows a popup with information about a place from a category marker
  void _showCategoryMarkerPopup(
      Map<String, String> placeInfo, GeoCoordinates coordinates) {
    // Set the POI info in the map provider
    _mapProvider.lastPoiName = placeInfo['name'];
    _mapProvider.lastPoiCategory = placeInfo['category'];
    _mapProvider.lastPoiCoordinates = coordinates;
    _mapProvider.showPoiPopup = true;

    // Move camera to the POI location
    _mapProvider.moveCamera(coordinates, 500);

    // Notify listeners
    _mapProvider.notifyListeners();
  }

  /// Shows debug information in case of errors
  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.debugInfo),
        content: SelectableText(
          "${AppLocalizations.of(context)!.errorPrefix(_mapProvider.errorMessage!)}\n\n"
          "${AppLocalizations.of(context)!.mapErrorInstructions}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  /// Builds the destination image or a placeholder
  Widget _buildDestinationImage(String? imageUrl, double width, double height) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: Icon(Icons.image, color: Colors.grey[600]),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
        child: Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: Icon(Icons.error, color: Colors.red),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, provider, child) {
        _mapProvider = provider;
        return Scaffold(
          key: provider.scaffoldMessengerKey,
          body: Stack(
            children: [
              // Map view
              provider.errorMessage != null
                  ? const ErrorView()
                  : provider.isLoading && provider.mapController == null
                      ? const Center(child: CircularProgressIndicator())
                      : HereMap(onMapCreated: _onMapCreated),

              // Category buttons - only show when not in routing mode
              if (!provider.isRoutingMode) const CategoryButtons(),

              // Location button
              const LocationButton(),

              // Loading indicator
              if (provider.isLoading && provider.mapController != null)
                const Center(child: CircularProgressIndicator()),

              // Conditionally show either POI info, favorite destinations, or hide both during routing
              if (!provider.isRoutingMode)
                provider.showPoiPopup
                    ? const PoiPopup()
                    : const FavoriteDestinationsSlider(),

              // Routing UI components when in routing mode
              const RoutingUI(),

              // Search bar with dropdown at the top (put last to be on top of z-order)
              const map_search.SearchBar(),
            ],
          ),
        );
      },
    );
  }
}
