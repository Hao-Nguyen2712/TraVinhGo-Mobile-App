import '../destination/destination.dart';

class OcopProduct {
  final String id;
  final String productName;
  final String? productDescription;
  final List<String>? productImage;
  final String? productPrice;
  final String ocopTypeId;
  final List<SellLocation> sellocations;
  final String companyId;
  final int ocopPoint;
  final int ocopYearRelease;
  final String tagId;

  OcopProduct(
      {required this.id,
      required this.productName,
      this.productDescription,
      this.productImage,
      this.productPrice,
      required this.ocopTypeId,
      required this.sellocations,
      required this.companyId,
      required this.ocopPoint,
      required this.ocopYearRelease,
      required this.tagId});

  factory OcopProduct.fromJson(Map<String, dynamic> json) {
    return OcopProduct(
      id: json['id'],
      productName: json['productName'],
      productDescription: json['productDescription'],
      productImage: json['productImage'] != null
          ? List<String>.from(json['productImage'])
          : [],
      productPrice: json['productPrice'],
      ocopTypeId: json['ocopTypeId'],
      sellocations: json['sellocations'] != null
          ? List<SellLocation>.from(
              json['sellocations'].map((x) => SellLocation.fromJson(x)))
          : [],
      companyId: json['companyId'],
      ocopPoint: json['ocopPoint'],
      ocopYearRelease: json['ocopYearRelease'],
      tagId: json['tagId'],
    );
  }
}

class SellLocation {
  final String locationName;
  final String locationAddress;
  final String markerId;
  final Location location;

  SellLocation(
      {required this.locationName,
      required this.locationAddress,
      required this.markerId,
      required this.location});

  factory SellLocation.fromJson(Map<String, dynamic> json) {
    return SellLocation(
      locationName: json['locationName'],
      locationAddress: json['locationAddress'],
      markerId: json['markerId'],
      location: Location.fromJson(json['location']),
    );
  }
}
