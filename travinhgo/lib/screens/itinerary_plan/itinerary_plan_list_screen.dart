import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../Models/itinerary_plan/itinerary_plan.dart';
import '../../services/itinerary_plan_service.dart';

const Color _systemGreen = Color(0xFF158247);

class ItineraryPlanListScreen extends StatefulWidget {
  const ItineraryPlanListScreen({super.key});

  @override
  State<ItineraryPlanListScreen> createState() =>
      _ItineraryPlanListScreenState();
}

class _ItineraryPlanListScreenState extends State<ItineraryPlanListScreen> {
  List<ItineraryPlan> _allItineraryPlans = [];
  List<ItineraryPlan> _filteredItineraryPlans = [];
  bool _isLoading = true;
  bool _isGridView = false;
  int _selectedFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchItineraryPlan();
  }

  Future<void> fetchItineraryPlan() async {
    final data =
        (await ItineraryPlanService().getItineraryPlan()).reversed.toList();

    if (mounted) {
      setState(() {
        _allItineraryPlans = data;
        _filteredItineraryPlans = data;
        _isLoading = false;
      });
    }
  }

  void _filterItineraryPlans(int filterIndex) {
    List<ItineraryPlan> filtered;
    const shortStayDurations = {
      "1 days",
      "2 days 1 night",
      "3 days 2 night",
      "One day"
    };

    switch (filterIndex) {
      case 1: // Ngắn ngày
        filtered = _allItineraryPlans
            .where((plan) => shortStayDurations.contains(plan.duration))
            .toList();
        break;
      case 2: // Dài ngày
        filtered = _allItineraryPlans
            .where((plan) => !shortStayDurations.contains(plan.duration))
            .toList();
        break;
      case 0: // Tất cả
      default:
        filtered = List.from(_allItineraryPlans);
        break;
    }

    setState(() {
      _selectedFilterIndex = filterIndex;
      _filteredItineraryPlans = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _systemGreen,
      appBar: AppBar(
        backgroundColor: _systemGreen,
        elevation: 0,
        title: const Text(
          "Lịch trình",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 16),
                          FilterChipsWidget(
                            onFilterChanged: _filterItineraryPlans,
                          ),
                          if (_allItineraryPlans.isNotEmpty) ...[
                            if (_selectedFilterIndex == 0) ...[
                              _buildSectionHeader(
                                "Phổ biến nhất",
                                Icons.local_fire_department,
                                Colors.orange,
                                showToggleButton: false,
                              ),
                              ..._allItineraryPlans.take(2).map((plan) =>
                                  buildItineraryListItem(context, plan)),
                              const SizedBox(height: 16),
                            ],
                            _buildSectionHeader(
                              "Tất cả lịch trình",
                              Icons.map_outlined,
                              Colors.blue,
                              showToggleButton: true,
                            ),
                          ]
                        ],
                      ),
                    ),
                    if (_allItineraryPlans.isEmpty && !_isLoading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text("Chưa có lịch trình nào được tạo."),
                        ),
                      )
                    else if (_filteredItineraryPlans.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text("Không có lịch trình nào phù hợp."),
                          ),
                        ),
                      )
                    else if (_isGridView)
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => buildItineraryGridItem(
                                context, _filteredItineraryPlans[index]),
                            childCount: _filteredItineraryPlans.length,
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => buildItineraryListItem(
                              context, _filteredItineraryPlans[index]),
                          childCount: _filteredItineraryPlans.length,
                        ),
                      ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color,
      {required bool showToggleButton}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (showToggleButton)
            IconButton(
              icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),
        ],
      ),
    );
  }
}

class FilterChipsWidget extends StatefulWidget {
  final Function(int) onFilterChanged;
  const FilterChipsWidget({super.key, required this.onFilterChanged});

  @override
  State<FilterChipsWidget> createState() => _FilterChipsWidgetState();
}

class _FilterChipsWidgetState extends State<FilterChipsWidget> {
  int _selectedIndex = 0;
  final List<String> _options = ['Tất cả', 'Ngắn ngày', 'Dài ngày'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _options.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedIndex == index;
          return ChoiceChip(
            label: Text(_options[index]),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedIndex = index;
                });
                widget.onFilterChanged(index);
              }
            },
            selectedColor: _systemGreen,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? _systemGreen : Colors.grey[300]!,
              ),
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
      ),
    );
  }
}

Widget buildItineraryListItem(BuildContext context, ItineraryPlan plan) {
  return GestureDetector(
    onTap: () {
      context.pushNamed(
        'ItineraryPlanDetail',
        extra: plan,
      );
    },
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              width: 90,
              height: 110,
              color: _systemGreen.withOpacity(0.8),
              child:
                  const Icon(Icons.map_outlined, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    plan.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(plan.duration ?? 'N/A',
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      const Text('4.8 (124)',
                          style: TextStyle(fontSize: 12)), // Placeholder
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.wb_sunny_outlined,
                          size: 16, color: Colors.orange[400]),
                      const SizedBox(width: 4),
                      const Text('28°C - Thời tiết đẹp',
                          style: TextStyle(fontSize: 12)), // Placeholder
                    ],
                  ),
                  Text(
                    plan.estimatedCost ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _systemGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildItineraryGridItem(BuildContext context, ItineraryPlan plan) {
  return GestureDetector(
    onTap: () {
      context.pushNamed(
        'ItineraryPlanDetail',
        extra: plan,
      );
    },
    child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            width: double.infinity,
            color: _systemGreen.withOpacity(0.8),
            child:
                const Icon(Icons.map_outlined, color: Colors.white, size: 40),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    plan.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              plan.duration ?? 'N/A',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          const Text('4.8',
                              style: TextStyle(fontSize: 12)), // Placeholder
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.wb_sunny_outlined,
                              size: 14, color: Colors.orange[400]),
                          const SizedBox(width: 4),
                          const Text('28°C',
                              style: TextStyle(fontSize: 12)), // Placeholder
                        ],
                      ),
                    ],
                  ),
                  Text(
                    plan.estimatedCost ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _systemGreen,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
