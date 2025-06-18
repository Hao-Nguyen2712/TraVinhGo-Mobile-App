import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../models/event_festival/event_and_festival.dart';
import '../../utils/string_helper.dart';
import '../data_field_row.dart';

class EventFestivalInformationTab extends StatelessWidget {
  final EventAndFestival eventAndFestival;

  const EventFestivalInformationTab(
      {super.key, required this.eventAndFestival});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Divider(
            color: Colors.grey.withOpacity(0.1),
            thickness: 0.4,
            height: 10,
          ),
          DataFieldRow(
            title: 'Location name',
            value: StringHelper.toTitleCase(
                    eventAndFestival.location.name.toString()) ??
                "N/A",
          ),
          DataFieldRow(
            title: 'Category',
            value: StringHelper.toTitleCase(
                eventAndFestival.category),
          ),
          DataFieldRow(
            title: 'Address',
            value: StringHelper.normalizeName(
                    eventAndFestival.location.address.toString()) ??
                "N/A",
          ),
          DataFieldRow(
            title: 'Start date',
            value: StringHelper.formatDate(eventAndFestival.startDate.toString()),
          ),
          DataFieldRow(
            title: 'End date',
            value: StringHelper.formatDate(eventAndFestival.endDate.toString()),
          ),
        ],
      ),
    );
  }
}
