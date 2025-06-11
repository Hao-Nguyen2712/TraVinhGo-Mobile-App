import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          _navigateToNextScreen();
        }
      });
    });
  }

  void _navigateToNextScreen() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kprimaryColor,
      body: Center(
        child: DefaultTextStyle(
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Aclonica',
          ),
          child: AnimatedTextKit(
            animatedTexts: [
              TyperAnimatedText(
                'TraVinhGo',
                speed: Duration(microseconds: 200),
              ),
            ],
            totalRepeatCount: 1,
            pause: Duration(milliseconds: 500),
          ),
        ),
      ),
    );
  }

  Future<void> _loadData() async {
    final markerProvider = Provider.of<MarkerProvider>(context, listen: false);
    final destinationTypeProvider =
        Provider.of<DestinationTypeProvider>(context, listen: false);
    final tagProvider = Provider.of<TagProvider>(context, listen: false);

    // fetch data
    await markerProvider.fetchMarkers();
    await destinationTypeProvider.fetchDestinationType();
    await tagProvider.fetchDestinationType();

    // Handle
    final markers = markerProvider.markers;
    for (var destinationType in destinationTypeProvider.destinationTypes) {
      final matchedMarker = markers.firstWhere(
        (m) => m.id == destinationType.markerId,
        orElse: () => Marker(id: '', name: 'Unknown', image: ''),
      );
      destinationType.marker = matchedMarker.id.isEmpty ? null : matchedMarker;
    }

    // Preload marker images
    final futures = <Future>[];
    for (final marker in markers) {
      if (marker.image.isNotEmpty) {
        futures.add(precacheImage(NetworkImage(marker.image), context));
      }
    }
    await Future.wait(futures);

    // Sau khi load xong, đợi thêm 1 giây để splash được nhìn thấy rõ hơn
    await Future.delayed(const Duration(seconds: 1));

    // Chuyển sang màn hình chính
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const BottomNavBar()),
    );
  }
}
