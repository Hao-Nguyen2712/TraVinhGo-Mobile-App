import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../../providers/map_provider.dart';
import '../../providers/map_provider.dart' show TransportMode;
import 'map_ui_utils.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Widget panel chọn địa điểm cho tính năng định tuyến
class LocationSelectionPanel extends StatelessWidget {
  final TextEditingController departureController;
  final FocusNode departureFocusNode;
  final MapProvider provider;

  const LocationSelectionPanel({
    Key? key,
    required this.departureController,
    required this.departureFocusNode,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF2C2C2E) : colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Origin and destination inputs
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                // Navigation row with back and swap buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    if (provider.isRoutingMode)
                      _buildIconButton(
                        context,
                        icon: Icons.arrow_back,
                        onPressed: () => provider.cancelRouting(),
                      ),
                    Row(
                      children: [
                        // Use current location button
                        _buildIconButton(
                          context,
                          icon: Icons.my_location,
                          onPressed: () =>
                              provider.useCurrentLocationAsDeparture(),
                          tooltip: AppLocalizations.of(context)!.myLocation,
                        ),
                        const SizedBox(width: 8),
                        // Swap button
                        _buildIconButton(
                          context,
                          icon: Icons.swap_vert,
                          onPressed: () =>
                              provider.swapDepartureAndDestination(),
                          tooltip: AppLocalizations.of(context)!.swapLocations,
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 8),

                // Departure point
                _buildRoutePoint(
                  context: context,
                  icon: Icons.location_on,
                  iconColor: isDarkMode
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                  title: AppLocalizations.of(context)!.departurePoint,
                  locationName: provider.departureName ?? "Không xác định",
                  locationAddress: provider.departureAddress,
                  onTap: () {
                    provider.showDepartureInput();
                    departureFocusNode.requestFocus();
                  },
                  isDeparture: true,
                ),

                if (!provider.isShowingDepartureInput) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 40.0),
                    child: Divider(
                        height: 1,
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.5)),
                  ),
                  _buildRoutePoint(
                    context: context,
                    icon: Icons.location_on,
                    iconColor: Theme.of(context).colorScheme.error,
                    title: AppLocalizations.of(context)!.destinationPoint,
                    locationName: provider.destinationName ?? "Không xác định",
                    locationAddress: provider.destinationAddress,
                    onTap: () {
                      // Destination is not editable directly from here
                    },
                    isEditable: false,
                  ),
                ],

                // Search suggestions for departure
                if (provider.isShowingDepartureInput &&
                    provider.searchSuggestions.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemCount: provider.searchSuggestions.length,
                      itemBuilder: (context, index) {
                        // Guard against RangeError if the list is modified during build
                        if (index >= provider.searchSuggestions.length) {
                          return const SizedBox.shrink();
                        }
                        final suggestion = provider.searchSuggestions[index];
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 0),
                          leading: Icon(Icons.location_on_outlined,
                              size: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                          title: Text(
                            suggestion.title ?? "Unnamed location",
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () {
                            provider.selectDepartureSuggestion(suggestion);
                            departureController.text = suggestion.title ?? "";
                            FocusScope.of(context).unfocus(); // Hide keyboard
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Instructions for map tap mode
          if (provider.isShowingDepartureInput &&
              provider.searchSuggestions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16.0),
                  bottomRight: Radius.circular(16.0),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app,
                      color: colorScheme.onPrimaryContainer, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.selectDeparturePoint,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer),
                        ),
                        SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.tapOrSearchDeparture,
                          style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Builds a styled circular icon button
  Widget _buildIconButton(BuildContext context,
      {required IconData icon,
      required VoidCallback onPressed,
      String? tooltip}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF3A3A3C) : colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 22),
        onPressed: onPressed,
        color: isDarkMode ? Colors.white : colorScheme.onSurfaceVariant,
        tooltip: tooltip,
        padding: EdgeInsets.all(8),
        constraints: BoxConstraints(),
      ),
    );
  }

  /// Builds a single route point (departure or destination) UI
  Widget _buildRoutePoint({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String locationName,
    String? locationAddress,
    required VoidCallback onTap,
    bool isEditable = true,
    bool isDeparture = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Determine if the text field should be shown
    final bool showTextField = isDeparture && provider.isShowingDepartureInput;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: showTextField
              ?
              // Show a text field for departure input
              TextField(
                  controller: departureController,
                  focusNode: departureFocusNode,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      provider.searchDepartureLocations(value);
                    } else {
                      provider.clearSearchResults();
                    }
                  },
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.enterDeparturePoint,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : null,
                  ),
                )
              :
              // Show location name as text
              InkWell(
                  onTap: isEditable ? onTap : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.white70
                              : colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locationName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (locationAddress != null && locationAddress.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            locationAddress,
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        if (isEditable && !showTextField)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Icon(Icons.edit,
                color: isDarkMode
                    ? Colors.white54
                    : colorScheme.onSurfaceVariant.withOpacity(0.7),
                size: 20),
          ),
      ],
    );
  }
}

/// Lớp tiện ích xử lý địa chỉ
class LocationAddressHelper {
  // Hàm trích xuất địa chỉ rút gọn từ tên địa điểm
  static String? getShortAddress(String? locationName) {
    if (locationName == null || locationName.isEmpty) {
      return null;
    }

    // Kiểm tra nếu có dấu phẩy để tách địa chỉ
    if (locationName.contains(",")) {
      List<String> parts = locationName.split(",");
      if (parts.length > 1) {
        return "${parts[0].trim()},...";
      }
    }

    // Nếu tên quá dài, rút gọn
    if (locationName.length > 30) {
      return "${locationName.substring(0, 30)}...";
    }

    return locationName;
  }

  // Hàm lấy địa chỉ đầy đủ
  static String? getFullAddress(String? locationName) {
    if (locationName == null || locationName.isEmpty) {
      return null;
    }

    // Nếu có tên địa điểm đi, giả định địa chỉ đầy đủ
    if (locationName ==
        "Trung tâm Bảo tồn Di tích Lịch sử và Văn hóa Trà Vinh (Khu trưng bày Khmer - Việt - Hoa), Phường 1, Thành phố Trà Vinh") {
      return "26 Đường Nguyễn Thị Minh Khai, Phường 1, Thành phố Trà Vinh, Tỉnh Trà Vinh";
    }

    if (locationName ==
        "Chi Cục Thi Hành Án Dân Sự Thành Phố Trà Vinh - Trụ sở tiếp dân khu vực số 3") {
      return "54 Lê Thánh Tôn, Phường 2, Thành phố Trà Vinh, Tỉnh Trà Vinh";
    }

    // Trường hợp khác, dùng chính tên địa điểm làm địa chỉ đầy đủ
    return locationName;
  }

  // Function to show the full address dialog
  static void showFullAddressDialog(BuildContext context, String title,
      String locationName, String fullAddress, MapProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                title == "Điểm đi" ? Icons.trip_origin : Icons.place,
                color: title == "Điểm đi"
                    ? colorScheme.primary
                    : colorScheme.error,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locationName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Địa chỉ đầy đủ:",
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: colorScheme.outline.withOpacity(0.5)),
                ),
                child: Text(
                  fullAddress,
                  style: TextStyle(
                    fontSize: 15,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Đóng",
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            if (title == "Điểm đến")
              TextButton(
                child: Text(
                  "Chỉ đường",
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Bắt đầu chỉ đường tới điểm này
                  if (title == "Điểm đến" &&
                      provider.destinationCoordinates != null) {
                    // Nếu đang không ở chế độ chỉ đường, bắt đầu chỉ đường
                    if (!provider.isRoutingMode) {
                      provider.startRouting(
                          provider.destinationCoordinates!, locationName);
                    }
                    // Nếu đã ở chế độ chỉ đường, không cần làm gì vì đã đang chỉ đường đến điểm này
                  }
                },
              ),
          ],
        );
      },
    );
  }
}

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
    bool isDarkMode,
  ) {
    bool isSelected = provider.selectedTransportMode == mode;
    final colorScheme = Theme.of(context).colorScheme;

    // Get the duration for this transport mode from the provider's stored durations
    int? duration = provider.routeDurations[mode];

    // Always show the duration if available, otherwise show the label
    String displayText = duration != null
        ? MapUiUtils.formatDuration(duration)
        : MapUiUtils.getTransportModeLabel(mode, AppLocalizations.of(context)!);

    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setTransportMode(mode),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDarkMode
                    ? colorScheme.primary.withOpacity(0.3)
                    : colorScheme.primary.withOpacity(0.1))
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? colorScheme.primary
                    : (isDarkMode
                        ? Colors.white70
                        : colorScheme.onSurfaceVariant),
                size: 28,
              ),
              SizedBox(height: 4),
              Text(
                displayText,
                style: TextStyle(
                  color: isSelected
                      ? (isDarkMode ? Colors.white : colorScheme.onSurface)
                      : (isDarkMode
                          ? Colors.white70
                          : colorScheme.onSurfaceVariant),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
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
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: LocationSelectionPanel(
                departureController: _departureController,
                departureFocusNode: _departureFocusNode,
                provider: provider,
              ),
            ),

            // Bottom route summary panel - shown only when route is calculated
            if (showRouteSummary)
              SlidingUpPanel(
                minHeight: 170,
                maxHeight: 450,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.0),
                  topRight: Radius.circular(24.0),
                ),
                panel: _buildDraggablePanel(provider, isDarkMode),
                collapsed: _buildCollapsedPanel(provider, isDarkMode),
                body: Container(), // The underlying map is the body
              ),
          ],
        );
      },
    );
  }

  /// Builds the part of the panel that is always visible (collapsed state)
  Widget _buildCollapsedPanel(MapProvider provider, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? Color(0xFF2C2C2E)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white54
                  : Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.5),
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          // Route summary
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
            child: _buildRouteSummary(provider, isDarkMode),
          ),
          SizedBox(height: 8),
          // Transport mode tabs
          _buildTransportModeTabs(provider, isDarkMode),
        ],
      ),
    );
  }

  /// Builds the main draggable panel content
  Widget _buildDraggablePanel(MapProvider provider, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? Color(0xFF2C2C2E)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white54
                  : Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.5),
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          // Route summary
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
            child: _buildRouteSummary(provider, isDarkMode),
          ),
          SizedBox(height: 8),
          // Transport mode tabs
          _buildTransportModeTabs(provider, isDarkMode),
          // Route details
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    SizedBox(height: 16),
                    _buildRoutePointsInfo(provider, isDarkMode),
                    SizedBox(height: 16),
                    _buildActionButtons(provider, isDarkMode),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Transport mode tabs
  Widget _buildTransportModeTabs(MapProvider provider, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: isDarkMode
                  ? Colors.white24
                  : Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildTransportTab(context, provider, TransportMode.car,
              Icons.directions_car, "Car", isDarkMode),
          _buildTransportTab(context, provider, TransportMode.motorcycle,
              Icons.motorcycle, "Motorcycle", isDarkMode),
          _buildTransportTab(context, provider, TransportMode.pedestrian,
              Icons.directions_walk, "Walk", isDarkMode),
        ],
      ),
    );
  }

  /// Route summary (time and distance)
  Widget _buildRouteSummary(MapProvider provider, bool isDarkMode) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF3A3A3C) : colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDarkMode
                ? Colors.transparent
                : colorScheme.outline.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time and arrival
          Row(
            children: [
              Icon(Icons.access_time,
                  color: isDarkMode ? Colors.white : colorScheme.primary),
              SizedBox(width: 8),
              Text(
                "${MapUiUtils.formatDuration(provider.routeDurationInSeconds!)}",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : null),
              ),
              const Spacer(),
              Text(
                MapUiUtils.getEstimatedArrivalTime(
                    provider.routeDurationInSeconds!, context),
                style: TextStyle(
                    color: isDarkMode ? Colors.white70 : colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 4),
          // Distance and route info
          Row(
            children: [
              Icon(Icons.straighten,
                  color: isDarkMode ? Colors.white70 : colorScheme.secondary,
                  size: 20),
              SizedBox(width: 8),
              Text(
                MapUiUtils.formatDistance(provider.routeLengthInMeters!),
                style: TextStyle(
                    color: isDarkMode ? Colors.white : colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 16),
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt,
                        color: isDarkMode
                            ? Colors.white
                            : colorScheme.onSecondaryContainer,
                        size: 16),
                    SizedBox(width: 4),
                    Text(
                      "Đường nhanh nhất",
                      style: TextStyle(
                          color: isDarkMode
                              ? Colors.white
                              : colorScheme.onSecondaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// From/To location info
  Widget _buildRoutePointsInfo(MapProvider provider, bool isDarkMode) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF3A3A3C) : colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDarkMode
                ? Colors.transparent
                : colorScheme.outline.withOpacity(0.5)),
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
                    color: colorScheme.secondary, shape: BoxShape.circle),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  provider.departureName ?? "Trung tâm Trà Vinh",
                  style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : colorScheme.onSurface),
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
            color: isDarkMode
                ? Colors.white30
                : colorScheme.outline.withOpacity(0.5),
          ),
          // To location
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: colorScheme.error, shape: BoxShape.circle),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  provider.destinationName ?? "Điểm đến",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Action buttons (start, save, etc.)
  Widget _buildActionButtons(MapProvider provider, bool isDarkMode) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Transport mode icon with label
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                  MapUiUtils.getTransportModeIcon(
                      provider.selectedTransportMode),
                  color: isDarkMode ? Colors.white : colorScheme.primary,
                  size: 20),
              SizedBox(width: 6),
              Text(
                MapUiUtils.getTransportModeLabel(provider.selectedTransportMode,
                    AppLocalizations.of(context)!),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : colorScheme.primary),
              ),
            ],
          ),
        ),
        Spacer(),
        // Start button
        ElevatedButton(
          onPressed: () {/* Start navigation - future implementation */},
          style: ElevatedButton.styleFrom(
            backgroundColor: isDarkMode
                ? colorScheme.primary.withOpacity(0.8)
                : colorScheme.primary,
            foregroundColor: isDarkMode ? Colors.black : colorScheme.onPrimary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            elevation: 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.navigation, size: 20),
              SizedBox(width: 6),
              Text("Bắt đầu",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(width: 10),
        // Save button
        IconButton(
          onPressed: () {/* Save route - future implementation */},
          icon: Icon(Icons.bookmark_border,
              color: isDarkMode ? Colors.white70 : colorScheme.secondary),
          style: IconButton.styleFrom(
            backgroundColor: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : colorScheme.secondary.withOpacity(0.1),
            shape: CircleBorder(),
          ),
          tooltip: "Lưu",
        ),
      ],
    );
  }
}
