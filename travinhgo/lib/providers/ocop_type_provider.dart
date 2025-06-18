import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/models/ocop/ocop_type.dart';
import 'package:travinhgo/services/ocop_type_service.dart';

class OcopTypeProvider extends ChangeNotifier {
  final List<OcopType> _ocopTypes = [];

  List<OcopType> get ocopTypes => _ocopTypes;

  Future<void> fetchOcopType() async {
    try {
      List<OcopType> ocopTypesFetch = await OcopTypeService().getOcopTypes();
      _ocopTypes.clear();
      _ocopTypes.addAll(ocopTypesFetch);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch ocop type: $e');
    }
  }

  OcopType getOcopTypeById(String ocopTypeId) {
    return _ocopTypes.firstWhere(
      (ot) => ot.id == ocopTypeId,
      orElse: () =>
          throw Exception('DestinationType with id $ocopTypeId not found'),
    );
  }

  static OcopTypeProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<OcopTypeProvider>(context, listen: listen);
  }
}
