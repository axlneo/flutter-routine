import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/models.dart';
import 'session_detail_page.dart';

class WeekCalendarPage extends StatefulWidget {
  const WeekCalendarPage({super.key});

  @override
  State<WeekCalendarPage> createState() => _WeekCalendarPageState();
}

class _WeekCalendarPageState extends State<WeekCalendarPage> {
  final StorageService _storage = StorageService();
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      '📅 Vue Semaine',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Calendar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  availableCalendarFormats: const {
                    CalendarFormat.week: 'Semaine',
                    CalendarFormat.twoWeeks: '2 Semaines',
                    CalendarFormat.month: 'Mois',
                  },
                  locale: 'fr_FR',
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      return _buildDayMarkers(day);
                    },
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: const TextStyle(color: Colors.white),
                    weekendTextStyle: const TextStyle(color: Colors.white70),
                    outsideTextStyle: const TextStyle(color: Colors.white30),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonTextStyle: TextStyle(color: Colors.white),
                    formatButtonDecoration: BoxDecoration(
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.white54),
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    titleTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                    rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: Colors.white70),
                    weekendStyle: TextStyle(color: Colors.white54),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Legend
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem(Colors.orange, 'Matin'),
                    _buildLegendItem(Colors.indigo, 'Soir'),
                    _buildLegendItem(Colors.green, 'Médocs'),
                    _buildLegendItem(Colors.redAccent, 'Cardio'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Selected day details
              Expanded(
                child: _buildDayDetails(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayMarkers(DateTime day) {
    final markers = _storage.getMarkersForDate(day);
    final hasAnyMarker = markers.values.any((v) => v);

    if (!hasAnyMarker) return const SizedBox.shrink();

    return Positioned(
      bottom: 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (markers['morningRoutine'] == true)
            _buildMarkerDot(Colors.orange),
          if (markers['eveningRoutine'] == true)
            _buildMarkerDot(Colors.indigo),
          if (markers['morningMeds'] == true || markers['eveningMeds'] == true)
            _buildMarkerDot(Colors.green),
          if (markers['cardio'] == true)
            _buildMarkerDot(Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildMarkerDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildDayDetails() {
    final dateStr = DateFormat('EEEE d MMMM', 'fr_FR').format(_selectedDay);
    final markers = _storage.getMarkersForDate(_selectedDay);
    final sessions = _storage.getSessionsForDate(_selectedDay);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Text(
            dateStr.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: ListView(
              children: [
                // Routines section
                _buildSectionTitle('🏋️ Routines'),
                _buildRoutineItem(
                  '🌅 Routine Matin',
                  markers['morningRoutine'] == true,
                  sessions.where((s) => s.routineId == 'morning').toList(),
                ),
                _buildRoutineItem(
                  '🌙 Routine Soir',
                  markers['eveningRoutine'] == true,
                  sessions.where((s) => s.routineId == 'evening').toList(),
                ),

                const SizedBox(height: 20),

                // Medications section
                _buildSectionTitle('💊 Médicaments'),
                _buildMedItem(
                  'Matin (7h)',
                  markers['morningMeds'] == true,
                  StorageService.morningMeds,
                ),
                _buildMedItem(
                  'Soir (19h)',
                  markers['eveningMeds'] == true,
                  _storage.getEveningMeds(_selectedDay),
                ),

                const SizedBox(height: 20),

                // Cardio section
                _buildSectionTitle('🏃 Cardio'),
                _buildCardioItem(markers['cardio'] == true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRoutineItem(String title, bool completed, List<SessionRecord> sessions) {
    SessionRecord? session = sessions.isNotEmpty ? sessions.first : null;

    return GestureDetector(
      onTap: session != null
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SessionDetailPage(session: session),
                ),
              )
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: completed
              ? Colors.green.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: completed
                ? Colors.green.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              completed ? Icons.check_circle : Icons.circle_outlined,
              color: completed ? Colors.green : Colors.white30,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(completed ? 1 : 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (session != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${session.durationMinutes} min',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                        if (session.averageHr != null) ...[
                          Text(
                            ' • ❤️ ${session.averageHr} bpm',
                            style: TextStyle(
                              color: Colors.red.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (session.hrTrace.isNotEmpty) ...[
                          Text(
                            ' • 📊',
                            style: TextStyle(
                              color: Colors.blue.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (session != null) ...[
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
            ] else if (completed) ...[
              Text(
                '✅',
                style: TextStyle(
                  color: Colors.green.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedItem(String title, bool taken, List<String> meds) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: taken
            ? Colors.green.withOpacity(0.2)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: taken
              ? Colors.green.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                taken ? Icons.check_circle : Icons.circle_outlined,
                color: taken ? Colors.green : Colors.white30,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(taken ? 1 : 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (taken)
                const Text('✅'),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: meds.map((med) {
              final isOmega = med.contains('Oméga');
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOmega
                      ? Colors.amber.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  med,
                  style: TextStyle(
                    color: isOmega ? Colors.amber : Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCardioItem(bool done) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: done
            ? Colors.redAccent.withOpacity(0.2)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done
              ? Colors.redAccent.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.circle_outlined,
            color: done ? Colors.redAccent : Colors.white30,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            done ? 'Séance faite' : 'Pas de séance',
            style: TextStyle(
              color: Colors.white.withOpacity(done ? 1 : 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (done) const Text('\u{1F3C3}'),
        ],
      ),
    );
  }
}
