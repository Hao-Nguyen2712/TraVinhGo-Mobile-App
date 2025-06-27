import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/map_provider.dart';

/// Error view displayed when map fails to load
class ErrorView extends StatelessWidget {
  const ErrorView({Key? key}) : super(key: key);

  /// Shows debug information in case of errors
  void _showDebugInfo(BuildContext context, MapProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Debug Info"),
        content: SelectableText(
          "Error: ${provider.errorMessage}\n\n"
          "Make sure:\n"
          "1. Your API key and secret are correctly registered\n"
          "2. Internet permissions are enabled in AndroidManifest.xml\n"
          "3. Your device has internet access\n"
          "4. HERE SDK is properly initialized",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MapProvider>(context, listen: false);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Failed to load map: ${provider.errorMessage}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              provider.errorMessage = null;
              provider.isLoading = true;
              // Simply notify listeners to trigger UI refresh
              provider.notifyListeners();
            },
            child: Text('Try Again'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => _showDebugInfo(context, provider),
            child: Text('Show Debug Info'),
          ),
        ],
      ),
    );
  }
}
