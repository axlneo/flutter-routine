import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';
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
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppHeader(title: 'Vue Semaine', subtitle: 'Calendrier'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: TableCalendar(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                availableCalendarFormats: const {
                  CalendarFormat.week: 'Semaine',
                  CalendarFormat.twoWeeks: '2 Sem.',
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
                  setState(() => _calendarFormat = format);
                },
                onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) => _buildDayMarkers(day),
                ),
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: AppColors.polarBlack,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  defaultTextStyle: TextStyle(color: AppColors.textPrimary),
                  weekendTextStyle: TextStyle(color: AppColors.textSecondary),
                  outsideTextStyle: TextStyle(color: AppColors.textTertiary),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonShowsNext: false,
                  formatButtonTextStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  formatButtonDecoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  titleTextStyle: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textSecondary),
                  rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w700, fontSize: 12),
                  weekendStyle: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legendItem(AppColors.warning, 'Matin'),
                _legendItem(AppColors.action, 'Soir'),
                _legendItem(AppColors.success, 'Médocs'),
                _legendItem(AppColors.heart, 'Cardio'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(child: _buildDayDetails()),
        ],
      ),
    );
  }

  Widget _buildDayMarkers(DateTime day) {
    final markers = _storage.getMarkersForDate(day);
    if (!markers.values.any((v) => v)) return const SizedBox.shrink();

    return Positioned(
      bottom: 2,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (markers['morningRoutine'] == true) _markerDot(AppColors.warning),
          if (markers['eveningRoutine'] == true) _markerDot(AppColors.action),
          if (markers['morningMeds'] == true || markers['eveningMeds'] == true)
            _markerDot(AppColors.success),
          if (markers['cardio'] == true) _markerDot(AppColors.heart),
        ],
      ),
    );
  }

  Widget _markerDot(Color color) => Container(
        width: 5,
        height: 5,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
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
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateStr.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SectionHeader('Routines'),
                _routineItem(
                  '🌅 Routine Matin',
                  markers['morningRoutine'] == true,
                  sessions.where((s) => s.routineId == 'morning').toList(),
                ),
                const SizedBox(height: 8),
                _routineItem(
                  '🌙 Routine Soir',
                  markers['eveningRoutine'] == true,
                  sessions.where((s) => s.routineId == 'evening').toList(),
                ),
                const SizedBox(height: 18),
                const SectionHeader('Médicaments'),
                _medItem('Matin (7h)', markers['morningMeds'] == true, StorageService.morningMeds),
                const SizedBox(height: 8),
                _medItem('Soir (19h)', markers['eveningMeds'] == true, _storage.getEveningMeds(_selectedDay)),
                const SizedBox(height: 18),
                const SectionHeader('Cardio'),
                _cardioItem(markers['cardio'] == true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _routineItem(String title, bool completed, List<SessionRecord> sessions) {
    final SessionRecord? session = sessions.isNotEmpty ? sessions.first : null;
    return AppCard(
      onTap: session != null
          ? () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SessionDetailPage(session: session)),
              )
          : null,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completed ? AppColors.success : AppColors.textTertiary,
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
                    color: completed ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (session != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${session.durationMinutes} min',
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                      ),
                      if (session.averageHr != null) ...[
                        const Text(' • ', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                        const Icon(Icons.favorite, size: 11, color: AppColors.heart),
                        const SizedBox(width: 2),
                        Text(
                          '${session.averageHr} bpm',
                          style: const TextStyle(color: AppColors.heart, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                      if (session.hrTrace.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.show_chart, size: 13, color: AppColors.info),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (session != null)
            const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
        ],
      ),
    );
  }

  Widget _medItem(String title, bool taken, List<String> meds) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                taken ? Icons.check_circle : Icons.radio_button_unchecked,
                color: taken ? AppColors.success : AppColors.textTertiary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: taken ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
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
                  color: isOmega ? const Color(0xFFFFF3E0) : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  med,
                  style: TextStyle(
                    color: isOmega ? AppColors.warning : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _cardioItem(bool done) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? AppColors.heart : AppColors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            done ? 'Séance faite' : 'Pas de séance',
            style: TextStyle(
              color: done ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          if (done) const Icon(Icons.directions_run, color: AppColors.heart, size: 18),
        ],
      ),
    );
  }
}
