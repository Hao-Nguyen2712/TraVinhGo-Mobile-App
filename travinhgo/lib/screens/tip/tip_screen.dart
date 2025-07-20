import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import '../../Models/tip/tip.dart';
import '../../providers/tag_provider.dart';
import '../../services/tip_service.dart';
import '../../utils/constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../utils/string_helper.dart';

class TipScreen extends StatefulWidget {
  const TipScreen({super.key});

  @override
  State<TipScreen> createState() => _TipScreenState();
}

class _TipScreenState extends State<TipScreen> {
  List<Tip> _tips = [];
  List<String> _nameTips = [];
  bool _isLoading = true;
  List<bool> _expandedList = [];

  String? _selectedTipTypeId;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTips();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchTips() async {
    final data = await TipService().getTips();

    setState(() {
      _tips = data;
      _nameTips = data.map((e) => e.title).toList();
      _expandedList = List.generate(data.length, (_) => false);
      _isLoading = false;
    });
  }

  List<Tip> get _filteredTips {
    return _tips.where((tip) {
      final matchesType =
          _selectedTipTypeId == null || tip.tagId == _selectedTipTypeId;

      final searchQuery = _searchController.text;
      final normalizedQuery =
          StringHelper.removeDiacritics(searchQuery.toLowerCase());
      final normalizedTitle =
          StringHelper.removeDiacritics(tip.title.toLowerCase());

      final matchesSearch =
          searchQuery.isEmpty || normalizedTitle.contains(normalizedQuery);

      return matchesType && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tagProvider = Provider.of<TagProvider>(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: theme.colorScheme.primary,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              title: Text(
                AppLocalizations.of(context)!.tipTravel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
          body: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.search,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(60),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor:
                          theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    ),
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _filteredTips.length,
                          itemBuilder: (context, index) {
                            final tip = _filteredTips[index];
                            final tag = tagProvider.getTagById(tip.tagId);
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      StringHelper.toTitleCase(tip.title),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: Image.network(
                                            tag.image,
                                            width: 20,
                                            height: 20,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          tag.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Html(
                                      data: tip.content,
                                      style: {
                                        "body": Style(
                                          maxLines:
                                              _expandedList[index] ? 1000 : 3,
                                          textOverflow: TextOverflow.ellipsis,
                                          fontSize: FontSize(15),
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _expandedList[index] =
                                                !_expandedList[index];
                                          });
                                        },
                                        icon: Text(
                                          _expandedList[index]
                                              ? AppLocalizations.of(context)!
                                                  .collapse
                                              : AppLocalizations.of(context)!
                                                  .seeMore,
                                          style: TextStyle(
                                              color: theme.colorScheme.primary),
                                        ),
                                        label: Icon(
                                          _expandedList[index]
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
