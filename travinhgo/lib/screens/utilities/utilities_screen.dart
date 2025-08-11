import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/search.dart';
import 'package:sizer/sizer.dart';
import 'package:travinhgo/widget/accomodation_card.dart';

class UtilitiesScreen extends StatefulWidget {
  const UtilitiesScreen({super.key});

  @override
  State<UtilitiesScreen> createState() => _UtilitiesScreenState();
}

class _UtilitiesScreenState extends State<UtilitiesScreen> {
  List<Place> _allPlaces = [];
  List<Place> _paginatedPlaces = [];
  bool _isSearchInitialized = false;
  int _currentPage = 0;
  static const int _itemsPerPage = 20;
  bool _isLoading = true;

  // Map to hold utility categories with their SDK PlaceCategory and a stable key
  final Map<String, PlaceCategory> _utilityCategories = {
    'atm': PlaceCategory(PlaceCategory.businessAndServicesAtm),
    'gas_station':
        PlaceCategory(PlaceCategory.businessAndServicesFuelingStation),
    'charging_station':
        PlaceCategory(PlaceCategory.businessAndServicesEvChargingStation),
    'hospital': PlaceCategory(PlaceCategory.facilitiesHospitalHealthcare),
    'police_station':
        PlaceCategory(PlaceCategory.businessAndServicesPoliceFireEmergency),
    'restaurant': PlaceCategory(PlaceCategory.eatAndDrinkRestaurant),
    'cinema': PlaceCategory(PlaceCategory.goingOutCinema),
  };

  // The key of the currently selected category from the map above
  late String _selectedCategoryKey;

  @override
  void initState() {
    super.initState();
    // Set the default selected category using a stable key
    _selectedCategoryKey = 'atm';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isSearchInitialized) {
      // Start the initial search with the default category
      _searchForUtilities(_utilityCategories[_selectedCategoryKey]!);
      _isSearchInitialized = true;
    }
  }

  void _searchForUtilities(PlaceCategory category) async {
    // Reset state for the new search
    setState(() {
      _isLoading = true;
      _allPlaces = [];
      _paginatedPlaces = [];
      _currentPage = 0;
    });

    final locale = Localizations.localeOf(context);
    final languageCode =
        locale.languageCode == 'vi' ? LanguageCode.viVn : LanguageCode.enUs;

    // This should be a singleton or managed by a provider
    final searchEngine = SearchEngine();

    // 1. Tải và giải mã tệp JSON
    final String jsonString =
        await rootBundle.loadString('assets/geo/travinh.json');
    final Map<String, dynamic> geoJson = json.decode(jsonString);

    // 2. Trích xuất danh sách tọa độ
    final List<dynamic> coordinatesList =
        geoJson['geometry']['coordinates'][0][0];

    // 3. Chuyển đổi tọa độ từ [kinh độ, vĩ độ] sang GeoCoordinates(vĩ độ, kinh độ)
    final List<GeoCoordinates> vertices = coordinatesList.map((coords) {
      return GeoCoordinates(coords[1], coords[0]);
    }).toList();

    if (vertices.isEmpty) {
      print("No vertices found in GeoJSON");
      return;
    }

    // 4. Tính toán trung tâm của đa giác để thực hiện tìm kiếm
    final center = _getPolygonCentroid(vertices);

    // 5. Tạo truy vấn tìm kiếm tại trung tâm (dựa trên API gốc)
    final categoryQueryArea =
        CategoryQueryArea.withCircle(center, GeoCircle(center, 10000));
    // The query now uses a single category passed to the function
    final query =
        CategoryQuery.withCategoriesInArea([category], categoryQueryArea);
    final searchOptions = SearchOptions();
    searchOptions.languageCode = languageCode;
    searchOptions.maxItems = 100; // Tăng giới hạn kết quả tìm kiếm

    // 6. Thực hiện tìm kiếm
    searchEngine.searchByCategory(query, searchOptions, (error, items) {
      if (error != null) {
        print("Search failed: ${error.toString()}");
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      if (mounted) {
        // 7. Lọc kết quả bằng thuật toán ray-casting để chỉ giữ lại các điểm trong đa giác
        List<Place> placesInsidePolygon = items!
            .where((place) =>
                place.geoCoordinates != null &&
                _isPointInPolygon(place.geoCoordinates!, vertices))
            .toList();

        // Special filtering for gas stations to exclude charging stations
        if (_selectedCategoryKey == 'gas_station') {
          placesInsidePolygon = placesInsidePolygon.where((place) {
            final title = place.title.toLowerCase();
            return !title.contains('sạc') && !title.contains('vinfast');
          }).toList();
        }

        print(
            "Found ${placesInsidePolygon.length} utilities inside the polygon.");

        setState(() {
          _allPlaces = placesInsidePolygon;
          _currentPage = 0;
          _updatePaginatedPlaces();
          _isLoading = false;
        });
      }
    });
  }

  void _updatePaginatedPlaces() {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage > _allPlaces.length)
        ? _allPlaces.length
        : startIndex + _itemsPerPage;

    setState(() {
      _paginatedPlaces = _allPlaces.sublist(startIndex, endIndex);
    });
  }

  GeoCoordinates _getPolygonCentroid(List<GeoCoordinates> vertices) {
    double sumLat = 0.0;
    double sumLon = 0.0;
    for (final vertex in vertices) {
      sumLat += vertex.latitude;
      sumLon += vertex.longitude;
    }
    return GeoCoordinates(sumLat / vertices.length, sumLon / vertices.length);
  }

  bool _isPointInPolygon(GeoCoordinates point, List<GeoCoordinates> polygon) {
    int crossings = 0;
    for (int i = 0; i < polygon.length; i++) {
      final GeoCoordinates a = polygon[i];
      final GeoCoordinates b = polygon[(i + 1) % polygon.length];
      if (a.latitude > point.latitude != b.latitude > point.latitude) {
        final double atX = (b.longitude - a.longitude) *
                (point.latitude - a.latitude) /
                (b.latitude - a.latitude) +
            a.longitude;
        if (point.longitude < atX) {
          crossings++;
        }
      }
    }
    return crossings % 2 == 1;
  }

  Widget _buildCategoryChips() {
    final appLocalizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    String getLocalizedCategoryName(String key) {
      switch (key) {
        case 'atm':
          return appLocalizations.atm;
        case 'gas_station':
          return appLocalizations.gasStation;
        case 'charging_station':
          return appLocalizations.chargingStation;
        case 'hospital':
          return appLocalizations.hospital;
        case 'police_station':
          return appLocalizations.policeStation;
        case 'restaurant':
          return appLocalizations.restaurant;
        case 'cinema':
          return appLocalizations.cinema;
        default:
          return key; // Fallback
      }
    }

    return Container(
      height: 60,
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        itemCount: _utilityCategories.length,
        itemBuilder: (context, index) {
          final key = _utilityCategories.keys.elementAt(index);
          final isSelected = key == _selectedCategoryKey;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(getLocalizedCategoryName(key)),
              selected: isSelected,
              onSelected: (bool selected) {
                if (selected) {
                  setState(() {
                    _selectedCategoryKey = key;
                  });
                  _searchForUtilities(_utilityCategories[key]!);
                }
              },
              backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5),
              selectedColor: colorScheme.primary,
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : (isDarkMode ? Colors.white : colorScheme.onSurface),
              ),
              side: const BorderSide(color: Colors.transparent),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) {
      return Container(); // Show nothing while loading, as the overlay handles it
    }

    final appLocalizations = AppLocalizations.of(context)!;
    if (_allPlaces.isEmpty) {
      return Center(
          child: Text(appLocalizations.noUtilitiesFound,
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _paginatedPlaces.length,
      itemBuilder: (context, index) {
        return AccomodationCard(place: _paginatedPlaces[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            color: colorScheme.primary,
            child: Column(
              children: [
                SizedBox(height: statusBarHeight),
                _buildHeader(context),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildCategoryChips(),
                        Expanded(
                          child: SafeArea(
                            top: false,
                            bottom:
                                false, // Let pagination controls handle bottom safe area
                            child: _buildBody(),
                          ),
                        ),
                        _buildPaginationControls(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final totalPages = (_allPlaces.length / _itemsPerPage).ceil();
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios,
                  color: isDarkMode ? Colors.white : Colors.black),
              onPressed: _currentPage == 0
                  ? null
                  : () {
                      setState(() {
                        _currentPage--;
                        _updatePaginatedPlaces();
                      });
                    },
            ),
            Text(
              AppLocalizations.of(context)!.pageInfo(
                (_currentPage + 1).toString(),
                totalPages.toString(),
              ),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios,
                  color: isDarkMode ? Colors.white : Colors.black),
              onPressed: _currentPage >= totalPages - 1
                  ? null
                  : () {
                      setState(() {
                        _currentPage++;
                        _updatePaginatedPlaces();
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  // Builds the header of the screen, including the back button and title.
  Widget _buildHeader(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              appLocalizations.utilities,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48), // To balance the IconButton
        ],
      ),
    );
  }
}
