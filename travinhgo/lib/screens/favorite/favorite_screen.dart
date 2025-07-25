import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:travinhgo/providers/favorite_provider.dart';
import 'favorite_tab/favorite_all_tab.dart';
import 'favorite_tab/favorite_destination_tab.dart';
import 'favorite_tab/favorite_local_tab.dart';
import 'favorite_tab/favorite_ocop_tab.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  int _selectedTab = 0;

  late final List<String> _tabs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    _tabs = [l10n.all, l10n.destination, l10n.ocop, l10n.local];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final destinationCount = favoriteProvider.destinationList.length;
    final ocopCount = favoriteProvider.ocopProductList.length;
    final localCount = favoriteProvider.localSpecialteList.length;
    final allCount = destinationCount + ocopCount + localCount;

    final counts = [allCount, destinationCount, ocopCount, localCount];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        top: false,
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: colorScheme.primary,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                AppLocalizations.of(context)!.favoriteTitle,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
              ),
              centerTitle: true,
            ),
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 2.w),
                color: colorScheme.primary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    _tabs.length,
                    (index) => _buildTab(index, counts[index]),
                  ),
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: true,
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, int count) {
    final bool isSelected = _selectedTab == index;
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 1.w),
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12.sp),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _tabs[index],
                style: TextStyle(
                  color: isSelected ? primaryColor : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return FavoriteAllTab();
      case 1:
        return FavoriteDestinationTab();
      case 2:
        return FavoriteOcopTab();
      case 3:
        return FavoriteLocalTab();
      default:
        return FavoriteAllTab();
    }
  }
}
