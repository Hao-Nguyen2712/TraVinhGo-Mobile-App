import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RatingStarWidget extends StatelessWidget {
  final int point;
  const RatingStarWidget(this.point, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          point.toString(),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 4),
        ...List.generate(5, (index) {
          if (index < point) {
            return Icon(Icons.star,
                color: Theme.of(context).colorScheme.secondary, size: 14);
          } else {
            return Icon(Icons.star_border,
                color: Theme.of(context).colorScheme.secondary, size: 14);
          }
        }),
      ],
    );
  }
}
