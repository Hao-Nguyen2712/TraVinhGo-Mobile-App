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

  final String _baseUrl = '${Base_api}LocalSpecialties/';

  final Dio dio = Dio();

  Future<List<LocalSpecialties>> getLocalSpecialtie() async {
    try {
      var endPoint = '${_baseUrl}active';

      final response = await dio.get(endPoint,
          options: Options(headers: {
            'Content-Type': 'application/json charset=UTF-8',
          }));

      if (response.statusCode == 200) {
        final List<dynamic>? data = response.data['data'];
        if (data == null) {
          return [];
        }
        List<LocalSpecialties> localSpecialties =
            data.map((item) => LocalSpecialties.fromJson(item)).toList();
        return localSpecialties;
      } else {
        throw Exception(
            'Failed to load local specialties. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error during get local specialties list: $e');
      rethrow;
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
        final dynamic data = response.data['data'];
        if (data == null) {
          return null;
        }
        LocalSpecialties localSpecialtie = LocalSpecialties.fromJson(data);
        return localSpecialtie;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error during get local specialtie : $e');
      rethrow;
    }
  }

  Future<List<LocalSpecialties>> getLocalSpecialtiesByIds(
      List<String> ids) async {
    try {
      var endPoint = '${_baseUrl}GetLocalSpecialtiByIds';

      final response = await dio.post(endPoint,
          data: ids,
          options: Options(headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          }));

      if (response.statusCode == 200) {
        final List<dynamic>? data = response.data['data'];
        if (data == null) {
          return [];
        }
        List<LocalSpecialties> localSpecialties =
            data.map((item) => LocalSpecialties.fromJson(item)).toList();
        return localSpecialties;
      } else {
        throw Exception(
            'Failed to load local specialties by ids. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error during get local specialties list: $e');
      rethrow;
    }
  }

  Future<List<LocalSpecialties>> getLocalSpecialtiesPaging({
    int pageNumber = 1,
    int pageSize = 10,
    String? searchQuery,
  }) async {
    try {
      var endPoint = '${_baseUrl}LocalSpecialities-Paging';

      final Map<String, dynamic> queryParameters = {
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      };
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParameters.addAll({'searchQuery': searchQuery});
      }

      final response = await dio.get(
        endPoint,
        queryParameters: queryParameters,
        options: Options(headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic>? data = response.data['data']['data'];
        if (data == null) {
          return [];
        }
        List<LocalSpecialties> localSpecialties =
            data.map((item) => LocalSpecialties.fromJson(item)).toList();
        return localSpecialties;
      } else {
        throw Exception(
            'Failed to load paged local specialties. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error during get paged local specialties: $e');
      rethrow;
    }
  }
}
