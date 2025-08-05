import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../models/ocop/ocop_product.dart';
import '../../providers/ocop_product_provider.dart';
import '../../services/auth_service.dart';
import '../../widget/ocop_product_widget/ocop_product_item.dart';

class OcopProductScreen extends StatefulWidget {
  const OcopProductScreen({super.key});

  @override
  State<OcopProductScreen> createState() => _OcopProductScreenState();
}

class _OcopProductScreenState extends State<OcopProductScreen> {
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
      final provider = Provider.of<OcopProductProvider>(context, listen: false);
      provider.loadInitialOcopProducts();
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
    final provider = Provider.of<OcopProductProvider>(context, listen: false);
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !provider.isLoadingMore &&
        provider.hasMore) {
      provider.fetchOcopProducts();
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
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final provider = Provider.of<OcopProductProvider>(context, listen: false);
      provider.applySearchQuery(query);
      provider.fetchOcopProducts(isRefresh: true);
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
                  child: Consumer<OcopProductProvider>(
                    builder: (context, ocopProvider, child) {
                      return RefreshIndicator(
                        onRefresh: () =>
                            ocopProvider.fetchOcopProducts(isRefresh: true),
                        child: CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            SliverToBoxAdapter(
                              child: _buildSearchBar(context),
                            ),
                            if (ocopProvider.isLoading &&
                                ocopProvider.ocopProducts.isEmpty)
                              const SliverToBoxAdapter(
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 32),
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              )
                            else if (ocopProvider.errorMessage != null)
                              SliverToBoxAdapter(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 32),
                                    child: Text(AppLocalizations.of(context)!
                                        .errorPrefix(
                                            ocopProvider.errorMessage!)),
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
                                              isTablet ? 0.75 : 0.64),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      return OcopProductItem(
                                        ocopProduct:
                                            ocopProvider.ocopProducts[index],
                                        isAllowFavorite: isAuthen,
                                      );
                                    },
                                    childCount:
                                        ocopProvider.ocopProducts.length,
                                  ),
                                ),
                              ),
                            if (ocopProvider.isLoadingMore)
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
              AppLocalizations.of(context)!.ocopProduct,
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
          hintText: AppLocalizations.of(context)!.searchOcopProduct,
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
