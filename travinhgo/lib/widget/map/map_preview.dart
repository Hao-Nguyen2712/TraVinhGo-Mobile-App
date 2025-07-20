import 'package:flutter/material.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';

class MapPreview extends StatelessWidget {
  final GeoCoordinates location;
  final VoidCallback? onTap;

  const MapPreview({
    super.key,
    required this.location,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: HereMap(
          onMapCreated: (HereMapController controller) async {
            final mapScheme =
                isDarkMode ? MapScheme.normalNight : MapScheme.normalDay;
            controller.mapScene.loadSceneForMapScheme(mapScheme, (error) async {
              if (error != null) {
                print('Map scene not loaded. Error: ${error.toString()}');
                return;
              }
              if (error == null) {
                final mapImage = await MapImage.withFilePathAndWidthAndHeight(
                    'assets/images/markers/marker.png', 70, 70);
                controller.camera.lookAtPoint(location);
                controller.mapScene.addMapMarker(MapMarker(location, mapImage));
              }
            });
          },
        ),
      ),
    );
  }
}
