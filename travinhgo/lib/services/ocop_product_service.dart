import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';

import '../models/ocop/ocop_product.dart';
import '../utils/constants.dart';

class OcopProductService {
  static final OcopProductService _instance = OcopProductService._internal();

  factory OcopProductService() {
    return _instance;
  }

  OcopProductService._internal() {
    dio.options.connectTimeout = const Duration(minutes: 3);

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  final String _baseUrl = '${Base_api}OcopProduct/';

  final Dio dio = Dio();

  Future<List<OcopProduct>> getDestination() async {
    try {
      var endPoint = '${_baseUrl}GetAllDestinations';

      final response = await dio.get(endPoint,
          options: Options(headers: {
            'Content-Type': 'application/json charset=UTF-8',
          }));

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        List<OcopProduct> destinations =
            data.map((item) => OcopProduct.fromJson(item)).toList();
        return destinations;
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error during get destination list: $e');
      return [];
    }
  }
}
