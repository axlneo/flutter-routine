import 'package:flutter/material.dart';
import 'routine_player_page.dart';
import '../models/models.dart';
import '../data/evening_routine.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';

class DaySelectorPage extends StatefulWidget {
  const DaySelectorPage({super.key});

  @override
  State<DaySelectorPage> createState() => _DaySelectorPageState();
}

class _DaySelectorPageState extends State<DaySelectorPage> {
  bool _isShortRoutine = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppHeader(
            title: 'Routine du Soir',
            subtitle: 'Choisis ton jour',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                _buildModeToggle(),
                const SizedBox(height: 18),
                const SectionHeader('Jours'),
                ...List.generate(dayThemes.length, (index) {
                  final day = dayThemes[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DayCard(
                      dayNumber: index + 1,
                      dayName: day['day']!,
                      theme: day['theme']!,
                      emoji: day['emoji']!,
                      onTap: () => _startEveningRoutine(context, index + 1),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                _buildFooterInfo(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: _modeOption('Complète', '40 min', false)),
          Expanded(child: _modeOption('Réduite', '~20 min muscu', true)),
        ],
      ),
    );
  }

  Widget _modeOption(String title, String sub, bool isShort) {
    final selected = _isShortRoutine == isShort;
    return GestureDetector(
      onTap: () => setState(() => _isShortRoutine = isShort),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.polarBlack : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 1))]
              : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: selected ? AppColors.textOnDark : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              sub,
              style: TextStyle(
                color: selected ? AppColors.textOnDarkMuted : AppColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterInfo() {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          AppIconBadge(
            icon: _isShortRoutine ? Icons.bolt : Icons.local_fire_department,
            color: _isShortRoutine ? AppColors.warning : AppColors.heart,
            soft: _isShortRoutine ? const Color(0xFFFFF3E0) : AppColors.heartSoft,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isShortRoutine
                      ? 'Routine réduite muscu'
                      : 'Structure identique chaque soir',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _isShortRoutine
                      ? 'Échauffement (5 min) + Renfo (~15 min)'
                      : 'HIIT (10 min) + Renfo (20 min) + Stretch (10 min)',
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startEveningRoutine(BuildContext context, int day) {
    final sections = _isShortRoutine
        ? buildShortEveningSections(day)
        : buildEveningSections(day);
    final suffix = _isShortRoutine ? ' (Réduite)' : '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutinePlayerPage(
          routineType: RoutineType.evening,
          sections: sections,
          routineTitle: 'Routine du Soir$suffix - ${dayNames[day - 1]}',
          primaryColor: AppColors.polarBlack,
          eveningDay: day,
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final int dayNumber;
  final String dayName;
  final String theme;
  final String emoji;
  final VoidCallback onTap;

  const _DayCard({
    required this.dayNumber,
    required this.dayName,
    required this.theme,
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;
    final isToday = dayNumber == today;

    final bgColor = isToday ? AppColors.polarBlack : AppColors.surface;
    final fgColor = isToday ? AppColors.textOnDark : AppColors.textPrimary;
    final fgMuted = isToday ? AppColors.textOnDarkMuted : AppColors.textTertiary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isToday ? AppColors.heart : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$dayNumber',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isToday ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: fgColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.heart,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'AUJOURD\'HUI',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$emoji $theme',
                    style: TextStyle(fontSize: 13, color: fgMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: fgMuted, size: 22),
          ],
        ),
      ),
    );
  }
}
