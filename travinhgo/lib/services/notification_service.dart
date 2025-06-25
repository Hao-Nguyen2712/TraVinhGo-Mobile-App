import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';

import '../Models/notification/notification.dart';
import '../utils/env_config.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal() {
    dio.options.connectTimeout = const Duration(minutes: 3);

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  final String _baseUrl = '${EnvConfig.apiBaseUrl}/Notifications/';

  final Dio dio = Dio();

  Future<List<UserNotification>> getNotifications() async {
    try {
      var endPoint = '${_baseUrl}recent';

      final response = await dio.get(endPoint,
          options: Options(headers: {
            'Content-Type': 'application/json charset=UTF-8',
          }));

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        List<UserNotification> notifications =
        data.map((item) => UserNotification.fromJson(item)).toList();
        return notifications;
      } else {
        debugPrint('List is empty');
        return [];
      }
    } catch (e) {
      debugPrint('Error during get notification list: $e');
      return [];
    }
  }
}