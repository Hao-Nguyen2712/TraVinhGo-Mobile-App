import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../providers/favorite_provider.dart';
import '../../../widget/destination_widget/destination_item.dart';
import '../../../widget/local_specialty_widget/local_specialty_item.dart';
import '../../../widget/ocop_product_widget/ocop_product_item.dart';

class FavoriteAllTab extends StatefulWidget {
  const FavoriteAllTab({super.key});

  @override
  State<FavoriteAllTab> createState() => _FavoriteAllTabState();
}

class _FavoriteAllTabState extends State<FavoriteAllTab> {
  bool showAllDestinations = false;
  bool showAllOcop = false;
  bool showAllLocals = false;

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = FavoriteProvider.of(context);
    final destinations = favoriteProvider.destinationList;
    final ocops = favoriteProvider.ocopProductList;
    final locals = favoriteProvider.localSpecialteList;

    // Số item cho một hàng
    const int destinationPerRow = 2;
    const int ocopPerRow = 2;
    const int localPerRow = 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DESTINATION
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Destination',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          destinations.isEmpty
              ? const Padding(
            padding: EdgeInsets.only(bottom: 12.0),
            child: Text('There are no favorite destination.'),
          )
              : Column(
            children: [
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: showAllDestinations
                    ? destinations.length
                    : (destinations.length > destinationPerRow
                    ? destinationPerRow
                    : destinations.length),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: destinationPerRow,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.58,
                ),
                itemBuilder: (context, index) {
                  return DestinationItem(destination: destinations[index]);
                },
              ),
              if (destinations.length > destinationPerRow)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        showAllDestinations = !showAllDestinations;
                      });
                    },
                    child: Text(
                      showAllDestinations ? 'Less' : 'More',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ),
            ],
          ),
          // OCOP
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Ocop',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          ocops.isEmpty
              ? const Padding(
            padding: EdgeInsets.only(bottom: 12.0),
            child: Text('There are no favorite ocop product.'),
          )
              : Column(
            children: [
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: showAllOcop
                    ? ocops.length
                    : (ocops.length > ocopPerRow
                    ? ocopPerRow
                    : ocops.length),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ocopPerRow,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.58,
                ),
                itemBuilder: (context, index) {
                  return OcopProductItem(ocopProduct: ocops[index]);
                },
              ),
              if (ocops.length > ocopPerRow)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        showAllOcop = !showAllOcop;
                      });
                    },
                    child: Text(
                      showAllOcop ? 'Less' : 'More',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ),
            ],
          ),
          // LOCAL SPECIALTY
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Local',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          locals.isEmpty
              ? const Padding(
            padding: EdgeInsets.only(bottom: 12.0),
            child: Text('There are no favorite local specialte.'),
          )
              : Column(
            children: [
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: showAllLocals
                    ? locals.length
                    : (locals.length > localPerRow
                    ? localPerRow
                    : locals.length),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: localPerRow,
                  childAspectRatio: 1.5,
                ),
                itemBuilder: (context, index) {
                  return LocalSpecialtyItem(localSpecialty: locals[index]);
                },
              ),
              if (locals.length > localPerRow)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        showAllLocals = !showAllLocals;
                      });
                    },
                    child: Text(
                      showAllLocals ? 'Less' : 'More',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}