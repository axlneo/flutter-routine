import 'package:flutter/material.dart';
import 'day_selector_page.dart';
import 'routine_player_page.dart';
import 'week_calendar_page.dart';
import 'settings_page.dart';
import '../models/models.dart';
import '../data/morning_routine.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  '💪 Fitness App',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Prêt pour ta routine ?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 40),

                // Navigation cards
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.0,
                    children: [
                      // Morning routine
                      _NavigationCard(
                        emoji: '🌅',
                        title: 'Routine\nMatin',
                        subtitle: '20 min',
                        gradientColors: const [
                          Color(0xFFFF6B6B),
                          Color(0xFFFF8E53),
                        ],
                        onTap: () => _startMorningRoutine(context),
                      ),

                      // Evening routine
                      _NavigationCard(
                        emoji: '🌙',
                        title: 'Routine\nSoir',
                        subtitle: '40 min',
                        gradientColors: const [
                          Color(0xFF4E54C8),
                          Color(0xFF8F94FB),
                        ],
                        onTap: () => _openDaySelector(context),
                      ),

                      // Week calendar
                      _NavigationCard(
                        emoji: '📅',
                        title: 'Semaine',
                        subtitle: 'Calendrier',
                        gradientColors: const [
                          Color(0xFF11998E),
                          Color(0xFF38EF7D),
                        ],
                        onTap: () => _openCalendar(context),
                      ),

                      // Settings & medications
                      _NavigationCard(
                        emoji: '🔔',
                        title: 'Planning &\nMédocs',
                        subtitle: 'Paramètres',
                        gradientColors: const [
                          Color(0xFFF857A6),
                          Color(0xFFFF5858),
                        ],
                        onTap: () => _openSettings(context),
                      ),
                    ],
                  ),
                ),

                // Footer
                Center(
                  child: Text(
                    'Reste constant, les résultats suivront 🔥',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startMorningRoutine(BuildContext context) {
    final sections = buildMorningSections();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutinePlayerPage(
          routineType: RoutineType.morning,
          sections: sections,
          routineTitle: 'Routine du Matin',
          primaryColor: Colors.deepPurple,
        ),
      ),
    );
  }

  void _openDaySelector(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DaySelectorPage(),
      ),
    );
  }

  void _openCalendar(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const WeekCalendarPage(),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsPage(),
      ),
    );
  }
}

class _NavigationCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _NavigationCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
