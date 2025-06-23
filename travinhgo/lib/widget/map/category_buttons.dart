import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/map_provider.dart';

/// Category filter buttons for map POIs
class CategoryButtons extends StatelessWidget {
  const CategoryButtons({Key? key}) : super(key: key);

  /// Called when a category filter is selected
  void _onCategorySelected(int index, bool selected, MapProvider provider) {
    if (selected) {
      provider.updateSelectedCategory(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, provider, _) {
        // Hide category buttons when in routing mode
        if (provider.isRoutingMode) {
          return SizedBox.shrink();
        }

        return Positioned(
          top: MediaQuery.of(context).padding.top + 70,
          left: 0,
          right: 0,
          height: 50,
          child: Stack(
            children: [
              ShaderMask(
                shaderCallback: (Rect rect) {
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withAlpha(20),
                      Colors.black.withAlpha(255),
                      Colors.black.withAlpha(255),
                      Colors.black.withAlpha(20)
                    ],
                    stops: [0.0, 0.05, 0.95, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  itemCount: provider.categories.length,
                  itemBuilder: (context, index) {
                    // A category is selected if it's the current index AND the category is active
                    bool isSelected = provider.selectedCategoryIndex == index &&
                        provider.isCategoryActive;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              _onCategorySelected(index, true, provider),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.green.withOpacity(0.8)
                                  : Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.green
                                    : Colors.white.withOpacity(0.8),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Category icon
                                Image.asset(
                                  provider.getCategoryIcon(index),
                                  width: 18,
                                  height: 18,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.category,
                                      size: 18,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                    );
                                  },
                                ),
                                SizedBox(width: 6),
                                // Category name
                                Text(
                                  provider.categories[index],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Show loading indicator when category search is in progress
              if (provider.isCategorySearching)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withAlpha(160),
                    child: Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
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
