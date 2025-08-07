import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
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
    final localizations = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 1.h,
          ),
          Row(
            children: [
              Icon(Icons.calendar_month_outlined,
                  color: const Color(0xFF8F83F3), size: 22.sp),
              SizedBox(width: 3.w),
              Text(
                localizations.eventDetails,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          _buildInfoRow(
            icon: Icons.home_filled,
            iconColor: const Color(0xFFF57A82),
            title: localizations.location,
            value: "${eventAndFestival.location.name}",
          ),
          SizedBox(height: 2.5.h),
          _buildInfoRow(
            icon: Icons.location_on_rounded,
            iconColor: const Color(0xFFF57A82),
            title: localizations.address,
            value: "${eventAndFestival.location.address}",
          ),
          SizedBox(height: 2.5.h),
          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            iconColor: const Color(0xFF8F83F3),
            title: localizations.startDate,
            value:
                StringHelper.formatDate(eventAndFestival.startDate.toString()),
          ),
          SizedBox(height: 2.5.h),
          _buildInfoRow(
            icon: Icons.timer_rounded,
            iconColor: const Color(0xFFF57A82),
            title: localizations.endDate,
            value: StringHelper.formatDate(eventAndFestival.endDate.toString()),
          ),
          SizedBox(height: 2.5.h),
          _buildInfoRow(
            icon: Icons.category_rounded,
            iconColor: const Color(0xFF4B9EFC),
            title: localizations.eventType,
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
        Icon(icon, color: iconColor, size: 22.sp),
        SizedBox(width: 4.w),
        Text(
          title,
          style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black,
              fontWeight: FontWeight.w700),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
