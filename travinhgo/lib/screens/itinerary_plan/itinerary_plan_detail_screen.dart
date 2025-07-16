import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Models/itinerary_plan/itinerary_plan.dart';
import '../../providers/destination_type_provider.dart';
import '../../utils/string_helper.dart';

class ItineraryPlanDetailScreen extends StatefulWidget {
  final ItineraryPlan itineraryPlan;

  const ItineraryPlanDetailScreen({super.key, required this.itineraryPlan});

  @override
  State<ItineraryPlanDetailScreen> createState() =>
      _ItineraryPlanDetailScreenState();
}

class _ItineraryPlanDetailScreenState extends State<ItineraryPlanDetailScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final destinationTypeProvider = DestinationTypeProvider.of(context);
    return Scaffold(
      body: SafeArea(
          child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title:
            Text(StringHelper.toTitleCase(widget.itineraryPlan.name)),
            centerTitle: true,
          ),
          _isLoading
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Scaffold(),
                    ),
                  ),
                )
              : SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  StringHelper.toTitleCase(
                                      widget.itineraryPlan.estimatedCost.toString()),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              SizedBox(width: 26), // khoảng cách nhỏ
                              Text(
                                widget.itineraryPlan.duration ?? "Unknow",
                                style: TextStyle(fontSize: 14),
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount:
                                widget.itineraryPlan.touristDestinations.length,
                            itemBuilder: (context, index) {
                              final item = widget
                                  .itineraryPlan.touristDestinations[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Thời gian
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 60,
                                          alignment: Alignment.center,
                                          // Căn giữa nội dung nếu cần
                                          child: Text(
                                            index.toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    // Nội dung
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Image.network(
                                                destinationTypeProvider
                                                        .getDestinationtypeById(
                                                            item.destinationTypeId)
                                                        .marker
                                                        ?.image ??
                                                    '',
                                                width: 25,
                                                height: 25,
                                              ),
                                              const SizedBox(
                                                width: 6,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  item.address.toString(),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  softWrap: true,
                                                  style:
                                                      TextStyle(fontSize: 14),
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                )
        ],
      )),
    );
  }
}
