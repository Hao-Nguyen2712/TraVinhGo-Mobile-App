import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/map_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// A widget to display an error message when the map fails to load.
class ErrorView extends StatelessWidget {
  final String message;
  const ErrorView({Key? key, required this.message}) : super(key: key);

  /// Shows debug information in case of errors
  void _showDebugInfo(BuildContext context, MapProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.debugInfo),
        content: SelectableText(
          "${AppLocalizations.of(context)!.errorPrefix(provider.errorMessage!)}\n\n"
          "${AppLocalizations.of(context)!.mapErrorInstructions}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.onErrorContainer,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onErrorContainer
                      .withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
