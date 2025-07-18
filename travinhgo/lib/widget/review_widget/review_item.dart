import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: kprimaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                        image: DecorationImage(
                          image: (review.avatar != null &&
                                  review.avatar!.isNotEmpty)
                              ? NetworkImage(
                                  review.avatar!,)
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
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
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
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  timeAgo(review.createdAt.toLocal()),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Enhanced rating badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  kprimaryColor,
                                  kprimaryColor.withOpacity(0.8),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kprimaryColor.withOpacity(0.3),
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
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.star,
                                    size: 14, color: Colors.white),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Review comment with better typography
                      if (review.comment != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Text(
                            review.comment!,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Enhanced images display
                      if (review.images != null && review.images!.isNotEmpty)
                        Container(
                          height: 80,
                          margin: const EdgeInsets.only(bottom: 12),
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
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image:
                                          NetworkImage(review.images![index]),
                                      fit: BoxFit.cover,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
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
