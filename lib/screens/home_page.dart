import 'package:flutter/material.dart';
import 'day_selector_page.dart';
import 'routine_player_page.dart';
import 'week_calendar_page.dart';
import 'settings_page.dart';
import 'polar_connect_page.dart';
import '../models/models.dart';
import '../data/morning_routine.dart';
import '../services/polar_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PolarService _polar = PolarService();

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
                // Header with Polar status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: const Text(
                        '💪 Fitness App',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Polar status indicator
                    StreamBuilder<PolarConnectionState>(
                      stream: _polar.connectionStateStream,
                      builder: (context, snapshot) {
                        final isConnected = _polar.isConnected;
                        return GestureDetector(
                          onTap: () => _openPolarConnect(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isConnected
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isConnected
                                    ? Colors.green
                                    : Colors.grey.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isConnected
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 16,
                                  color: isConnected ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isConnected ? 'H10' : 'Non connecté',
                                  style: TextStyle(
                                    color: isConnected
                                        ? Colors.green
                                        : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
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
                        onTap: () => _showH10Dialog(
                          context,
                          onProceed: () => _startMorningRoutine(context),
                        ),
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
                        onTap: () => _showH10Dialog(
                          context,
                          onProceed: () => _openDaySelector(context),
                        ),
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

  void _showH10Dialog(BuildContext context, {required VoidCallback onProceed}) {
    // If already connected, proceed directly
    if (_polar.isConnected) {
      onProceed();
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Polar H10',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Veux-tu connecter ta ceinture Polar H10 pour enregistrer ta fréquence cardiaque ?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tu pourras voir ton HR en temps réel et revoir les données après.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onProceed();
            },
            child: Text(
              'Sans H10',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _openPolarConnectThenProceed(onProceed);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.bluetooth, size: 18),
            label: const Text('Connecter H10'),
          ),
        ],
      ),
    );
  }

  void _openPolarConnect() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PolarConnectPage(),
      ),
    );
  }

  void _openPolarConnectThenProceed(VoidCallback onProceed) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PolarConnectPage(
          onConnected: () {},
          onSkipped: () {},
        ),
      ),
    );

    // Proceed regardless of connection result
    if (mounted) {
      onProceed();
    }
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
          primaryColor: Colors.deepOrange,
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
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
