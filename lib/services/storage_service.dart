import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class StorageService {
  static const String _sessionsBox = 'sessions';
  static const String _medsBox = 'meds';
  static const String _settingsBox = 'settings';
  static const String _settingsKey = 'userSettings';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late Box<SessionRecord> _sessions;
  late Box<MedRecord> _meds;
  late Box<UserSettings> _settings;

  final _uuid = const Uuid();

  /// Initialize Hive and register adapters
  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SessionRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HrPointAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MedRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(UserSettingsAdapter());
    }

    // Open boxes
    _sessions = await Hive.openBox<SessionRecord>(_sessionsBox);
    _meds = await Hive.openBox<MedRecord>(_medsBox);
    _settings = await Hive.openBox<UserSettings>(_settingsBox);

    // Initialize default settings if needed
    if (!_settings.containsKey(_settingsKey)) {
      await _settings.put(_settingsKey, UserSettings());
    }
  }

  // ============ SETTINGS ============

  UserSettings get settings =>
      _settings.get(_settingsKey) ?? UserSettings();

  Future<void> saveSettings(UserSettings newSettings) async {
    await _settings.put(_settingsKey, newSettings);
  }

  // ============ SESSIONS ============

  /// Create a new session and return its ID
  Future<String> startSession({
    required String routineId,
    int? day,
  }) async {
    final id = _uuid.v4();
    final session = SessionRecord(
      id: id,
      tsStart: DateTime.now(),
      routineId: routineId,
      day: day,
      completed: false,
    );
    await _sessions.put(id, session);
    return id;
  }

  /// Add HR point to session
  Future<void> addHrPoint(String sessionId, int hr) async {
    final session = _sessions.get(sessionId);
    if (session != null) {
      session.hrTrace.add(HrPoint(t: DateTime.now(), hr: hr));
      await session.save();
    }
  }

  /// Complete a session
  Future<void> completeSession(String sessionId, {bool completed = true}) async {
    final session = _sessions.get(sessionId);
    if (session != null) {
      session.tsEnd = DateTime.now();
      session.completed = completed;
      await session.save();
    }
  }

  /// Get sessions for a specific date
  List<SessionRecord> getSessionsForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return _sessions.values.where((s) {
      final sessionDate = DateFormat('yyyy-MM-dd').format(s.tsStart);
      return sessionDate == dateStr;
    }).toList();
  }

  /// Get all sessions
  List<SessionRecord> getAllSessions() {
    return _sessions.values.toList();
  }

  /// Get a specific session by ID
  SessionRecord? getSession(String sessionId) {
    return _sessions.get(sessionId);
  }

  /// Check if routine was completed on date
  bool isRoutineCompletedOnDate(DateTime date, String routineId) {
    final sessions = getSessionsForDate(date);
    return sessions.any((s) => s.routineId == routineId && s.completed);
  }

  // ============ MEDICATIONS ============

  /// Morning medications list
  static const List<String> morningMeds = [
    'Ramipril',
    'Bisoprolol (matin)',
    'Metformine',
    '1 capsule Oméga-3',
    '1 gélule multivitamines',
  ];

  /// Evening medications list
  static const List<String> eveningMedsBase = [
    'Aspirine 100 mg',
    'Bisoprolol (soir)',
    'Atorvastatine + ézétimibe',
    'Metformine',
    '1 gélule multivitamines',
  ];

  /// Get evening meds for a given date
  List<String> getEveningMeds(DateTime date) {
    return List<String>.from(eveningMedsBase);
  }

  /// Get or create med record for date and slot
  MedRecord getMedRecord(DateTime date, String slot) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final key = '${dateStr}_$slot';
    
    var record = _meds.get(key);
    if (record == null) {
      final items = slot == 'morning' 
          ? morningMeds 
          : getEveningMeds(date);
      record = MedRecord(
        date: dateStr,
        slot: slot,
        items: items,
        checked: false,
      );
      _meds.put(key, record);
    }
    return record;
  }

  /// Mark medications as taken
  Future<void> setMedsTaken(DateTime date, String slot, bool taken) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final key = '${dateStr}_$slot';
    
    var record = _meds.get(key);
    if (record == null) {
      final items = slot == 'morning' 
          ? morningMeds 
          : getEveningMeds(date);
      record = MedRecord(
        date: dateStr,
        slot: slot,
        items: items,
      );
    }
    
    record.checked = taken;
    record.checkedAt = taken ? DateTime.now() : null;
    await _meds.put(key, record);
  }

  /// Check if meds were taken on date
  bool areMedsTakenOnDate(DateTime date, String slot) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final key = '${dateStr}_$slot';
    final record = _meds.get(key);
    return record?.checked ?? false;
  }

  // ============ CARDIO ============

  /// Check if cardio was done on a given date
  bool isCardioCompletedOnDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final record = _meds.get('${dateStr}_cardio');
    return record?.checked ?? false;
  }

  /// Toggle cardio completion for a given date
  Future<void> setCardioCompleted(DateTime date, bool completed) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final key = '${dateStr}_cardio';
    var record = _meds.get(key);
    if (record == null) {
      record = MedRecord(
        date: dateStr,
        slot: 'cardio',
        items: ['Cardio'],
      );
    }
    record.checked = completed;
    record.checkedAt = completed ? DateTime.now() : null;
    await _meds.put(key, record);
  }

  /// Count cardio sessions done this week (Monday → Sunday)
  int getWeeklyCardioCount(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    int count = 0;
    for (int i = 0; i < 7; i++) {
      if (isCardioCompletedOnDate(monday.add(Duration(days: i)))) count++;
    }
    return count;
  }

  // ============ CALENDAR MARKERS ============

  /// Get markers for calendar view
  Map<String, bool> getMarkersForDate(DateTime date) {
    return {
      'morningRoutine': isRoutineCompletedOnDate(date, 'morning'),
      'eveningRoutine': isRoutineCompletedOnDate(date, 'evening'),
      'morningMeds': areMedsTakenOnDate(date, 'morning'),
      'eveningMeds': areMedsTakenOnDate(date, 'evening'),
      'cardio': isCardioCompletedOnDate(date),
    };
  }
}
