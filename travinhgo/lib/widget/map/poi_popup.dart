import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

import '../../providers/map_provider.dart';
import '../../providers/map_provider.dart' show TransportMode;

/// POI information popup widget
class PoiPopup extends StatelessWidget {
  const PoiPopup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, provider, _) {
        if (!provider.showPoiPopup || provider.lastPoiName == null) {
          return SizedBox.shrink();
        }

        // Extract POI information
        Map<String, String>? placeInfo;
        if (provider.currentCustomMarker != null &&
            provider.currentCustomMarker!.metadata != null) {
          placeInfo =
              provider.getPlaceInfoFromMarker(provider.currentCustomMarker!);
        }

        // Get place name, category, address and coordinates
        final name = provider.lastPoiName ?? "Unknown Place";
        final category = provider.lastPoiCategory ?? "";
        final address = placeInfo?['address'] ?? "";
        final phone = placeInfo?['phone'] ?? "";
        final coordinates = provider.lastPoiCoordinates;

        // Dummy rating - would come from actual data in a real app
        double rating = 4.7;

        return Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 20,
          left: 0,
          right: 0,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                // Header with title, rating and close button
                _buildHeader(name, rating, provider),

                // Action buttons
                _buildActionButtons(provider),

                // Image gallery
                _buildImageGallery(),

                // Address information
                _buildAddressInfo(address, category, phone, coordinates),
              ],
            ),
          ),
        );
      },
    );
  }

  // Header with title, rating and close button
  Widget _buildHeader(String name, double rating, MapProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                // Rating bar
                Row(
                  children: [
                    Text(
                      rating.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => provider.closePoiPopup(),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "×",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Action buttons row
  Widget _buildActionButtons(MapProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Direction button
          _buildActionButton(
            icon: Icons.directions,
            label: "Direct",
            color: Colors.teal,
            onTap: () {
              // Start routing mode with the POI as destination
              if (provider.lastPoiCoordinates != null &&
                  provider.lastPoiName != null) {
                // Close the POI popup first
                provider.closePoiPopup();

                // Start routing with the POI as destination
                provider.startRouting(
                    provider.lastPoiCoordinates!, provider.lastPoiName!);

                // Set car as the default transport mode for better visibility
                provider.setTransportMode(TransportMode.car);

                // Set Tra Vinh center as departure point and calculate route
                provider.useTraVinhCenterAsDeparture();

                // Log the route creation
                developer.log(
                    'Creating route from Tra Vinh center to ${provider.lastPoiName}',
                    name: 'PoiPopup');
              }
            },
          ),
          // Start button
          _buildActionButton(
            icon: Icons.arrow_upward_sharp,
            label: "Start",
            color: Colors.green,
            onTap: () {
              // Navigation functionality can be added here
            },
          ),
          // Detail button
          _buildActionButton(
            icon: Icons.info_outline,
            label: "Detail",
            color: Colors.blue,
            onTap: () {
              // Show detailed information
            },
          ),
          // Share button
          _buildActionButton(
            icon: Icons.share,
            label: "Share",
            color: Colors.deepOrange,
            onTap: () {
              // Share functionality
            },
          ),
        ],
      ),
    );
  }

  // Image gallery
  Widget _buildImageGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12),
        Container(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Sample images - Replace with actual POI images when available
              _buildGalleryImage("assets/images/sample/destination1.jpg"),
              _buildGalleryImage("assets/images/sample/destination2.jpg"),
              _buildGalleryImage("assets/images/sample/destination3.jpg"),
            ],
          ),
        ),
      ],
    );
  }

  // Address information
  Widget _buildAddressInfo(
      String address, String category, String phone, var coordinates) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show actual address if available
          if (address.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

          // Show category if available
          if (category.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Show phone if available
          if (phone.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      phone,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Show coordinates if available
          if (coordinates != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.my_location, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${coordinates.latitude.toStringAsFixed(6)}, ${coordinates.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Helper method to create action buttons
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12),
          )
        ],
      ),
    );
  }

  // Helper method to create gallery images
  Widget _buildGalleryImage(String imagePath) {
    return Container(
      width: 140,
      margin: EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
