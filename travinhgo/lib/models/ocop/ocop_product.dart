import '../destination/destination.dart';

class OcopProduct {
  final String id;
  final String productName;
  final String? productDescription;
  final List<String> productImage;
  final String? productPrice;
  final String ocopTypeId;
  final List<SellLocation> sellocations;
  final String companyId;
  final int ocopPoint;
  final int ocopYearRelease;
  final String tagId;
  final Company company;
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
      required this.company,
      this.ocopType});

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
      company: Company.fromJson(json['company']),
      ocopType:
          json['ocopType'] != null ? OcopTypeDTO.fromJson(json['ocopType']) : null,
    );
  }
}

class Company {
  final String id;
  final String name;

  Company({required this.id, required this.name});

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'],
    );
  }
}

class SellLocation {
  final String? locationName;
  final String? locationAddress;
  final Location location;

  SellLocation(
      {required this.locationName,
      this.locationAddress,
      required this.location});

  factory SellLocation.fromJson(Map<String, dynamic> json) {
    return SellLocation(
      locationName: json['locationName'],
      locationAddress: json['locationAddress'],
      location: Location.fromJson(json['location']),
    );
  }
}

class OcopTypeDTO {
  final String id;
  final String ocopTypeName;

  OcopTypeDTO({required this.id, required this.ocopTypeName});

  factory OcopTypeDTO.fromJson(Map<String, dynamic> json) {
    return OcopTypeDTO(id: json['id'], ocopTypeName: json['name']);
  }
}
