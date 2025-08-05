import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:sizer/sizer.dart';

class EventFestivalContentTab extends StatelessWidget {
  final String? description;

  const EventFestivalContentTab({
    super.key,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
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
                "Mô tả sự kiện",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Html(
            data: description ?? 'Chưa có mô tả cho sự kiện này.',
            style: {
              "body": Style(
                fontSize: FontSize(14.sp),
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
