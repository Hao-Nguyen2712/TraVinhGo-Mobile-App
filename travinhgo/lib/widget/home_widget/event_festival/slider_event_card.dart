import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../utils/string_helper.dart';

class SliderEventCard extends StatelessWidget {
  final String id;
  final String imageUrl;
  final String title;

  const SliderEventCard(
      {super.key, required this.imageUrl, required this.title, required this.id});

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
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        elevation: 4,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          
          children: [
            // Image
            // Image with Favorite Icon
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ],
              ),
            ),
            // Name + Icon
            Padding(
              padding: const EdgeInsets.symmetric(vertical:6, horizontal: 2 ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      StringHelper.toTitleCase(title),
                      style: const TextStyle(
                        fontSize: 16,
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
