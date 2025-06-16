import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';
import 'package:travinhgo/models/Tag/Tag.dart';

import '../utils/env_config.dart';

class TagService {
  static final TagService _instance = TagService._internal();

  factory TagService() {
    return _instance;
  }

  TagService._internal() {
    dio.options.connectTimeout = const Duration(minutes: 3);

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  final String _baseUrl = '${EnvConfig.apiBaseUrl}/Tags/';

  final Dio dio = Dio();

  Future<List<Tag>> getTags() async {
    try {
      var endPoint = '${_baseUrl}all';

      final response = await dio.get(endPoint,
          options: Options(headers: {
            'Content-Type': 'application/json charset=UTF-8',
          }));

      if (response.statusCode == 200) {
        List<dynamic> data = response.data as List;
        List<Tag> tags = data.map((item) => Tag.fromJson(item)).toList();
        return tags;
      } else {
        debugPrint('List is empty');
        return [];
      }
    } catch (e) {
      debugPrint('Error during get tag list: $e');
      return [];
    }
  }
}
