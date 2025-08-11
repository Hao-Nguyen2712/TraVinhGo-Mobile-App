import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/Models/favorite/favorite.dart';

import 'package:travinhgo/models/destination/destination.dart';
import 'package:travinhgo/models/event_festival/event_and_festival.dart';
import 'package:travinhgo/models/local_specialties/local_specialties.dart';
import 'package:travinhgo/models/ocop/ocop_product.dart';
import 'package:travinhgo/services/event_festival_service.dart';
import '../services/destination_service.dart';
import '../services/favorite_service.dart';
import '../services/local_specialtie_service.dart';
import '../services/ocop_product_service.dart';

class FavoriteProvider extends ChangeNotifier {
  final List<Favorite> _favorites = [];
  final List<Destination> _destinationList = [];
  final List<LocalSpecialties> _localSpecialteList = [];
  final List<OcopProduct> _ocopProductList = [];
  final List<EventAndFestival> _eventFestivalList = [];

  List<Favorite> get favorites => _favorites;

  List<Destination> get destinationList => _destinationList;

  List<LocalSpecialties> get localSpecialteList => _localSpecialteList;

  List<OcopProduct> get ocopProductList => _ocopProductList;

  List<EventAndFestival> get eventFestivalList => _eventFestivalList;

  Future<void> fetchFavorites() async {
    try {
      List<Favorite> favoriteFetch = await FavoriteService().getFavorites();
      _favorites.clear();
      _favorites.addAll(favoriteFetch);

      List<String> destinationIds = [];
      List<String> ocopIds = [];
      List<String> localIds = [];
      List<String> eventFestivalIds = [];

      for (var item in _favorites) {
        switch (item.itemType) {
          case 'Destination':
            destinationIds.add(item.itemId);
            break;
          case 'OcopProduct':
            ocopIds.add(item.itemId);
            break;
          case 'LocalSpecialties':
            localIds.add(item.itemId);
            break;
          case 'EventAndFestival':
            eventFestivalIds.add(item.itemId);
            break;
        }
      }

      // Chuẩn bị future cho từng loại
      final destinationFuture = destinationIds.isNotEmpty
          ? DestinationService().getDestinationsByIds(destinationIds)
          : Future.value(<Destination>[]);

      final ocopFuture = ocopIds.isNotEmpty
          ? OcopProductService().getOcopProductsByIds(ocopIds)
          : Future.value(<OcopProduct>[]);

      final localFuture = localIds.isNotEmpty
          ? LocalSpecialtieService().getLocalSpecialtiesByIds(localIds)
          : Future.value(<LocalSpecialties>[]);

      final eventFestivalFuture = eventFestivalIds.isNotEmpty
          ? EventFestivalService().getEventFestivalsByIds(eventFestivalIds)
          : Future.value(<EventAndFestival>[]);

      // Chờ 4 future hoàn tất song song
      final results = await Future.wait([
        destinationFuture,
        ocopFuture,
        localFuture,
        eventFestivalFuture,
      ]);

      // Gán kết quả vào danh sách tương ứng
      _destinationList
        ..clear()
        ..addAll(results[0] as List<Destination>);

      _ocopProductList
        ..clear()
        ..addAll(results[1] as List<OcopProduct>);

      _localSpecialteList
        ..clear()
        ..addAll(results[2] as List<LocalSpecialties>);

      _eventFestivalList
        ..clear()
        ..addAll(results[3] as List<EventAndFestival>);

      debugPrint('-------------------------------------------');
      for (var destination in _destinationList) {
        debugPrint('name: ${destination.name}, ID: ${destination.id}');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch favorite: $e');
    }
  }

  void toggleDestinationFavorite(Destination item) {
    final isCurrentlyFavorite = isExist(item.id);
    if (isCurrentlyFavorite) {
      _favorites.removeWhere((f) => f.itemId == item.id);
      _destinationList.removeWhere((d) => d.id == item.id);
      FavoriteService().removeFavoriteList(item.id);
    } else {
      final fav = Favorite(itemId: item.id, itemType: "Destination");
      _favorites.add(fav);
      _destinationList.add(item);
      FavoriteService().addFavoriteList(fav);
    }
    notifyListeners();
  }

  void toggleOcopFavorite(OcopProduct item) {
    final isCurrentlyFavorite = isExist(item.id);
    if (isCurrentlyFavorite) {
      _favorites.removeWhere((f) => f.itemId == item.id);
      _ocopProductList.removeWhere((o) => o.id == item.id);
      FavoriteService().removeFavoriteList(item.id);
    } else {
      final fav = Favorite(itemId: item.id, itemType: "OcopProduct");
      _favorites.add(fav);
      _ocopProductList.add(item);
      FavoriteService().addFavoriteList(fav);
    }
    notifyListeners();
  }

  void toggleLocalSpecialtiesFavorite(LocalSpecialties item) {
    final isCurrentlyFavorite = isExist(item.id);
    if (isCurrentlyFavorite) {
      _favorites.removeWhere((f) => f.itemId == item.id);
      _localSpecialteList.removeWhere((l) => l.id == item.id);
      FavoriteService().removeFavoriteList(item.id);
    } else {
      final fav = Favorite(itemId: item.id, itemType: "LocalSpecialties");
      _favorites.add(fav);
      _localSpecialteList.add(item);
      FavoriteService().addFavoriteList(fav);
    }
    notifyListeners();
  }

  void toggleEventFestivalFavorite(EventAndFestival item) {
    final isCurrentlyFavorite = isExist(item.id);
    if (isCurrentlyFavorite) {
      _favorites.removeWhere((f) => f.itemId == item.id);
      _eventFestivalList.removeWhere((e) => e.id == item.id);
      FavoriteService().removeFavoriteList(item.id);
    } else {
      final fav = Favorite(itemId: item.id, itemType: "EventAndFestival");
      _favorites.add(fav);
      _eventFestivalList.add(item);
      FavoriteService().addFavoriteList(fav);
    }
    notifyListeners();
  }

  bool isExist(String id) {
    return _favorites.any((fav) => fav.itemId == id);
  }

  static FavoriteProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<FavoriteProvider>(context, listen: listen);
  }
}
