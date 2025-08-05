// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_specialties.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalSpecialtiesAdapter extends TypeAdapter<LocalSpecialties> {
  @override
  final int typeId = 0;

  @override
  LocalSpecialties read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalSpecialties(
      id: fields[0] as String,
      foodName: fields[1] as String,
      description: fields[2] as String?,
      images: (fields[3] as List).cast<String>(),
      locations: (fields[4] as List).cast<LocalSpecialtyLocation>(),
      tagId: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LocalSpecialties obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.foodName)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.images)
      ..writeByte(4)
      ..write(obj.locations)
      ..writeByte(5)
      ..write(obj.tagId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalSpecialtiesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocalSpecialtyLocationAdapter
    extends TypeAdapter<LocalSpecialtyLocation> {
  @override
  final int typeId = 2;

  @override
  LocalSpecialtyLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalSpecialtyLocation(
      locationId: fields[0] as String,
      name: fields[1] as String,
      address: fields[2] as String,
      markerId: fields[3] as String,
      location: fields[4] as Location,
    );
  }

  @override
  void write(BinaryWriter writer, LocalSpecialtyLocation obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.locationId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.markerId)
      ..writeByte(4)
      ..write(obj.location);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalSpecialtyLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
