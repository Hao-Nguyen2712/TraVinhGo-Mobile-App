import 'package:flutter/material.dart';
import 'package:travinhgo/models/local_specialties/local_specialties.dart';
import 'package:travinhgo/services/local_specialtie_service.dart';

enum LocalSpecialtyState { initial, loading, loaded, error }

class LocalSpecialtyProvider with ChangeNotifier {
  final LocalSpecialtieService _localSpecialtieService =
      LocalSpecialtieService();

  LocalSpecialtyState _state = LocalSpecialtyState.initial;
  List<LocalSpecialties> _localSpecialties = [];
  String _errorMessage = '';

  LocalSpecialtyState get state => _state;
  List<LocalSpecialties> get localSpecialties => _localSpecialties;
  String get errorMessage => _errorMessage;

  Future<void> fetchLocalSpecialties() async {
    _state = LocalSpecialtyState.loading;
    notifyListeners();

    try {
      _localSpecialties = await _localSpecialtieService.getLocalSpecialtie();
      _state = LocalSpecialtyState.loaded;
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.';
      _state = LocalSpecialtyState.error;
    }
    notifyListeners();
  }
}
