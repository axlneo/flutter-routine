// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SessionRecordAdapter extends TypeAdapter<SessionRecord> {
  @override
  final int typeId = 0;

  @override
  SessionRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionRecord(
      id: fields[0] as String,
      tsStart: fields[1] as DateTime,
      tsEnd: fields[2] as DateTime?,
      routineId: fields[3] as String,
      day: fields[4] as int?,
      completed: fields[5] as bool,
      hrTrace: (fields[6] as List?)?.cast<HrPoint>(),
    );
  }

  @override
  void write(BinaryWriter writer, SessionRecord obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tsStart)
      ..writeByte(2)
      ..write(obj.tsEnd)
      ..writeByte(3)
      ..write(obj.routineId)
      ..writeByte(4)
      ..write(obj.day)
      ..writeByte(5)
      ..write(obj.completed)
      ..writeByte(6)
      ..write(obj.hrTrace);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HrPointAdapter extends TypeAdapter<HrPoint> {
  @override
  final int typeId = 1;

  @override
  HrPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HrPoint(
      t: fields[0] as DateTime,
      hr: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HrPoint obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.t)
      ..writeByte(1)
      ..write(obj.hr);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HrPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MedRecordAdapter extends TypeAdapter<MedRecord> {
  @override
  final int typeId = 2;

  @override
  MedRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedRecord(
      date: fields[0] as String,
      slot: fields[1] as String,
      items: (fields[2] as List).cast<String>(),
      checked: fields[3] as bool,
      checkedAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MedRecord obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.slot)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.checked)
      ..writeByte(4)
      ..write(obj.checkedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 3;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      age: fields[0] as int,
      hrRest: fields[1] as int?,
      hrMaxOverride: fields[2] as int?,
      useKarvonen: fields[3] as bool,
      notificationsEnabled: fields[4] as bool,
      polarDeviceId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.age)
      ..writeByte(1)
      ..write(obj.hrRest)
      ..writeByte(2)
      ..write(obj.hrMaxOverride)
      ..writeByte(3)
      ..write(obj.useKarvonen)
      ..writeByte(4)
      ..write(obj.notificationsEnabled)
      ..writeByte(5)
      ..write(obj.polarDeviceId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
