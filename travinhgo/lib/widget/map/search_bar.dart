import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:here_sdk/search.dart' show Suggestion;

import '../../providers/map_provider.dart';
import 'map_ui_utils.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Search bar widget with suggestions dropdown
class SearchBar extends StatefulWidget {
  const SearchBar({Key? key}) : super(key: key);

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String? _lastSearchTerm;
  int _lastSearchTimestamp = 0;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Handles search input changes with smart debounce for Vietnamese typing experience
  void _onSearchChanged(String text, MapProvider provider) {
    // Cancel any previous timer
    _debounceTimer?.cancel();

    if (text.isEmpty) {
      provider.clearSearchResults();
      _lastSearchTerm = null;
      return;
    }

    // Skip if text too short
    if (text.length < 2) return;

    // Simple debounce approach - let IME handle composition naturally
    final debounceDuration = MapUiUtils.getDebounceDuration(text);

    _debounceTimer = Timer(debounceDuration, () {
      _performSearch(text, provider);
    });
  }

  /// Perform search with duplicate prevention and performance tracking
  void _performSearch(String searchTerm, MapProvider provider) {
    final trimmedTerm = searchTerm.trim();

    // Avoid duplicate searches
    if (_lastSearchTerm == trimmedTerm) {
      return;
    }

    // Performance tracking
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeSinceLastSearch =
        _lastSearchTimestamp > 0 ? now - _lastSearchTimestamp : 0;
    _lastSearchTimestamp = now;

    _lastSearchTerm = trimmedTerm;

    provider.searchLocations(trimmedTerm);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<MapProvider>(
      builder: (context, provider, _) {
        // Don't show the search bar when in routing mode
        if (provider.isRoutingMode) {
          return SizedBox.shrink();
        }

        // Access search suggestions
        final suggestions = provider.searchSuggestions;

        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search input field
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withAlpha(242), // 0.95 opacity
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withAlpha(38), // 0.15 opacity
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,

                  // Vietnamese text optimization
                  autocorrect: true,
                  enableSuggestions: true,
                  enableInteractiveSelection: true,

                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.searchHere,
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colorScheme.primary.withAlpha(230),
                      size: 24,
                    ),
                    suffixIcon: provider.isSearching
                        ? Container(
                            width: 24,
                            height: 24,
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(
                            icon: Icon(Icons.clear,
                                color: colorScheme.onSurfaceVariant),
                            onPressed: () {
                              _searchController.clear();
                              provider.clearSearchResults();
                            },
                          ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  onChanged: (text) => _onSearchChanged(text, provider),
                ),
              ),

              // Search results dropdown with higher z-index
              if (suggestions.isNotEmpty)
                Material(
                  elevation: 12, // Higher elevation for better shadow
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    margin: EdgeInsets.only(top: 4),
                    constraints: BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        itemCount: suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = suggestions[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(Icons.location_on_outlined,
                                color: colorScheme.onSurface),
                            title: Text(
                              suggestion.title ??
                                  AppLocalizations.of(context)!.unnamedLocation,
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () {
                              provider.selectSearchSuggestion(suggestion);
                              _searchController.text = suggestion.title ?? "";
                              FocusScope.of(context).unfocus(); // Hide keyboard
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
