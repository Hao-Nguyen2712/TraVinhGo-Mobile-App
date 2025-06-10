import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/widgets.dart';
import 'package:travinhgo/models/destination/destination.dart';

import '../utils/constants.dart';

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
  
  final String _baseUrl =
      '${Base_api}TouristDestination/'; // Replace with your API base URL

  final Dio dio = Dio();

  Future<List<Destination>> getDestination() async {
    try {
      var endPoint = '${_baseUrl}GetAllDestinations';

      final response = await dio.get(endPoint,
          options: Options(headers: {
            'Content-Type': 'application/json charset=UTF-8',
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
}
