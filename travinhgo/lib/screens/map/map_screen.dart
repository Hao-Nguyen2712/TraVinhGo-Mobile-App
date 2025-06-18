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

import '../../Models/Maps/top_favorite_destination.dart';
import '../../providers/map_provider.dart';

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

  // Text editing controller for search input
  final TextEditingController _searchController = TextEditingController();
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
      _mapProvider.initializeHERESDK();
      _mapProvider.loadTopDestinations();
    });
  }

  @override
  void dispose() {
    // Thoroughly clean up all map resources
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    mapProvider.cleanupMapResources();

    // Clear markers before disposing
    mapProvider.clearMarkers([
      MapProvider.MARKER_TYPE_LOCATION,
      MapProvider.MARKER_TYPE_DESTINATION,
      MapProvider.MARKER_TYPE_CUSTOM
    ]);

    _debounceTimer?.cancel();
    _searchController.dispose();
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
    _mapProvider.initMapScene(hereMapController);

    // Set up tap listener for category markers
    hereMapController.gestures.tapListener = TapListener((Point2D touchPoint) {
      _handleMapTap(touchPoint);
    });
  }

  /// Handle taps on the map with special handling for markers
  void _handleMapTap(Point2D touchPoint) {
    if (_mapProvider.mapController == null) return;

    // Create a small rectangle around the touch point for picking
    final size = Size2D(20, 20); // 10 pixels radius in each direction
    final origin = Point2D(touchPoint.x - 10, touchPoint.y - 10);
    final Rectangle2D pickArea = Rectangle2D(origin, size);

    // Use the pick API to find markers at the touch point
    _mapProvider.mapController!.pick(null, pickArea,
        (MapPickResult? pickResult) {
      // Check if any markers were picked
      if (pickResult == null ||
          pickResult.mapItems == null ||
          pickResult.mapItems!.markers.isEmpty) {
        // No marker was tapped, proceed with regular tap handling
        var geoCoords =
            _mapProvider.mapController?.viewToGeoCoordinates(touchPoint);
        if (geoCoords != null) {
          // Handle regular map tap
        }
        return;
      }

      // A marker was tapped
      MapMarker tappedMarker = pickResult.mapItems!.markers.first;

      // Check if this is a category marker
      if (tappedMarker.metadata != null) {
        // Get place information from marker metadata
        Map<String, String>? placeInfo =
            _mapProvider.getPlaceInfoFromMarker(tappedMarker);

        if (placeInfo != null) {
          // Show POI popup with the place information
          _showCategoryMarkerPopup(placeInfo, tappedMarker.coordinates);
        }
      }
    });
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
        title: Text("Debug Info"),
        content: SelectableText(
          "Error: ${_mapProvider.errorMessage}\n\n"
          "Make sure:\n"
          "1. Your API key and secret are correctly registered\n"
          "2. Internet permissions are enabled in AndroidManifest.xml\n"
          "3. Your device has internet access\n"
          "4. HERE SDK is properly initialized",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("OK"),
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

  /// Builds the POI information popup
  Widget _buildPoiPopup() {
    if (!_mapProvider.showPoiPopup || _mapProvider.lastPoiName == null) {
      return SizedBox.shrink();
    }

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 160,
      left: 20,
      right: 20,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _mapProvider.lastPoiName ?? "Unknown Place",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => _mapProvider.closePoiPopup(),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (_mapProvider.lastPoiCategory != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.category, size: 16, color: Colors.grey[700]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _mapProvider.lastPoiCategory!,
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_mapProvider.lastPoiCoordinates != null)
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[700]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_mapProvider.lastPoiCoordinates!.latitude.toStringAsFixed(6)}, ${_mapProvider.lastPoiCoordinates!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Navigate to the POI
                    if (_mapProvider.lastPoiCoordinates != null) {
                      _mapProvider.moveCamera(
                          _mapProvider.lastPoiCoordinates!, 500);
                    }
                  },
                  icon: Icon(Icons.navigation, size: 16),
                  label: Text("Navigate"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green[700],
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
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
                  ? _buildErrorView()
                  : provider.isLoading && provider.mapController == null
                      ? const Center(child: CircularProgressIndicator())
                      : HereMap(onMapCreated: _onMapCreated),

              // Category buttons
              _buildCategoryButtons(),

              // Location button
              _buildLocationButton(),

              // Loading indicator
              if (provider.isLoading && provider.mapController != null)
                const Center(child: CircularProgressIndicator()),

              // Favorite destinations slider at the bottom
              _buildFavoriteDestinationsSlider(),

              // POI information popup
              _buildPoiPopup(),

              // Search bar with dropdown at the top (put last to be on top of z-order)
              _buildSearchBar(),
            ],
          ),
        );
      },
    );
  }

  /// Builds the search bar widget
  Widget _buildSearchBar() {
    return Consumer<MapProvider>(
      builder: (context, provider, _) {
        // Access search suggestions
        final suggestions = provider.searchSuggestions;

        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search input field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(242), // 0.95 opacity
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(38), // 0.15 opacity
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,

                  // Vietnamese text optimization
                  autocorrect: true,
                  enableSuggestions: true,
                  enableInteractiveSelection: true,

                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.green.withAlpha(230),
                      size: 24,
                    ),
                    suffixIcon: provider.isSearching
                        ? Container(
                            width: 24,
                            height: 24,
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              provider.clearSearchResults();
                            },
                          ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  onChanged: (text) => _onSearchChanged(text, provider),
                ),
              ),

              // Search results dropdown with higher z-index
              if (suggestions.isNotEmpty)
                Material(
                  elevation: 12, // Higher elevation for better shadow
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    margin: EdgeInsets.only(top: 4),
                    constraints: BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        itemCount: suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = suggestions[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(Icons.location_on_outlined,
                                color: Colors.black),
                            title: Text(
                              suggestion.title ?? "Địa điểm không tên",
                              style: TextStyle(fontSize: 14),
                            ),
                            onTap: () {
                              provider.selectSearchSuggestion(suggestion);
                              _searchController.text = suggestion.title ?? "";
                              FocusScope.of(context).unfocus(); // Hide keyboard
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the location button widget
  Widget _buildLocationButton() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 160,
      right: 16,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(242),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(38),
              blurRadius: 8,
              spreadRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(Icons.my_location,
              color: Colors.green.withAlpha(230), size: 24),
          onPressed: () {
            // First get location if needed
            if (_mapProvider.currentPosition == null) {
              _mapProvider.getCurrentPosition();
            } else {
              // If we already have location, just move to it
              _mapProvider.moveToCurrentPosition();
            }
          },
        ),
      ),
    );
  }

  /// Builds the category filter buttons
  Widget _buildCategoryButtons() {
    return Consumer<MapProvider>(
      builder: (context, provider, _) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 70,
          left: 0,
          right: 0,
          height: 50,
          child: Stack(
            children: [
              ShaderMask(
                shaderCallback: (Rect rect) {
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withAlpha(20),
                      Colors.black.withAlpha(255),
                      Colors.black.withAlpha(255),
                      Colors.black.withAlpha(20)
                    ],
                    stops: [0.0, 0.05, 0.95, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  itemCount: provider.categories.length,
                  itemBuilder: (context, index) {
                    bool isSelected = provider.selectedCategoryIndex == index;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _onCategorySelected(index, true),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.green.withOpacity(0.8)
                                  : Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.green
                                    : Colors.white.withOpacity(0.8),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Category icon
                                Image.asset(
                                  provider.getCategoryIcon(index),
                                  width: 18,
                                  height: 18,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.category,
                                      size: 18,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                    );
                                  },
                                ),
                                SizedBox(width: 6),
                                // Category name
                                Text(
                                  provider.categories[index],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Show loading indicator when category search is in progress
              if (provider.isCategorySearching)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withAlpha(160),
                    child: Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the favorite destinations carousel slider
  Widget _buildFavoriteDestinationsSlider() {
    if (_mapProvider.topDestinations.isEmpty) return SizedBox.shrink();
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 0,
      right: 0,
      height: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _mapProvider.topDestinations.length,
              onPageChanged: _onDestinationPageChanged,
              itemBuilder: (context, index) {
                final destination = _mapProvider.topDestinations[index];
                return AnimatedOpacity(
                  duration: Duration(milliseconds: 300),
                  opacity:
                      _mapProvider.currentDestinationIndex == index ? 1.0 : 0.7,
                  child: GestureDetector(
                    onTap: () => _showPOIDetails(destination),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(250),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(60),
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(15),
                              bottomLeft: Radius.circular(15),
                            ),
                            child: _buildDestinationImage(
                                destination.image, 80, double.infinity),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    destination.name ?? 'Unknown Place',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 3),
                                  _buildDestinationRating(
                                      destination.averageRating ?? 0),
                                  SizedBox(height: 5),
                                  Text(
                                    destination.description ??
                                        'No description available',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.withAlpha(230),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the rating display for a destination
  Widget _buildDestinationRating(double rating) {
    return Row(
      children: [
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 4),
        ...List.generate(
          5,
          (index) => Icon(
            index < rating.floor()
                ? Icons.star
                : (index == rating.floor() && rating % 1 > 0)
                    ? Icons.star_half
                    : Icons.star_border,
            color: Colors.amber.withAlpha(230),
            size: 16,
          ),
        ),
      ],
    );
  }

  /// Builds the error view when map fails to load
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Failed to load map: ${_mapProvider.errorMessage}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _mapProvider.errorMessage = null;
              _mapProvider.isLoading = true;
              _mapProvider.initializeHERESDK();
            },
            child: Text('Try Again'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => _showDebugInfo(),
            child: Text('Show Debug Info'),
          ),
        ],
      ),
    );
  }
}
