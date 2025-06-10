import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:travinhgo/models/destination/destination.dart';
import 'package:travinhgo/providers/destination_type_provider.dart';
import 'package:travinhgo/screens/destination/destination_detail_screen.dart';
import 'package:travinhgo/utils/constants.dart';

class DestinationItem extends StatelessWidget {
  final Destination destination;

  const DestinationItem({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    final destinationTypeProvider = DestinationTypeProvider.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DestinationDetailScreen(
                id: destination.id,
                )));
      },
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: kcontentColor,
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.1),
                  blurRadius: 10, 
                  spreadRadius: 2, 
                  offset: Offset(0, 4), 
                )
              ]
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Center(
                    child: Container(
                      width: 175,
                      height: 190,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          image: DecorationImage(
                              image: NetworkImage(destination.images[0]),
                              fit: BoxFit.cover)),
                    ),
                  ),
                  const SizedBox(height: 4,),
                  Text(
                    destination.name,
                    maxLines: 2,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kprimaryColor,
                        fontSize: 16,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Row(
                    children: [
                      Text(
                        destination.avarageRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      ...List.generate(5, (index) {
                        double rating = destination.avarageRating;
                        if (index < rating.floor()) {
                          return Icon(Icons.star,
                              color: CupertinoColors.systemYellow, size: 12);
                        } else if (index < rating && rating - index >= 0.5) {
                          return Icon(Icons.star_half,
                              color: CupertinoColors.systemYellow, size: 12);
                        } else {
                          return Icon(Icons.star_border,
                              color: CupertinoColors.systemYellow, size: 12);
                        }
                      }),
                      const SizedBox(width: 4),
                      Text(
                        '(53 reviewer)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      Image.network(
                        destinationTypeProvider
                                .getDestinationtypeById(
                                    destination.destinationTypeId)
                                .marker
                                ?.image ??
                            '',
                        width: 25,
                        height: 25,
                      ),
                      const SizedBox(width: 6,),
                      Expanded(
                        child: Text(
                          destination.address.toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
