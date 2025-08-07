import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:travinhgo/models/local_specialties/local_specialties.dart';
import 'package:travinhgo/providers/local_specialty_provider.dart';
import 'package:travinhgo/widget/local_specialty_widget/local_specialty_item.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../services/auth_service.dart';

class LocalSpecialtyScreen extends StatefulWidget {
  const LocalSpecialtyScreen({super.key});

  @override
  State<LocalSpecialtyScreen> createState() => _LocalSpecialtyScreenState();
}

class _LocalSpecialtyScreenState extends State<LocalSpecialtyScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool isAuthen = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    isAuthentication();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<LocalSpecialtyProvider>(context, listen: false);
      provider.fetchLocalSpecialties(isRefresh: true);
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider =
        Provider.of<LocalSpecialtyProvider>(context, listen: false);
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !provider.isLoadingMore &&
        provider.hasMore) {
      provider.fetchLocalSpecialties();
    }
  }

  Future<void> isAuthentication() async {
    var sessionId = await AuthService().getSessionId();
    if (mounted) {
      setState(() {
        isAuthen = sessionId != null;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      final provider =
          Provider.of<LocalSpecialtyProvider>(context, listen: false);
      provider.applySearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: theme.brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      body: Container(
        color: colorScheme.primary,
        child: Column(
          children: [
            SizedBox(height: statusBarHeight),
            _buildHeader(context),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  bottom: true,
                  child: Consumer<LocalSpecialtyProvider>(
                    builder: (context, provider, child) {
                      return RefreshIndicator(
                        onRefresh: () =>
                            provider.fetchLocalSpecialties(isRefresh: true),
                        child: CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            SliverToBoxAdapter(
                              child: _buildSearchBar(context),
                            ),
                            if (provider.isLoading &&
                                provider.localSpecialties.isEmpty)
                              const SliverToBoxAdapter(
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 32),
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              )
                            else if (provider.errorMessage != null)
                              SliverToBoxAdapter(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 32),
                                    child: Text(AppLocalizations.of(context)!
                                        .errorPrefix(provider.errorMessage!)),
                                  ),
                                ),
                              )
                            else if (provider.localSpecialties.isEmpty)
                              SliverToBoxAdapter(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 32),
                                    child: Text(AppLocalizations.of(context)!
                                        .noLocalSpecialtyFound),
                                  ),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 4.w, vertical: 2.h),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: isTablet ? 3 : 2,
                                          crossAxisSpacing: 5.w,
                                          mainAxisSpacing: 2.h,
                                          childAspectRatio:
                                              isTablet ? 0.7 : 0.6),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      return LocalSpecialtyItem(
                                        localSpecialty:
                                            provider.localSpecialties[index],
                                        isAllowFavorite: isAuthen,
                                      );
                                    },
                                    childCount:
                                        provider.localSpecialties.length,
                                  ),
                                ),
                              ),
                            if (provider.isLoadingMore)
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).colorScheme.onPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.localSpecialty,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48), // To balance the IconButton
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.search,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(60),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: colorScheme.surfaceVariant.withOpacity(0.7),
        ),
      ),
    );
  }
}
