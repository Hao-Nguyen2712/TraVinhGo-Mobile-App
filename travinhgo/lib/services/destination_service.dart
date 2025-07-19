import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/widgets.dart';
import 'package:travinhgo/models/destination/destination.dart';

import '../utils/env_config.dart';

class DestinationService {
  static final DestinationService _instance = DestinationService._internal();

  factory DestinationService() {
    return _instance;
  }

  DestinationService._internal() {
    dio.options.connectTimeout = const Duration(minutes: 3);

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  final String _baseUrl = '${EnvConfig.apiBaseUrl}/TouristDestination/';

  final Dio dio = Dio();

  Future<List<Destination>> getDestination({
    int pageIndex = 1,
    int pageSize = 10,
    String? searchQuery,
    String? sortOrder,
    String? typeId,
  }) async {
    try {
      var endPoint = '${_baseUrl}GetTouristDestinationPaging';
      final params = {
        'PageIndex': pageIndex.toString(),
        'PageSize': pageSize.toString(),
        if (searchQuery != null && searchQuery.isNotEmpty)
          'Search': searchQuery,
        if (sortOrder != null) 'Sort': sortOrder,
        if (typeId != null) 'DestinationTypeId': typeId,
      };

      final response = await dio.get(endPoint,
          queryParameters: params,
          options: Options(headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          }));

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data']['data'];
        List<Destination> destinations =
            data.map((item) => Destination.fromJson(item)).toList();
        return destinations;
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error during get destination list: $e');
      return [];
    }
  }

  Future<Destination?> getDestinationById(String id) async {
    try {
      var endPoint = '${_baseUrl}GetDestinationById/${id}';

      final response = await dio.get(endPoint,
          options: Options(headers: {
            'Content-Type': 'application/json charset=UTF-8',
          }));

      if (response.statusCode == 200) {
        dynamic data = response.data['data'];
        Destination destinationDetail = Destination.fromJson(data);
        return destinationDetail;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error during get destination list: $e');
      return null;
    }
  }

  Future<List<Destination>> getDestinationsByIds(List<String> ids) async {
    try {
      var endPoint = '${_baseUrl}GetDestinationsByIds';

      final response = await dio.post(endPoint,
          data: ids,
          options: Options(headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          }));

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        List<Destination> destinations =
            data.map((item) => Destination.fromJson(item)).toList();
        return destinations;
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error during get destination list: $e');
      return [];
    }
  }

  Future<List<Destination>> getAllDestinations() async {
    final List<Destination> allDestinations = [];
    int pageIndex = 1;
    const int pageSize = 10;
    bool hasMore = true;

    while (hasMore) {
      try {
        final List<Destination> pageOfDestinations = await getDestination(
          pageIndex: pageIndex,
          pageSize: pageSize,
        );

        if (pageOfDestinations.isNotEmpty) {
          allDestinations.addAll(pageOfDestinations);
          pageIndex++;
        } else {
          hasMore = false;
        }
      } catch (e) {
        debugPrint('Error fetching page $pageIndex for all destinations: $e');
        hasMore = false; // Stop on error
      }
    }
    debugPrint(
        'Fetched a total of ${allDestinations.length} destinations for the map.');
    return allDestinations;
  }
}
