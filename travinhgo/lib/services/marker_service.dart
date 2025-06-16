import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';
import 'package:travinhgo/models/marker/marker.dart';

import '../utils/env_config.dart';

class MarkerService {
  static final MarkerService _instance = MarkerService._internal();

  factory MarkerService() {
    return _instance;
  }

  MarkerService._internal() {
    dio.options.connectTimeout = const Duration(minutes: 3);

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  final String _baseUrl = '${EnvConfig.apiBaseUrl}/Marker/';

  final Dio dio = Dio();

  Future<List<Marker>> getMarkers() async {
    try {
      var endPoint = '${_baseUrl}GetAllMarkers';

      final response = await dio.get(endPoint,
          options: Options(headers: {
            'Content-Type': 'application/json charset=UTF-8',
          }));

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        List<Marker> markers =
            data.map((item) => Marker.fromJson(item)).toList();
        return markers;
      } else {
        debugPrint('List is empty');
        return [];
      }
    } catch (e) {
      debugPrint('Error during get destination list: $e');
      return [];
    }
  }
}
