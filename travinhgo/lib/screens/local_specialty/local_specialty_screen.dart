import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/models/local_specialties/local_specialties.dart';
import 'package:travinhgo/providers/local_specialty_provider.dart';
import 'package:travinhgo/widget/local_specialty_widget/local_specialty_item.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/string_helper.dart';

class LocalSpecialtyScreen extends StatefulWidget {
  const LocalSpecialtyScreen({super.key});

  @override
  State<LocalSpecialtyScreen> createState() => _LocalSpecialtyScreenState();
}

class _LocalSpecialtyScreenState extends State<LocalSpecialtyScreen> {
  String _searchQuery = '';
  late bool isAuthen;

  @override
  void initState() {
    super.initState();
    isAuthentication();
    // Fetch initial data using the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocalSpecialtyProvider>(context, listen: false)
          .fetchLocalSpecialties();
    });
  }

  Future<void> isAuthentication() async {
    var sessionId =  await AuthService().getSessionId();
    isAuthen = sessionId != null;
  }

  @override
  Widget build(BuildContext context) {
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
        body: SafeArea(
          top: false, // We handle the top padding with the AppBar
          child: Consumer<LocalSpecialtyProvider>(
            builder: (context, provider, child) {
              final filteredLocals = provider.localSpecialties.where((local) {
                final normalizedQuery =
                    StringHelper.removeDiacritics(_searchQuery.toLowerCase());
                final normalizedFoodName =
                    StringHelper.removeDiacritics(local.foodName.toLowerCase());

                return _searchQuery.isEmpty ||
                    normalizedFoodName.contains(normalizedQuery);
              }).toList();

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    title: Text(AppLocalizations.of(context)!.localSpecialty),
                    centerTitle: true,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.search,
                          prefixIcon: Icon(Icons.search,
                              color: theme.colorScheme.onSurface),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(60),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: kSearchBackgroundColor,
                        ),
                      ),
                    ),
                  ),
                  _buildBody(provider.state, filteredLocals, provider),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(LocalSpecialtyState state,
      List<LocalSpecialties> filteredLocals, LocalSpecialtyProvider provider) {
    switch (state) {
      case LocalSpecialtyState.loading:
      case LocalSpecialtyState.initial:
        return const SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            ),
          ),
        );
      case LocalSpecialtyState.error:
        return SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.errorMessage,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchLocalSpecialties(),
                    child: const Text("Thử lại"),
                  )
                ],
              ),
            ),
          ),
        );
      case LocalSpecialtyState.loaded:
        return filteredLocals.isEmpty
            ? SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                        AppLocalizations.of(context)!.noLocalSpecialtyFound),
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1 / 1.4,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return LocalSpecialtyItem(
                          localSpecialty: filteredLocals[index], isAllowFavorite: isAuthen,);
                    },
                    childCount: filteredLocals.length,
                  ),
                ),
              );
    }
  }
}
