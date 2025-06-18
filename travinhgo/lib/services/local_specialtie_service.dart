import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';

import '../models/local_specialties/local_specialties.dart';
import '../utils/constants.dart';

class LocalSpecialtieService {
  static final LocalSpecialtieService _instance =
      LocalSpecialtieService._internal();

  factory LocalSpecialtieService() {
    return _instance;
  }

  LocalSpecialtieService._internal() {
    dio.options.connectTimeout = const Duration(minutes: 3);

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  final String _baseUrl =
      '${Base_api}LocalSpecialties/'; 

  final Dio dio = Dio();

  Future<List<LocalSpecialties>> getLocalSpecialtie() async {
    try {
      var endPoint = '${_baseUrl}all';

      final response = await dio.get(endPoint,
          options: Options(headers: {
            'Content-Type': 'application/json charset=UTF-8',
          }));

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        List<LocalSpecialties> localSpecialties =
            data.map((item) => LocalSpecialties.fromJson(item)).toList();
        return localSpecialties;
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error during get local specialties list: $e');
      return [];
    }
  }

  Future<LocalSpecialties?> getLocalSpecialtieById(String id) async {
    try {
      var endPoint = '${_baseUrl}${id}';

      final response = await dio.get(endPoint,
          options: Options(headers: {
            'Content-Type': 'application/json charset=UTF-8',
          }));

      if (response.statusCode == 200) {
        dynamic data = response.data['data'];
        LocalSpecialties localSpecialtie = LocalSpecialties.fromJson(data);
        return localSpecialtie;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error during get local specialtie : $e');
      return null;
    }
  }
}
