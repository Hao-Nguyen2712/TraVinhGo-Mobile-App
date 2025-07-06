import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';

import '../Models/Maps/top_favorite_destination.dart';
import '../Models/event_festival/event_and_festival.dart';
import '../Models/ocop/ocop_product.dart';
import '../utils/env_config.dart';

class HomeService {
  static final HomeService _instance = HomeService._internal();

  factory HomeService() {
    return _instance;
  }

  HomeService._internal() {
    dio.options.connectTimeout = const Duration(minutes: 3);

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  final String _baseUrl = '${EnvConfig.apiBaseUrl}/Home/';

  final Dio dio = Dio();

  Future<HomePageData?> getHomePageData() async {
    try {
      var endPoint = '${_baseUrl}GetDataHomePage';

      final response = await dio.get(endPoint,
          options: Options(headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          }));

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        debugPrint('data: ${data.toString()}');  // cách đơn giản
        return HomePageData.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error during get data home page list: $e');
      return null;
    }
  }
}

class HomePageData {
  final List<TopFavoriteDestination> favoriteDestinations;
  final List<EventAndFestival> topEvents;
  final List<OcopProduct> ocopProducts;

  HomePageData({
    required this.favoriteDestinations,
    required this.topEvents,
    required this.ocopProducts,
  });

  factory HomePageData.fromJson(Map<String, dynamic> json) {
    return HomePageData(
      favoriteDestinations: (json['favoriteDestinations'] as List<dynamic>)
          .map((e) => TopFavoriteDestination.fromJson(e))
          .toList(),
      topEvents: (json['topEvents'] as List<dynamic>)
          .map((e) => EventAndFestival.fromJson(e))
          .toList(),
      ocopProducts: (json['ocopProducts'] as List<dynamic>)
          .map((e) => OcopProduct.fromJson(e))
          .toList(),
    );
  }
}
