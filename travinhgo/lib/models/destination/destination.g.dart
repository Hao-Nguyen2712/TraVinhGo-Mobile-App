// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'destination.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DestinationAdapter extends TypeAdapter<Destination> {
  @override
  final int typeId = 0;

  @override
  Destination read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Destination(
      id: fields[0] as String,
      name: fields[1] as String,
      avarageRating: fields[2] as double,
      description: fields[3] as String?,
      address: fields[4] as String?,
      location: fields[5] as Location,
      images: (fields[6] as List).cast<String>(),
      historyStory: fields[7] as HistoryStory?,
      updateAt: fields[8] as DateTime?,
      destinationTypeId: fields[9] as String,
      openingHours: fields[10] as OpeningHours?,
      capacity: fields[11] as String?,
      contact: fields[12] as Contact?,
      tagId: fields[13] as String,
      ticket: fields[14] as String?,
      favoriteCount: fields[15] as int?,
      status: fields[16] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Destination obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.avarageRating)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.address)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.images)
      ..writeByte(7)
      ..write(obj.historyStory)
      ..writeByte(8)
      ..write(obj.updateAt)
      ..writeByte(9)
      ..write(obj.destinationTypeId)
      ..writeByte(10)
      ..write(obj.openingHours)
      ..writeByte(11)
      ..write(obj.capacity)
      ..writeByte(12)
      ..write(obj.contact)
      ..writeByte(13)
      ..write(obj.tagId)
      ..writeByte(14)
      ..write(obj.ticket)
      ..writeByte(15)
      ..write(obj.favoriteCount)
      ..writeByte(16)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DestinationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HistoryStoryAdapter extends TypeAdapter<HistoryStory> {
  @override
  final int typeId = 2;

  @override
  HistoryStory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryStory(
      content: fields[0] as String?,
      images: (fields[1] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, HistoryStory obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.content)
      ..writeByte(1)
      ..write(obj.images);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryStoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OpeningHoursAdapter extends TypeAdapter<OpeningHours> {
  @override
  final int typeId = 3;

  @override
  OpeningHours read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OpeningHours(
      openTime: fields[0] as String?,
      closeTime: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OpeningHours obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.openTime)
      ..writeByte(1)
      ..write(obj.closeTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpeningHoursAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ContactAdapter extends TypeAdapter<Contact> {
  @override
  final int typeId = 4;

  @override
  Contact read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Contact(
      phone: fields[0] as String?,
      email: fields[1] as String?,
      website: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Contact obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.phone)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.website);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
