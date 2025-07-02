import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';
import 'package:travinhgo/Models/favorite/favorite.dart';

import '../utils/env_config.dart';
import 'auth_service.dart';

class FavoriteService {
  static final FavoriteService _instance = FavoriteService._internal();

  factory FavoriteService() {
    return _instance;
  }

  FavoriteService._internal() {
    dio.options.connectTimeout = const Duration(minutes: 3);

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  final String _baseUrl = '${EnvConfig.apiBaseUrl}/Users/';

  final Dio dio = Dio();

  Future<List<Favorite>> getFavorites() async {
    try {
      var endPoint = '${_baseUrl}GetFavoriteList';
      var sessionId = await AuthService().getSessionId();

      final response = await dio.get(
        endPoint,
        options: Options(
          headers: {
            'Content-Type': 'application/json charset=UTF-8',
            'sessionId': sessionId
          },
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        List<Favorite> favorites =
            data.map((item) => Favorite.fromJson(item)).toList();
        return favorites;
      } else {
        debugPrint('List is empty');
        return [];
      }
    } catch (e) {
      debugPrint('Error during get favorite list: $e');
      return [];
    }
  }

  Future<bool> addFavoriteList(Favorite favorite) async {
    try {
      var endPoint = '${_baseUrl}AddItemToFavoriteList';
      var sessionId = await AuthService().getSessionId();
      final response = await dio.post(
        endPoint,
        data: favorite.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'sessionId': sessionId
          },
        ),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Add failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error during add favorite to list: $e');
      return false;
    }
  }

  Future<bool> removeFavoriteList(String itemId) async {
    try {
      var endPoint = '${_baseUrl}RemoveItemToFavoriteList/${itemId}';
      var sessionId = await AuthService().getSessionId();
      final response = await dio.delete(
        endPoint,
        options: Options(
          headers: {'sessionId': sessionId},
        ),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Remove failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error during remove favorite to list: $e');
      return false;
    }
  }
}
