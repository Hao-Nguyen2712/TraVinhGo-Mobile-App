import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../Models/interaction/interaction_log.dart';
import '../Models/interaction/item_type.dart';
import '../services/interaction_log_service.dart';

class InteractionLogProvider {
  List<InteractionLogRequest> _interactionLogRequests = [];
  Timer? _timer;

  InteractionLogProvider() {
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      sendAllInteracLog();
    });
  }

  Future<void> _saveLogsToLocal() async {
    var box = await Hive.openBox('interaction_log_requests');
    await box.put('logs', _interactionLogRequests.map((e) => e.toJson()).toList());
  }

  Future<void> addInteracLog(String itemId,ItemType itemType, int duration) async {
    InteractionLogRequest interactionLogData = InteractionLogRequest(itemId: itemId, itemType:itemType.toShortString(), duration: duration);
    _interactionLogRequests.add(interactionLogData);
    await _saveLogsToLocal();
  }

  Future<void> sendAllInteracLog() async {
    if (_interactionLogRequests.isEmpty) return;
    try {
      final ok = await InteractionLogService().sendInteractionLog(_interactionLogRequests);
      if (ok) {
        _interactionLogRequests.clear();
        var box = await Hive.openBox('interaction_log_requests');
        await box.delete('logs');
      }
    } catch (e) {
      debugPrint('Error during sending interaction log in provider: $e');
    }
  }

  void dispose() {
    _timer?.cancel();
  }

  Future<void> _restoreLogsFromLocal() async {
    var box = await Hive.openBox('interaction_log_requests');
    List? logs = box.get('logs');
    if (logs != null) {
      _interactionLogRequests = logs.map((e) => InteractionLogRequest.fromJson(e)).toList();
    }
  }

  Future<void> restoreLogsFromLocal() => _restoreLogsFromLocal();

  static InteractionLogProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<InteractionLogProvider>(context, listen: listen);
  }
  
}
