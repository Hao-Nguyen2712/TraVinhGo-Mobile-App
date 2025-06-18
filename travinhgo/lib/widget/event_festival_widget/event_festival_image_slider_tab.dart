import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EventFestivalImageSliderTab extends StatelessWidget {
  final Function(int) onChange;
  final List<String> imageList;
  const EventFestivalImageSliderTab({super.key, required this.onChange, required this.imageList});

  @override
  Widget build(BuildContext context) {
    final PageController controller = PageController(viewportFraction: 1.0);
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SizedBox(
        height: 550,
        child: PageView.builder(
          controller: controller,
          itemCount: imageList.length,
          onPageChanged: onChange,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imageList[index],
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 300),
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}