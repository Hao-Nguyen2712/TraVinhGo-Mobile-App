import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';

import '../models/destination_types/destination_type.dart';
import '../utils/constants.dart';

class DestinationTypeService {
  static final DestinationTypeService _instance =
      DestinationTypeService._internal();

  factory DestinationTypeService() {
    return _instance;
  }

  DestinationTypeService._internal() {
    dio.options.connectTimeout = const Duration(minutes: 3);

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  final String _baseUrl =
      '${Base_api}DestinationType/';

  final Dio dio = Dio();

  Future<List<DestinationType>> getMarkers() async {
    try {
      var endPoint = '${_baseUrl}GetAllDestinationTypes';

      final response = await dio.get(endPoint,
          options: Options(headers: {
            'Content-Type': 'application/json charset=UTF-8',
          }));

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        List<DestinationType> destinationTypes =
            data.map((item) => DestinationType.fromJson(item)).toList();
        return destinationTypes;
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
