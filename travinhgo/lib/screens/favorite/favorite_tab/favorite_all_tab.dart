import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../providers/favorite_provider.dart';
import '../../../widget/destination_widget/destination_item.dart';
import '../../../widget/local_specialty_widget/local_specialty_item.dart';
import '../../../widget/ocop_product_widget/ocop_product_item.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              AppLocalizations.of(context)!.destination,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          destinations.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                      AppLocalizations.of(context)!.noFavoriteDestinations),
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
                        return DestinationItem(
                            destination: destinations[index]);
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
                            showAllDestinations
                                ? AppLocalizations.of(context)!.less
                                : AppLocalizations.of(context)!.more,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                      ),
                  ],
                ),
          // OCOP
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              AppLocalizations.of(context)!.ocop,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          ocops.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(AppLocalizations.of(context)!.noFavoriteOcop),
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
                            showAllOcop
                                ? AppLocalizations.of(context)!.less
                                : AppLocalizations.of(context)!.more,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                      ),
                  ],
                ),
          // LOCAL SPECIALTY
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              AppLocalizations.of(context)!.local,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          locals.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(AppLocalizations.of(context)!.noFavoriteLocal),
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
                        return LocalSpecialtyItem(
                            localSpecialty: locals[index]);
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
                            showAllLocals
                                ? AppLocalizations.of(context)!.less
                                : AppLocalizations.of(context)!.more,
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
