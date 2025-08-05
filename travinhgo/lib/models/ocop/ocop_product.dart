import 'package:hive/hive.dart';
import 'package:travinhgo/models/location.dart';

part 'ocop_product.g.dart';

@HiveType(typeId: 10)
class OcopProduct extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String productName;
  @HiveField(2)
  final String? productDescription;
  @HiveField(3)
  final List<String> productImage;
  @HiveField(4)
  final String? productPrice;
  @HiveField(5)
  final String ocopTypeId;
  @HiveField(6)
  final List<SellLocation> sellocations;
  @HiveField(7)
  final String companyId;
  @HiveField(8)
  final int ocopPoint;
  @HiveField(9)
  final int ocopYearRelease;
  @HiveField(10)
  final String tagId;
  @HiveField(11)
  final Company? company;
  @HiveField(12)
  final OcopTypeDTO? ocopType;

  OcopProduct(
      {required this.id,
      required this.productName,
      this.productDescription,
      required this.productImage,
      this.productPrice,
      required this.ocopTypeId,
      required this.sellocations,
      required this.companyId,
      required this.ocopPoint,
      required this.ocopYearRelease,
      required this.tagId,
      this.company,
      this.ocopType});

  factory OcopProduct.fromJson(Map<String, dynamic> json) {
    return OcopProduct(
      id: json['id'],
      productName: json['productName'],
      productDescription: json['productDescription'],
      productImage: json['productImage'] != null
          ? List<String>.from(json['productImage'])
          : [],
      productPrice: json['productPrice']?.toString(),
      ocopTypeId: json['ocopTypeId'],
      sellocations: json['sellocations'] != null
          ? List<SellLocation>.from(
              json['sellocations'].map((x) => SellLocation.fromJson(x)))
          : [],
      companyId: json['companyId'],
      ocopPoint: json['ocopPoint'],
      ocopYearRelease: json['ocopYearRelease'],
      tagId: json['tagId'],
      company:
          json['company'] != null ? Company.fromJson(json['company']) : null,
      ocopType: json['ocopType'] != null
          ? OcopTypeDTO.fromJson(json['ocopType'])
          : null,
    );
  }
}

@HiveType(typeId: 11)
class Company extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;

  Company({required this.id, required this.name});

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'],
    );
  }
}

@HiveType(typeId: 12)
class SellLocation extends HiveObject {
  @HiveField(0)
  final String? locationName;
  @HiveField(1)
  final String? locationAddress;
  @HiveField(2)
  final Location? location;

  SellLocation(
      {required this.locationName,
      this.locationAddress,
      required this.location});

  factory SellLocation.fromJson(Map<String, dynamic> json) {
    return SellLocation(
      locationName: json['locationName'],
      locationAddress: json['locationAddress'],
      location:
          json['location'] != null ? Location.fromJson(json['location']) : null,
    );
  }
}

@HiveType(typeId: 13)
class OcopTypeDTO extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String ocopTypeName;

  OcopTypeDTO({required this.id, required this.ocopTypeName});

  factory OcopTypeDTO.fromJson(Map<String, dynamic> json) {
    return OcopTypeDTO(id: json['id'], ocopTypeName: json['name']);
  }
}
