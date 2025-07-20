import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travinhgo/models/event_festival/event_and_festival.dart';
import 'package:travinhgo/utils/string_helper.dart';

class EventFestivalInformationTab extends StatelessWidget {
  final EventAndFestival eventAndFestival;

  const EventFestivalInformationTab({
    super.key,
    required this.eventAndFestival,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 18,
          ),
          const Row(
            children: [
              Icon(Icons.calendar_month_outlined,
                  color: Color(0xFF8F83F3), size: 30),
              SizedBox(width: 18),
              Text(
                "Chi tiết sự kiện",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            iconColor: const Color(0xFFF57A82),
            title: "Địa điểm",
            value:
                "${eventAndFestival.location.name}\n${eventAndFestival.location.address}",
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            iconColor: const Color(0xFF8F83F3),
            title: "Ngày bắt đầu",
            value:
                StringHelper.formatDate(eventAndFestival.startDate.toString()),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            icon: Icons.timer_outlined,
            iconColor: const Color(0xFFF57A82),
            title: "Ngày kết thúc",
            value: StringHelper.formatDate(eventAndFestival.endDate.toString()),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            icon: Icons.category_outlined,
            iconColor: const Color(0xFF4B9EFC),
            title: "Loại sự kiện",
            value: eventAndFestival.category,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 30),
        const SizedBox(width: 16),
        Text(
          title,
          style: TextStyle(
              fontSize: 16, color: Colors.black, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
