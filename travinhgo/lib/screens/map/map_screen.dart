import 'package:flutter/material.dart';
import 'package:here_sdk/mapview.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../Models/Maps/top_favorite_destination.dart';
import '../../providers/map_provider.dart';

/// Map Screen that displays HERE Maps with POIs and user location
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
    }
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

              // Search bar at the top
              _buildSearchBar(),

              // Location button
              _buildLocationButton(),

              // Category buttons
              _buildCategoryButtons(),

              // Loading indicator
              if (provider.isLoading && provider.mapController != null)
                const Center(child: CircularProgressIndicator()),

              // Favorite destinations slider at the bottom
              _buildFavoriteDestinationsSlider(),

              // POI information popup
              _buildPoiPopup(),
            ],
          ),
        );
      },
    );
  }

  /// Builds the search bar widget
  Widget _buildSearchBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Container(
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
          decoration: InputDecoration(
            hintText: 'Search here',
            hintStyle: TextStyle(color: Colors.grey),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.green.withAlpha(230),
              size: 24,
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.filter_list, color: Colors.grey),
              onPressed: () {
                // Implement search filter functionality
              },
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
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
    return Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      left: 0,
      right: 0,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withAlpha(240),
              Colors.white.withAlpha(200),
            ],
          ),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 8),
          itemCount: _mapProvider.categories.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(
                  _mapProvider.categories[index],
                  style: TextStyle(
                    fontSize: 12,
                    color: _mapProvider.selectedCategoryIndex == index
                        ? Colors.white
                        : Colors.black.withAlpha(200),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: _mapProvider.selectedCategoryIndex == index,
                selectedColor: Colors.green.withAlpha(240),
                backgroundColor: Colors.white.withAlpha(230),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                onSelected: (selected) => _onCategorySelected(index, selected),
              ),
            );
          },
        ),
      ),
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
