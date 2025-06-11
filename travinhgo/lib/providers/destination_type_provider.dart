import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/models/destination_types/destination_type.dart';

import '../services/destination_type_service.dart';

class DestinationTypeProvider extends ChangeNotifier {
  final List<DestinationType> _destinationTypes = [];

  List<DestinationType> get destinationTypes => _destinationTypes;

  Future<void> fetchDestinationType() async {
    try {
      List<DestinationType> destinationTypesFetch =
          await DestinationTypeService().getMarkers();
      _destinationTypes.clear();
      _destinationTypes.addAll(destinationTypesFetch);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch markers: $e');
    }
  }

  DestinationType getDestinationtypeById(String destinationTypeId) {
    return _destinationTypes.firstWhere(
      (dt) => dt.id == destinationTypeId,
      orElse: () => throw Exception(
          'DestinationType with id $destinationTypeId not found'),
    );
  }

  static DestinationTypeProvider of(BuildContext context,
      {bool listen = true}) {
    return Provider.of<DestinationTypeProvider>(context, listen: listen);
  }
}
