import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'models.g.dart';

// ============ EXERCISE & SECTION ============

class Exercise {
  final String title;
  final String description;
  final int duration;
  final String icon;
  final bool isBilateral;
  final List<String> instructions;
  final int? sets;
  final int? reps;
  bool isCompleted;

  Exercise({
    required this.title,
    required this.description,
    required this.duration,
    required this.icon,
    this.isBilateral = false,
    this.instructions = const [],
    this.sets,
    this.reps,
    this.isCompleted = false,
  });

  int get midPoint => duration ~/ 2;
}

class Section {
  final String title;
  final String emoji;
  final Color color;
  final List<Exercise> exercises;

  Section({
    required this.title,
    required this.emoji,
    required this.color,
    required this.exercises,
  });

  int get totalDuration => exercises.fold(0, (sum, e) => sum + e.duration);
  int get completedCount => exercises.where((e) => e.isCompleted).length;
}

// ============ ROUTINE TYPE ============

enum RoutineType { morning, evening }

// ============ HR ZONE ============

enum HrZone {
  recovery, // <50%
  fatBurn, // 50-60%
  endurance, // 60-70%
  cardio, // 70-80%
  threshold, // 80-90%
  redZone, // >=90%
}

extension HrZoneExtension on HrZone {
  String get label {
    switch (this) {
      case HrZone.recovery:
        return 'Récup';
      case HrZone.fatBurn:
        return 'Brûlage';
      case HrZone.endurance:
        return 'Endurance';
      case HrZone.cardio:
        return 'Cardio';
      case HrZone.threshold:
        return 'Seuil';
      case HrZone.redZone:
        return 'Zone rouge';
    }
  }

  Color get color {
    switch (this) {
      case HrZone.recovery:
        return Colors.grey;
      case HrZone.fatBurn:
        return Colors.blue;
      case HrZone.endurance:
        return Colors.green;
      case HrZone.cardio:
        return Colors.orange;
      case HrZone.threshold:
        return Colors.deepOrange;
      case HrZone.redZone:
        return Colors.red;
    }
  }
}

// ============ HIVE MODELS ============

@HiveType(typeId: 0)
class SessionRecord extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late DateTime tsStart;

  @HiveField(2)
  DateTime? tsEnd;

  @HiveField(3)
  late String routineId; // "morning" or "evening"

  @HiveField(4)
  int? day; // 1-7 for evening, null for morning

  @HiveField(5)
  late bool completed;

  @HiveField(6)
  late List<HrPoint> hrTrace;

  SessionRecord({
    required this.id,
    required this.tsStart,
    this.tsEnd,
    required this.routineId,
    this.day,
    this.completed = false,
    List<HrPoint>? hrTrace,
  }) : hrTrace = hrTrace ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'tsStart': tsStart.toIso8601String(),
        'tsEnd': tsEnd?.toIso8601String(),
        'routineId': routineId,
        'day': day,
        'completed': completed,
        'hrTrace': hrTrace.map((p) => p.toJson()).toList(),
      };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
        id: json['id'] as String,
        tsStart: DateTime.parse(json['tsStart'] as String),
        tsEnd: json['tsEnd'] != null
            ? DateTime.parse(json['tsEnd'] as String)
            : null,
        routineId: json['routineId'] as String,
        day: json['day'] as int?,
        completed: json['completed'] as bool,
        hrTrace: (json['hrTrace'] as List<dynamic>?)
            ?.map((e) => HrPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  int get durationMinutes {
    if (tsEnd == null) return 0;
    return tsEnd!.difference(tsStart).inMinutes;
  }

  int? get averageHr {
    if (hrTrace.isEmpty) return null;
    final sum = hrTrace.fold<int>(0, (s, p) => s + p.hr);
    return sum ~/ hrTrace.length;
  }
}

@HiveType(typeId: 1)
class HrPoint {
  @HiveField(0)
  late DateTime t;

  @HiveField(1)
  late int hr;

  HrPoint({required this.t, required this.hr});

  Map<String, dynamic> toJson() => {
        't': t.toIso8601String(),
        'hr': hr,
      };

  factory HrPoint.fromJson(Map<String, dynamic> json) => HrPoint(
        t: DateTime.parse(json['t'] as String),
        hr: json['hr'] as int,
      );
}

@HiveType(typeId: 2)
class MedRecord extends HiveObject {
  @HiveField(0)
  late String date; // YYYY-MM-DD

  @HiveField(1)
  late String slot; // "morning" or "evening"

  @HiveField(2)
  late List<String> items;

  @HiveField(3)
  late bool checked;

  @HiveField(4)
  DateTime? checkedAt;

  MedRecord({
    required this.date,
    required this.slot,
    required this.items,
    this.checked = false,
    this.checkedAt,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'slot': slot,
        'items': items,
        'checked': checked,
        'checkedAt': checkedAt?.toIso8601String(),
      };

  factory MedRecord.fromJson(Map<String, dynamic> json) => MedRecord(
        date: json['date'] as String,
        slot: json['slot'] as String,
        items: (json['items'] as List<dynamic>).cast<String>(),
        checked: json['checked'] as bool,
        checkedAt: json['checkedAt'] != null
            ? DateTime.parse(json['checkedAt'] as String)
            : null,
      );
}

@HiveType(typeId: 3)
class UserSettings extends HiveObject {
  @HiveField(0)
  int age;

  @HiveField(1)
  int? hrRest;

  @HiveField(2)
  int? hrMaxOverride;

  @HiveField(3)
  bool useKarvonen;

  @HiveField(4)
  bool notificationsEnabled;

  @HiveField(5)
  String? polarDeviceId;

  UserSettings({
    this.age = 40,
    this.hrRest,
    this.hrMaxOverride,
    this.useKarvonen = true,
    this.notificationsEnabled = true,
    this.polarDeviceId,
  });

  Map<String, dynamic> toJson() => {
        'age': age,
        'hrRest': hrRest,
        'hrMaxOverride': hrMaxOverride,
        'useKarvonen': useKarvonen,
        'notificationsEnabled': notificationsEnabled,
        'polarDeviceId': polarDeviceId,
      };

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
        age: json['age'] as int? ?? 40,
        hrRest: json['hrRest'] as int?,
        hrMaxOverride: json['hrMaxOverride'] as int?,
        useKarvonen: json['useKarvonen'] as bool? ?? true,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        polarDeviceId: json['polarDeviceId'] as String?,
      );

  int get hrMax => hrMaxOverride ?? (220 - age);

  int calculateHrPercent(int currentHr) {
    if (useKarvonen && hrRest != null) {
      // Karvonen formula
      final reserve = hrMax - hrRest!;
      if (reserve <= 0) return 0;
      return (((currentHr - hrRest!) / reserve) * 100).round().clamp(0, 120);
    } else {
      // Simple formula
      return ((currentHr / hrMax) * 100).round().clamp(0, 120);
    }
  }

  HrZone getZone(int percent) {
    if (percent < 50) return HrZone.recovery;
    if (percent < 60) return HrZone.fatBurn;
    if (percent < 70) return HrZone.endurance;
    if (percent < 80) return HrZone.cardio;
    if (percent < 90) return HrZone.threshold;
    return HrZone.redZone;
  }
}
