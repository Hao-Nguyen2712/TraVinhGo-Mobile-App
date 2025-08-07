// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'top_favorite_destination.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TopFavoriteDestinationAdapter
    extends TypeAdapter<TopFavoriteDestination> {
  @override
  final int typeId = 16;

  @override
  TopFavoriteDestination read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TopFavoriteDestination(
      fields[0] as String?,
      fields[1] as String?,
      fields[2] as String?,
      fields[3] as double?,
      fields[4] as String?,
      fields[5] as double?,
      fields[6] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, TopFavoriteDestination obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.image)
      ..writeByte(3)
      ..write(obj.averageRating)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.latitude)
      ..writeByte(6)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopFavoriteDestinationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
