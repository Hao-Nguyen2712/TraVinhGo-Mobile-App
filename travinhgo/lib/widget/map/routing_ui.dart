import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/map_provider.dart' show TransportMode;
import 'map_ui_utils.dart';

/// Routing UI components for map navigation
class RoutingUI extends StatefulWidget {
  const RoutingUI({Key? key}) : super(key: key);

  @override
  State<RoutingUI> createState() => _RoutingUIState();
}

class _RoutingUIState extends State<RoutingUI> {
  final TextEditingController _departureController = TextEditingController();
  final FocusNode _departureFocusNode = FocusNode();

  @override
  void dispose() {
    _departureController.dispose();
    _departureFocusNode.dispose();
    super.dispose();
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

  // Helper method to build transport tabs
  Widget _buildTransportTab(
    BuildContext context,
    MapProvider provider,
    TransportMode mode,
    IconData icon,
    String label,
  ) {
    bool isSelected = provider.selectedTransportMode == mode;

    // Get the duration for this transport mode from the provider's stored durations
    int? duration = provider.routeDurations[mode];

    // Always show the duration if available, otherwise show the label
    String displayText =
        duration != null ? MapUiUtils.formatDuration(duration) : label;

    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setTransportMode(mode),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected ? Colors.teal.withOpacity(0.1) : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.teal : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.teal : Colors.grey,
                size: 32, // Larger icon size
              ),
              SizedBox(height: 6),
              Text(
                displayText,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15, // Larger text
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, provider, _) {
        if (!provider.isRoutingMode) {
          return SizedBox.shrink();
        }

        // Update departure controller text when routing mode is active
        _updateDepartureControllerText(provider);

        // Check if we have all the route information to show the route summary
        bool showRouteSummary = provider.routeLengthInMeters != null &&
            provider.routeDurationInSeconds != null &&
            !provider.isShowingDepartureInput;

        return Stack(
          children: [
            // Top location selection panel
            Positioned(
              top: MediaQuery.of(context).padding.top - 30,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                // No elevation here to ensure suggestions can overlay
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Origin and destination inputs
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              // Navigation row with back and swap buttons
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Back button
                                  if (provider.isRoutingMode)
                                    IconButton(
                                      icon: Icon(Icons.arrow_back, size: 28),
                                      onPressed: () => provider.cancelRouting(),
                                      color: Colors.black54,
                                      padding: EdgeInsets.fromLTRB(0, 4, 0, 2),
                                    )
                                  else
                                    SizedBox(
                                        width:
                                            36), // Empty space to maintain alignment

                                  // Swap button
                                  IconButton(
                                    icon: Icon(Icons.swap_vert,
                                        color: Colors.blue, size: 28),
                                    onPressed: () =>
                                        provider.swapDepartureAndDestination(),
                                    tooltip: "Swap locations",
                                    padding: EdgeInsets.all(4),
                                  ),
                                ],
                              ),

                              // Origin input row with departure point image
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/markers/departure_point.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: provider.isShowingDepartureInput
                                        ? Container(
                                            height: 56, // Increased height
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.green,
                                                width: 1.5,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: TextField(
                                              controller: _departureController,
                                              focusNode: _departureFocusNode,
                                              autofocus:
                                                  true, // Auto focus when showing input
                                              decoration: InputDecoration(
                                                hintText: "Nhập vị trí của bạn",
                                                hintStyle: TextStyle(
                                                    color: Colors.grey),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  borderSide: BorderSide
                                                      .none, // Remove default border
                                                ),
                                                filled: true,
                                                fillColor: Colors.white,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical:
                                                            16), // Increased padding
                                              ),
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black87),
                                              onChanged: (text) {
                                                if (text.length >= 2) {
                                                  provider
                                                      .searchDepartureLocations(
                                                          text);
                                                } else if (text.isEmpty) {
                                                  provider.clearSearchResults();
                                                }
                                              },
                                            ),
                                          )
                                        : Container(
                                            height: 56, // Increased height
                                            padding: EdgeInsets.symmetric(
                                                vertical: 8),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.green,
                                                width: 1.5,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: GestureDetector(
                                              onTap: () {
                                                provider.showDepartureInput();
                                                // Request focus after a short delay to ensure the text field is built
                                                Future.delayed(
                                                    Duration(milliseconds: 100),
                                                    () {
                                                  _departureFocusNode
                                                      .requestFocus();
                                                });
                                              },
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Padding(
                                                  padding:
                                                      EdgeInsets.only(left: 12),
                                                  child: Text(
                                                    provider.departureName ??
                                                        "Vị trí của bạn",
                                                    style:
                                                        TextStyle(fontSize: 16),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                  ),
                                  if (provider.isShowingDepartureInput)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Use current location
                                        IconButton(
                                          icon: Icon(Icons.my_location,
                                              size: 26, color: Colors.blue),
                                          onPressed: () => provider
                                              .useTraVinhCenterAsDeparture(),
                                          padding: EdgeInsets.all(4),
                                          constraints: BoxConstraints(),
                                          tooltip: "Use current location",
                                        ),
                                      ],
                                    ),
                                ],
                              ),

                              Divider(),

                              // Destination row with destination point image
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/images/markers/destination_point.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      height: 56, // Increased height
                                      padding:
                                          EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.green,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 12),
                                          child: Text(
                                            provider.destinationName ??
                                                "Điểm đến",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Instructions for map tap mode
                    if (provider.isShowingDepartureInput &&
                        provider.searchSuggestions.isEmpty)
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: Colors.blue[50],
                        child: Row(
                          children: [
                            Icon(Icons.touch_app,
                                color: Colors.blue[800], size: 22),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Chọn điểm khởi hành:",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[800]),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Chạm vào vị trí trên bản đồ hoặc nhập địa điểm vào ô tìm kiếm",
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.blue[800]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom route summary panel - shown only when route is calculated
            if (showRouteSummary)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Transport mode tabs
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Colors.grey.withOpacity(0.2), width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildTransportTab(
                              context,
                              provider,
                              TransportMode.car,
                              Icons.directions_car,
                              "Car",
                            ),
                            _buildTransportTab(
                              context,
                              provider,
                              TransportMode.motorcycle,
                              Icons.motorcycle,
                              "Motorcycle",
                            ),
                            _buildTransportTab(
                              context,
                              provider,
                              TransportMode.pedestrian,
                              Icons.directions_walk,
                              "Walk",
                            ),
                          ],
                        ),
                      ),

                      // Route details
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Route summary with time and arrival
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Time and arrival
                                  Row(
                                    children: [
                                      Icon(Icons.access_time,
                                          color: Colors.teal),
                                      SizedBox(width: 8),
                                      Text(
                                        "${MapUiUtils.formatDuration(provider.routeDurationInSeconds!)}",
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Spacer(),
                                      Text(
                                        MapUiUtils.getEstimatedArrivalTime(
                                            provider.routeDurationInSeconds!),
                                        style: TextStyle(
                                          color: Colors.teal,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),

                                  // Distance and route info
                                  Row(
                                    children: [
                                      Icon(Icons.straighten,
                                          color: Colors.blue.shade700,
                                          size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        MapUiUtils.formatDistance(
                                            provider.routeLengthInMeters!),
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.bolt,
                                                color: Colors.blue, size: 16),
                                            SizedBox(width: 4),
                                            Text(
                                              "Đường nhanh nhất",
                                              style: TextStyle(
                                                color: Colors.blue.shade700,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 16),

                            // Route source and destination info
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // From location
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          provider.departureName ??
                                              "Trung tâm Trà Vinh",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[800],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Dotted line between points
                                  Container(
                                    margin: EdgeInsets.only(left: 4),
                                    height: 20,
                                    width: 1,
                                    color: Colors.grey[300],
                                  ),

                                  // To location
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          provider.destinationName ??
                                              "Điểm đến",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 16),

                            // Transport label and buttons
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Transport mode icon with label
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        MapUiUtils.getTransportModeIcon(
                                            provider.selectedTransportMode),
                                        color: Colors.teal,
                                        size: 20,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        MapUiUtils.getTransportModeLabel(
                                            provider.selectedTransportMode),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Spacer(),

                                // Start button
                                ElevatedButton(
                                  onPressed: () {
                                    // Start navigation - future implementation
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 12),
                                    elevation: 2,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.navigation, size: 20),
                                      SizedBox(width: 6),
                                      Text("Bắt đầu",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),

                                SizedBox(width: 10),

                                // Save button
                                IconButton(
                                  onPressed: () {
                                    // Save route - future implementation
                                  },
                                  icon: Icon(Icons.bookmark_border,
                                      color: Colors.blue),
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        Colors.blue.withOpacity(0.1),
                                    shape: CircleBorder(),
                                  ),
                                  tooltip: "Lưu",
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Search suggestions for departure (positioned at the end of Stack to ensure it's on top)
            if (provider.isShowingDepartureInput &&
                provider.searchSuggestions.isNotEmpty)
              Positioned(
                top: MediaQuery.of(context).padding.top +
                    100, // Adjusted position to account for the swap button and increased height
                left: 40,
                right: 40,
                child: Material(
                  elevation: 30, // Increased elevation for higher z-index
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    constraints: BoxConstraints(
                        maxHeight:
                            240), // Increased max height to show more results
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      separatorBuilder: (context, index) => Divider(height: 1),
                      itemCount: provider.searchSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = provider.searchSuggestions[index];
                        return ListTile(
                          dense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          leading: Icon(Icons.location_on_outlined,
                              size: 18, color: Colors.grey[700]),
                          title: Text(
                            suggestion.title ?? "Unnamed location",
                            style: TextStyle(fontSize: 14),
                          ),
                          onTap: () {
                            provider.selectDepartureSuggestion(suggestion);
                            _departureController.text = suggestion.title ?? "";
                            FocusScope.of(context).unfocus(); // Hide keyboard
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
