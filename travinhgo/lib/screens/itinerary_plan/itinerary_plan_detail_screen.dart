import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../Models/itinerary_plan/itinerary_plan.dart';
import '../../providers/destination_type_provider.dart';

class ItineraryPlanDetailScreen extends StatelessWidget {
  final ItineraryPlan itineraryPlan;

  const ItineraryPlanDetailScreen({super.key, required this.itineraryPlan});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16.0),
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                child: Text(
                  itineraryPlan.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              background: Container(
                color: colorScheme.primary,
                child: const Icon(
                  Icons.directions_walk,
                  size: 80,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    color: theme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoColumn(
                              context,
                              Icons.access_time,
                              l10n.duration,
                              itineraryPlan.duration ?? l10n.notAvailable),
                          _buildInfoColumn(
                              context,
                              Icons.monetization_on,
                              l10n.cost,
                              itineraryPlan.estimatedCost ?? l10n.notAvailable),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.itineraryDetails,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = itineraryPlan.touristDestinations[index];
                  final isFirst = index == 0;
                  final isLast =
                      index == itineraryPlan.touristDestinations.length - 1;
                  return TimelineTile(
                    isFirst: isFirst,
                    isLast: isLast,
                    destination: item,
                  );
                },
                childCount: itineraryPlan.touristDestinations.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(
      BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon,
            color: isDarkMode ? Colors.white : colorScheme.primary, size: 28),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black)),
      ],
    );
  }
}

class TimelineTile extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final dynamic destination;

  const TimelineTile({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    final destinationTypeProvider = DestinationTypeProvider.of(context);
    final destinationType = destinationTypeProvider
        .getDestinationtypeById(destination.destinationTypeId);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 60,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 1,
                  height: 20,
                  color: isFirst
                      ? Colors.transparent
                      : (isDarkMode ? Colors.white54 : Colors.grey),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: isDarkMode ? Colors.white : colorScheme.primary,
                    size: 24,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 1,
                    color: isLast
                        ? Colors.transparent
                        : (isDarkMode ? Colors.white54 : Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (destinationType.marker?.image != null)
                        Image.network(
                          destinationType.marker!.image!,
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.category, size: 20),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          destination.address.toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
