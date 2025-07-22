import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';

import '../../../utils/string_helper.dart';

class SliderEventCard extends StatelessWidget {
  final String id;
  final String imageUrl;
  final String title;

  const SliderEventCard(
      {super.key,
      required this.imageUrl,
      required this.title,
      required this.id});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          'EventFestivalDetail',
          pathParameters: {'id': id},
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.h),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.sp),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image
            // Image with Favorite Icon
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15.sp),
                topRight: Radius.circular(15.sp),
              ),
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    height: 15.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.h),
            // Name + Icon
            Padding(
              padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 1.w),
              child: Row(
                children: [
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      StringHelper.toTitleCase(title),
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
