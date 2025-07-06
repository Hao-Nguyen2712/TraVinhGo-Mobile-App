import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/map_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Error view displayed when map fails to load
class ErrorView extends StatelessWidget {
  const ErrorView({Key? key}) : super(key: key);

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
    final provider = Provider.of(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.mapLoadFailed(provider.errorMessage ?? 'Unknown error'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              provider.errorMessage = null;
              provider.isLoading = true;
              // Simply notify listeners to trigger UI refresh
              provider.notifyListeners();
            },
            child: Text(l10n.tryAgain),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => _showDebugInfo(context, provider),
            child: Text(l10n.showDebugInfo),
          ),
        ],
      ),
    );
  }
}
