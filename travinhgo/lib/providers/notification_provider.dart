
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../Models/notification/notification.dart';

class NotificationProvider extends ChangeNotifier {
  List<UserNotification> _userNotification = [];
  List<UserNotification> get userNotification => _userNotification;
  
  void increaseNotification(UserNotification item) {
    _userNotification.add(item);
    notifyListeners();
  }

  void resetNotification() {
    _userNotification.clear();
    notifyListeners();
  }

  static NotificationProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<NotificationProvider>(context, listen: listen);
  }
}