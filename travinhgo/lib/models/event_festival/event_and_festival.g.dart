// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_and_festival.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventAndFestivalAdapter extends TypeAdapter<EventAndFestival> {
  @override
  final int typeId = 14;

  @override
  EventAndFestival read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventAndFestival(
      id: fields[0] as String,
      nameEvent: fields[1] as String,
      description: fields[2] as String?,
      startDate: fields[3] as DateTime,
      endDate: fields[4] as DateTime,
      category: fields[5] as String,
      images: (fields[6] as List).cast<String>(),
      location: fields[7] as EventLocation,
      tagId: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, EventAndFestival obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nameEvent)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.endDate)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.images)
      ..writeByte(7)
      ..write(obj.location)
      ..writeByte(8)
      ..write(obj.tagId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventAndFestivalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EventLocationAdapter extends TypeAdapter<EventLocation> {
  @override
  final int typeId = 15;

  @override
  EventLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventLocation(
      name: fields[0] as String?,
      address: fields[1] as String?,
      location: fields[2] as Location,
      markerId: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, EventLocation obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.address)
      ..writeByte(2)
      ..write(obj.location)
      ..writeByte(3)
      ..write(obj.markerId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
