import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'favorite_tab/favorite_all_tab.dart';
import 'favorite_tab/favorite_destination_tab.dart';
import 'favorite_tab/favorite_local_tab.dart';
import 'favorite_tab/favorite_ocop_tab.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  int _selectedTab = 0;

  final List<String> _tabs = ["All", "Destination", "Ocop", "Local"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kbackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: Colors.white,
              automaticallyImplyLeading: false,
              title: const Text(
                'Favorite',
                style: TextStyle(
                  color: Color(0xFF219653),
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
            ),
            // Tabbar
            SliverToBoxAdapter(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                child: Row(
                  children: List.generate(
                    _tabs.length,
                        (index) => Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: _buildTab(index),
                    ),
                  ),
                ),
              ),
            ),
            // Nội dung thay đổi theo tab
            SliverFillRemaining(
              hasScrollBody: true,
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index) {
    final bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[700] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.green.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Text(
          _tabs[index],
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 15,
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