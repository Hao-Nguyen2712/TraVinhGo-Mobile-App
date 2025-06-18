import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travinhgo/models/event_festival/event_and_festival.dart';

import '../../utils/string_helper.dart';

class EventFestivalItem extends StatelessWidget {
  final EventAndFestival eventAndFestival;

  const EventFestivalItem({super.key, required this.eventAndFestival});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        context.pushNamed(
          'EventFestivalDetail',
          pathParameters: {'id': eventAndFestival.id},
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 4,
        color: Colors.white,
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
                height: 200,
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
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.yellow,
                    child: Icon(
                      Icons.ramen_dining,
                      color: Colors.red,
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
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
