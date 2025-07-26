import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:travinhgo/models/ocop/ocop_product.dart';
import 'package:travinhgo/services/ocop_product_service.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../providers/ocop_product_provider.dart';
import '../../services/auth_service.dart';
import '../../widget/ocop_product_widget/ocop_product_item.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OcopProductScreen extends StatefulWidget {
  const OcopProductScreen({super.key});

  @override
  State<OcopProductScreen> createState() => _OcopProductScreenState();
}

class _OcopProductScreenState extends State<OcopProductScreen> {
  List<String> _ocopProductNames = [];
  String _searchQuery = '';
  late bool isAuthen;

  @override
  void initState() {
    super.initState();
    isAuthentication();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OcopProductProvider>(context, listen: false)
          .fetchOcopProducts();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ocopProducts = Provider.of<OcopProductProvider>(context).ocopProducts;
    _ocopProductNames = ocopProducts.map((e) => e.productName).toList();
  }

  Future<void> isAuthentication() async {
    var sessionId =  await AuthService().getSessionId();
    isAuthen = sessionId != null;
  }

  List<OcopProduct> _filteredOcopProducts(List<OcopProduct> products) {
    return products.where((event) {
      final matchesSearch = _searchQuery.isEmpty ||
          event.productName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ocopProvider = Provider.of<OcopProductProvider>(context);
    final ocopProducts = ocopProvider.ocopProducts;
    final isLoading = ocopProvider.isLoading;
    final error = ocopProvider.errorMessage;
    final filteredProducts = _filteredOcopProducts(ocopProducts);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      body: SafeArea(
          child: CustomScrollView(slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          title: Text(AppLocalizations.of(context)!.ocopProduct),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty)
                    return const Iterable<String>.empty();
                  return _ocopProductNames.where((name) => name
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String selection) {
                  setState(() {
                    _searchQuery = selection;
                  });
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onSubmitted: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchOcopProduct,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(60),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 90.w,
                        constraints: BoxConstraints(maxHeight: 25.h),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final option = options.elementAt(index);
                            return InkWell(
                              onTap: () {
                                onSelected(option);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 12.0),
                                child: Text(
                                  option,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              )),
        ),
        if (isLoading)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(),
              ),
            ),
          )
        else if (error != null)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(AppLocalizations.of(context)!.errorPrefix(error)),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 3 : 2,
                  crossAxisSpacing: 5.w,
                  mainAxisSpacing: 2.h,
                  childAspectRatio: isTablet ? 0.75 : 0.64),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return OcopProductItem(ocopProduct: filteredProducts[index], isAllowFavorite: isAuthen,);
                },
                childCount: filteredProducts.length,
              ),
            ),
          ),
      ])),
    );
  }
}
