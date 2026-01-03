import 'package:flutter/material.dart';
import 'routine_player_page.dart';
import '../models/models.dart';
import '../data/evening_routine.dart';

class DaySelectorPage extends StatelessWidget {
  const DaySelectorPage({super.key});

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
                    const SizedBox(width: 8),
                    const Text(
                      '🌙 Routine du Soir',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Choisis ton jour pour adapter le renforcement',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Day cards
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: dayThemes.length,
                  itemBuilder: (context, index) {
                    final day = dayThemes[index];
                    return _DayCard(
                      dayNumber: index + 1,
                      dayName: day['day']!,
                      theme: day['theme']!,
                      emoji: day['emoji']!,
                      onTap: () => _startEveningRoutine(context, index + 1),
                    );
                  },
                ),
              ),

              // Footer info
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Structure identique chaque soir',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'HIIT (10 min) + Renfo (20 min) + Stretch (10 min)',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startEveningRoutine(BuildContext context, int day) {
    final sections = buildEveningSections(day);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutinePlayerPage(
          routineType: RoutineType.evening,
          sections: sections,
          routineTitle: 'Routine du Soir - ${dayNames[day - 1]}',
          primaryColor: Colors.indigo,
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
    // Check if today
    final today = DateTime.now().weekday;
    final isToday = dayNumber == today;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isToday
                  ? [const Color(0xFF4E54C8), const Color(0xFF8F94FB)]
                  : [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: isToday
                ? null
                : Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Day number
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isToday
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Day info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          dayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Aujourd\'hui',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$emoji $theme',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
