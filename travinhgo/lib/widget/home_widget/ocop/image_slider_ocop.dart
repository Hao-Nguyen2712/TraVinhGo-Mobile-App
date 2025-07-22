import 'package:flutter/cupertino.dart';
import 'package:sizer/sizer.dart';

import '../../../Models/ocop/ocop_product.dart';
import '../../../widget/home_widget/ocop/slider_ocop_card.dart';

class ImageSliderOcop extends StatelessWidget {
  final List<OcopProduct> ocopProducts;
  const ImageSliderOcop({super.key, required this.ocopProducts});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30.h,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ocopProducts.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisSpacing: 2.w,
          childAspectRatio: 1.2,
        ),
        itemBuilder: (context, index) {
          final ocop = ocopProducts[index];
          return SliderOcopCard(
            id: ocop.id,
            title: ocop.productName,
            imageUrl: ocop.productImage[0],
            companyName: ocop.company.name,
          );
        },
      ),
    );
  }
}
