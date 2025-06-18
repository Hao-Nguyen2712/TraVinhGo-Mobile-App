import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';

import '../models/ocop/ocop_type.dart';
import '../utils/env_config.dart';

class OcopTypeService {
  static final OcopTypeService _instance = OcopTypeService._internal();

  factory OcopTypeService() {
    return _instance;
  }

  OcopTypeService._internal() {
    dio.options.connectTimeout = const Duration(minutes: 3);

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  final String _baseUrl = '${EnvConfig.apiBaseUrl}/OcopType/';

  final Dio dio = Dio();

  Future<List<OcopType>> getOcopTypes() async {
    try {
      var endPoint = '${_baseUrl}GetAllOcopType';

      final response = await dio.get(endPoint,
          options: Options(headers: {
            'Content-Type': 'application/json charset=UTF-8',
          }));

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        List<OcopType> ocopTypes =
        data.map((item) => OcopType.fromJson(item)).toList();
        return ocopTypes;
      } else {
        debugPrint('List is empty');
        return [];
      }
    } catch (e) {
      debugPrint('Error during get ocop type list: $e');
      return [];
    }
  }
}
