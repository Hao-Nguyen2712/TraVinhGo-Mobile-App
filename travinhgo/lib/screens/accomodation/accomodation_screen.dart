import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/search.dart';
import 'package:sizer/sizer.dart';
import 'package:travinhgo/widget/accomodation_card.dart';

class AccomodationScreen extends StatefulWidget {
  const AccomodationScreen({super.key});

  @override
  State<AccomodationScreen> createState() => _AccomodationScreenState();
}

class _AccomodationScreenState extends State<AccomodationScreen> {
  List<Place> _allAccomodations = [];
  List<Place> _paginatedAccomodations = [];
  bool _isSearchInitialized = false;
  int _currentPage = 0;
  static const int _itemsPerPage = 20;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isSearchInitialized) {
      _searchForAccomodations();
      _isSearchInitialized = true;
    }
  }

  void _searchForAccomodations() async {
    final locale = Localizations.localeOf(context);
    final languageCode =
        locale.languageCode == 'vi' ? LanguageCode.viVn : LanguageCode.enUs;

    // This should be a singleton or managed by a provider
    final searchEngine = SearchEngine();
    // Thay đổi thành một danh sách để có thể tìm kiếm nhiều loại hình
    final List<PlaceCategory> categories = [
      PlaceCategory(PlaceCategory.accommodation),
      PlaceCategory(PlaceCategory.accommodationHotelMotel),
      PlaceCategory(PlaceCategory.accommodationLodging),
    ];

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
    final query =
        CategoryQuery.withCategoriesInArea(categories, categoryQueryArea);
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
        final List<Place> placesInsidePolygon = items!
            .where((place) =>
                place.geoCoordinates != null &&
                _isPointInPolygon(place.geoCoordinates!, vertices))
            .toList();

        print(
            "Found ${placesInsidePolygon.length} accommodations inside the polygon.");

        setState(() {
          _allAccomodations = placesInsidePolygon;
          _currentPage = 0;
          _updatePaginatedAccomodations();
          _isLoading = false;
        });
      }
    });
  }

  void _updatePaginatedAccomodations() {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage > _allAccomodations.length)
        ? _allAccomodations.length
        : startIndex + _itemsPerPage;

    setState(() {
      _paginatedAccomodations = _allAccomodations.sublist(startIndex, endIndex);
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

  Widget _buildBody() {
    if (_isLoading) {
      return Container(); // Show nothing while loading, as the overlay handles it
    }

    if (_allAccomodations.isEmpty) {
      return Center(
          child: Text(AppLocalizations.of(context)!.noAccommodationsFound));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _paginatedAccomodations.length,
      itemBuilder: (context, index) {
        return AccomodationCard(place: _paginatedAccomodations[index]);
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
    final totalPages = (_allAccomodations.length / _itemsPerPage).ceil();
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
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _currentPage == 0
                  ? null
                  : () {
                      setState(() {
                        _currentPage--;
                        _updatePaginatedAccomodations();
                      });
                    },
            ),
            Text(
              AppLocalizations.of(context)!.pageInfo(
                (_currentPage + 1).toString(),
                totalPages.toString(),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: _currentPage >= totalPages - 1
                  ? null
                  : () {
                      setState(() {
                        _currentPage++;
                        _updatePaginatedAccomodations();
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).colorScheme.onPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.accommodation,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
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
