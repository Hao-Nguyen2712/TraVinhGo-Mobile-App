import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EventFestivalContentTab extends StatelessWidget {
  final String? description;

  const EventFestivalContentTab({
    super.key,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 2.h,
          ),
          Row(
            children: [
              Icon(Icons.library_books_outlined,
                  color: const Color(0xFF8F83F3), size: 18.sp),
              SizedBox(width: 2.w),
              Text(
                localizations.eventDescription,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Html(
            data: description ?? localizations.noDescription,
            style: {
              "body": Style(
                fontSize: FontSize(15.sp),
                color: Colors.grey.shade700,
                lineHeight: const LineHeight(1.5),
              ),
            },
          ),
        ],
      ),
    );
  }
}
