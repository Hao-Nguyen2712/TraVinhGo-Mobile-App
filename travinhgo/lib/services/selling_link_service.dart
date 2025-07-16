import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';

import '../Models/selling_link/selling_link.dart';
import '../utils/env_config.dart';

class SellingLinkService {
  static final SellingLinkService _instance = SellingLinkService._internal();

  factory SellingLinkService() {
    return _instance;
  }

  SellingLinkService._internal() {
    dio.options.connectTimeout = const Duration(minutes: 3);

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  final String _baseUrl = '${EnvConfig.apiBaseUrl}/SellingLink/';

  final Dio dio = Dio();

  Future<List<SellingLink>> getSellingLinkByOcopId(String id) async {
    try {
      var endPoint = '${_baseUrl}GetSellingLinkByProductId/$id';
      final response = await dio.get(
        endPoint,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        List<SellingLink> sellingLinks = data.map((item) => SellingLink.fromJson(item)).toList();
        return sellingLinks;
      }
      return [];
    } catch (e) {
      debugPrint('Error during get selling link list: $e');
      return [];
    }
  }
}