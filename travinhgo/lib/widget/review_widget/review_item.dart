import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../Models/review/reply_user_information.dart';
import '../../Models/review/review.dart';
import '../../utils/constants.dart';

// Time ago utility
String timeAgo(DateTime date) {
  final duration = DateTime.now().difference(date);
  if (duration.inMinutes < 1) return 'Just now';
  if (duration.inHours < 1) return '${duration.inMinutes} min ago';
  if (duration.inDays < 1) return '${duration.inHours} hr ago';
  return '${duration.inDays} day(s) ago';
}

class ReviewItem extends StatefulWidget {
  final ReviewResponse review;

  const ReviewItem({super.key, required this.review});

  @override
  State<ReviewItem> createState() => _ReviewItemState();
}

class _ReviewItemState extends State<ReviewItem> with TickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _expandAnimationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    final replies = review.reply ?? [];
    final repliesToShow = isExpanded ? replies : replies.take(1).toList();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.sp),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main review section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced Avatar with online indicator
                Stack(
                  children: [
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.3),
                          width: 0.5.w,
                        ),
                        image: DecorationImage(
                          image: (review.avatar != null &&
                                  review.avatar!.isNotEmpty)
                              ? NetworkImage(
                                  review.avatar!,
                                )
                              : const AssetImage(
                                      'assets/images/profile/profile.png')
                                  as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                    ),
                    // Online indicator (optional)
                    Positioned(
                      bottom: 0.2.h,
                      right: 0.5.w,
                      child: Container(
                        width: 3.w,
                        height: 3.w,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: theme.cardColor, width: 0.5.w),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 3.w),
                // Review content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with improved layout
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review.userName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 0.3.h),
                                Text(
                                  timeAgo(review.createdAt.toLocal()),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          // Enhanced rating badge
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 3.w, vertical: 0.8.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15.sp),
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.primary.withOpacity(0.8),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  review.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                SizedBox(width: 1.w),
                                Icon(Icons.star,
                                    size: 11.sp, color: Colors.amber),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.5.h),

                      // Review comment with better typography
                      if (review.comment != null)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10.sp),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Text(
                            review.comment!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),

                      SizedBox(height: 1.5.h),

                      // Enhanced images display
                      if (review.images != null && review.images!.isNotEmpty)
                        Container(
                          height: 10.h,
                          margin: EdgeInsets.only(bottom: 1.5.h),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: review.images!.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text("Viewing image ${index + 1}"),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.sp),
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: EdgeInsets.only(right: 2.w),
                                  width: 20.w,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.sp),
                                    image: DecorationImage(
                                      image:
                                          NetworkImage(review.images![index]),
                                      fit: BoxFit.cover,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            theme.shadowColor.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
