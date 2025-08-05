// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ocop_product.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OcopProductAdapter extends TypeAdapter<OcopProduct> {
  @override
  final int typeId = 10;

  @override
  OcopProduct read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OcopProduct(
      id: fields[0] as String,
      productName: fields[1] as String,
      productDescription: fields[2] as String?,
      productImage: (fields[3] as List).cast<String>(),
      productPrice: fields[4] as String?,
      ocopTypeId: fields[5] as String,
      sellocations: (fields[6] as List).cast<SellLocation>(),
      companyId: fields[7] as String,
      ocopPoint: fields[8] as int,
      ocopYearRelease: fields[9] as int,
      tagId: fields[10] as String,
      company: fields[11] as Company?,
      ocopType: fields[12] as OcopTypeDTO?,
    );
  }

  @override
  void write(BinaryWriter writer, OcopProduct obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.productDescription)
      ..writeByte(3)
      ..write(obj.productImage)
      ..writeByte(4)
      ..write(obj.productPrice)
      ..writeByte(5)
      ..write(obj.ocopTypeId)
      ..writeByte(6)
      ..write(obj.sellocations)
      ..writeByte(7)
      ..write(obj.companyId)
      ..writeByte(8)
      ..write(obj.ocopPoint)
      ..writeByte(9)
      ..write(obj.ocopYearRelease)
      ..writeByte(10)
      ..write(obj.tagId)
      ..writeByte(11)
      ..write(obj.company)
      ..writeByte(12)
      ..write(obj.ocopType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcopProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CompanyAdapter extends TypeAdapter<Company> {
  @override
  final int typeId = 11;

  @override
  Company read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Company(
      id: fields[0] as String,
      name: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Company obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SellLocationAdapter extends TypeAdapter<SellLocation> {
  @override
  final int typeId = 12;

  @override
  SellLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SellLocation(
      locationName: fields[0] as String?,
      locationAddress: fields[1] as String?,
      location: fields[2] as Location?,
    );
  }

  @override
  void write(BinaryWriter writer, SellLocation obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.locationName)
      ..writeByte(1)
      ..write(obj.locationAddress)
      ..writeByte(2)
      ..write(obj.location);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SellLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OcopTypeDTOAdapter extends TypeAdapter<OcopTypeDTO> {
  @override
  final int typeId = 13;

  @override
  OcopTypeDTO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OcopTypeDTO(
      id: fields[0] as String,
      ocopTypeName: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, OcopTypeDTO obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ocopTypeName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcopTypeDTOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
