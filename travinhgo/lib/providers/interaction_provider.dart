import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../Models/interaction/interaction.dart';
import '../Models/interaction/item_type.dart';
import '../services/interaction_service.dart';

class InteractionProvider {
  List<InteractionRequest> _interactionRequests = [];
  Timer? _timer;

  InteractionProvider() {
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      sendAllLogs();
    });
  }

  Future<void> _saveLogsToLocal() async {
    var box = await Hive.openBox('interaction_requests');
    await box.put('logs', _interactionRequests.map((e) => e.toJson()).toList());
  }

  Future<void> addInterac(String itemId, ItemType itemType) async {
    final index = _interactionRequests.indexWhere(
          (e) => e.itemId == itemId && e.itemType == itemType.toShortString(),
    );
    if (index != -1) {
      _interactionRequests[index].totalCount += 1;
    } else {
      final interactionLogRequest = InteractionRequest(
        itemId: itemId,
        itemType: itemType.toShortString(),
      );
      _interactionRequests.add(interactionLogRequest);
    }
    await _saveLogsToLocal();
  }

  Future<void> sendAllLogs() async {
    if (_interactionRequests.isEmpty) return;
    try {
      final ok = await InteractionService().sendInteraction(_interactionRequests);
      if (ok) {
        _interactionRequests.clear(); // Xóa log nếu gửi thành công
        var box = await Hive.openBox('interaction_requests');
        await box.delete('logs');
      }
    } catch (e) {
      debugPrint('Error during sending interaction in provider: $e');
    }
  }

  void dispose() {
    _timer?.cancel();
  }

  Future<void> _restoreLogsFromLocal() async {
    var box = await Hive.openBox('interaction_requests');
    List? logs = box.get('logs');
    if (logs != null) {
      _interactionRequests = logs.map((e) => InteractionRequest.fromJson(e)).toList();
    }
  }

  Future<void> restoreLogsFromLocal() => _restoreLogsFromLocal();

  static InteractionProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<InteractionProvider>(context, listen: listen);
  }
}
