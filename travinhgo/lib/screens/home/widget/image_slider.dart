import 'package:flutter/cupertino.dart';

class ImageSlider extends StatelessWidget {
  final List<String> imageList;
  const ImageSlider({super.key, required this.imageList});

  @override
  Widget build(BuildContext context) {
    final PageController controller = PageController(viewportFraction: 0.9);
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: SizedBox(
        height: 250,
        child: PageView.builder(
          controller: controller,
          itemCount: imageList.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Image.asset("assets/images/sample/"+ imageList[index],
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
