import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:travinhgo/widget/home_widget/event_festival/slider_event_card.dart';
import '../../../Models/event_festival/event_and_festival.dart';

class ImageSliderEvent extends StatelessWidget {
  final List<EventAndFestival> topEvents;

  const ImageSliderEvent({super.key, required this.topEvents});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26.h,
      child: PageView.builder(
        itemCount: topEvents.length,
        itemBuilder: (context, index) {
          final event = topEvents[index];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: SliderEventCard(
              title: event.nameEvent,
              imageUrl: event.images[0],
              id: event.id,
            ),
          );
        },
      ),
    );
  }
}
