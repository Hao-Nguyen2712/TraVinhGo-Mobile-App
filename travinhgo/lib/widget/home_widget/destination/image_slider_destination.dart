import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import '../../../Models/Maps/top_favorite_destination.dart';
import '../../../widget/home_widget/destination/slider_destination_card.dart';

class ImageSliderDestination extends StatelessWidget {
  final List<TopFavoriteDestination> favoriteDestinations;

  const ImageSliderDestination({super.key, required this.favoriteDestinations});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26.h,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: favoriteDestinations.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisSpacing: 2.w,
          childAspectRatio: 1.5,
        ),
        itemBuilder: (context, index) {
          final destination = favoriteDestinations[index];
          if (destination.id == null ||
              destination.name == null ||
              destination.image == null) {
            // Return an empty container or a placeholder for invalid data
            return Container();
          }
          return GestureDetector(
            onTap: () {
              context.pushNamed('TouristDestinationDetail',
                  pathParameters: {'id': destination.id!});
            },
            child: SliderDestinationCard(
              id: destination.id!,
              title: destination.name!,
              imageUrl: destination.image!,
              averageRating: destination.averageRating,
            ),
          );
        },
      ),
    );
  }
}
