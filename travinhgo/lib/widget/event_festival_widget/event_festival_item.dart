import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import 'package:travinhgo/models/event_festival/event_and_festival.dart';

import '../../utils/string_helper.dart';

class EventFestivalItem extends StatelessWidget {
  final EventAndFestival eventAndFestival;

  const EventFestivalItem({super.key, required this.eventAndFestival});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          'EventFestivalDetail',
          pathParameters: {'id': eventAndFestival.id},
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 4,
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Image.network(
                eventAndFestival.images.first,
                height: 20.h,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            // Name + Icon
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Icon (ví dụ dùng icon cục gạch tạm)
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.ramen_dining,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Text
                  Expanded(
                    child: Text(
                      StringHelper.toTitleCase(eventAndFestival.nameEvent),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
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
