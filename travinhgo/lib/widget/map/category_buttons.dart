import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/map_provider.dart';
import '../../utils/constants.dart';

/// Widget for displaying category filter buttons on the map
class CategoryButtons extends StatelessWidget {
  const CategoryButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, provider, child) {
        // Get selected category index and category list
        final selectedIndex = provider.selectedCategoryIndex;
        final categoryList = provider.categories;

        // Calculate required space for system status bar
        final statusBarHeight = MediaQuery.of(context).padding.top;

        return Positioned(
          top: statusBarHeight + 56,
          left: 0,
          right: 0,
          child: Container(
            height: 44,
            margin: const EdgeInsets.only(top: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categoryList.length,
              itemBuilder: (context, index) {
                final isSelected =
                    selectedIndex == index && provider.isCategoryActive;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      categoryList[index],
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    selectedColor: kprimaryColor,
                    checkmarkColor: Colors.white,
                    selected: isSelected,
                    showCheckmark: false,
                    avatar: Image.asset(
                      provider.getCategoryIconForState(index, isSelected),
                      width: 20,
                      height: 20,
                      color: isSelected && provider.isCategoryTintable(index)
                          ? Colors.white
                          : null,
                    ),
                    onSelected: (selected) {
                      provider.updateSelectedCategory(index);
                    },
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.grey.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
