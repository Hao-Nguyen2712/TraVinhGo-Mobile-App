import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/models/marker/marker.dart';

import '../services/marker_service.dart';

class MarkerProvider extends ChangeNotifier {
  final List<Marker> _markers = [];

  List<Marker> get markers => _markers;

  Future<void> fetchMarkers() async {
    try {
      List<Marker> markersFetch = await MarkerService().getMarkers();
      _markers.clear();
      _markers.addAll(markersFetch);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch markers: $e');
    }
  }

  static MarkerProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<MarkerProvider>(context, listen: listen);
  }
}
