import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';

import '../../../utils/string_helper.dart';

class SliderDestinationCard extends StatelessWidget {
  final String id;
  final String title;
  final String imageUrl;
  final double? averageRating;

  const SliderDestinationCard(
      {super.key,
      required this.id,
      required this.imageUrl,
      this.averageRating,
      required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 1.h),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12.sp),
              topRight: Radius.circular(12.sp),
            ),
            child: Stack(
              children: [
                Image.network(
                  imageUrl,
                  height: 17.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 17.h,
                      width: double.infinity,
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: Icon(Icons.image_not_supported,
                          color: Colors.grey, size: 30.sp),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 2.w),
                Text(
                  StringHelper.toTitleCase(title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Text(
                      (averageRating ?? 0.0).toStringAsFixed(1),
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    SizedBox(width: 1.w),
                    ...List.generate(5, (index) {
                      double rating = averageRating ?? 0.0;
                      if (index < rating.floor()) {
                        return Icon(Icons.star,
                            color: CupertinoColors.systemYellow, size: 14.sp);
                      } else if (index < rating && rating - index >= 0.5) {
                        return Icon(Icons.star_half,
                            color: CupertinoColors.systemYellow, size: 14.sp);
                      } else {
                        return Icon(Icons.star_border,
                            color: CupertinoColors.systemYellow, size: 14.sp);
                      }
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
