import 'package:flutter/material.dart';
import 'day_selector_page.dart';
import 'routine_player_page.dart';
import 'week_calendar_page.dart';
import 'settings_page.dart';
import 'polar_connect_page.dart';
import '../models/models.dart';
import '../data/morning_routine.dart';
import '../services/polar_service.dart';
import '../services/step_service.dart';
import '../services/storage_service.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final PolarService _polar = PolarService();
  final StepService _steps = StepService();
  final StorageService _storage = StorageService();
  static const int _stepGoal = 10000;
  static const int _cardioGoal = 5;
  bool _waitingForHealthConnectReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForHealthConnectReturn) {
      _waitingForHealthConnectReturn = false;
      _steps.recheckAfterSettings();
    }
  }

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
                const SizedBox(height: 20),

                // Step counter banner
                _buildStepBanner(),

                const SizedBox(height: 12),

                // Cardio counter banner
                _buildCardioBanner(),

                const SizedBox(height: 20),

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

  Widget _buildStepBanner() {
    // Listen to both status and steps streams
    return StreamBuilder<StepStatus>(
      stream: _steps.statusStream,
      initialData: _steps.status,
      builder: (context, statusSnap) {
        final status = statusSnap.data ?? StepStatus.noPermission;

        return StreamBuilder<int>(
          stream: _steps.stepsStream,
          initialData: _steps.todaySteps,
          builder: (context, stepsSnap) {
            final steps = stepsSnap.data;
            final hasData = status == StepStatus.ready && steps != null && steps > 0;
            final progress = hasData ? (steps / _stepGoal).clamp(0.0, 1.0) : 0.0;
            final percent = (progress * 100).toInt();
            final formatter = NumberFormat('#,###', 'fr_FR');

            return GestureDetector(
              onTap: () => _onStepBannerTap(status, hasData),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: hasData
                    ? Row(
                        children: [
                          const Text('\u{1F6B6}', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Text(
                            '${formatter.format(steps)} pas',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 10,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress >= 1.0
                                      ? Colors.greenAccent
                                      : Colors.deepPurpleAccent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$percent%',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            status == StepStatus.healthConnectUnavailable
                                ? Icons.download
                                : Icons.directions_walk,
                            color: Colors.white.withOpacity(0.3),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              status == StepStatus.healthConnectUnavailable
                                  ? 'Installer Health Connect pour les pas'
                                  : 'Taper pour activer le compteur de pas',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCardioBanner() {
    final today = DateTime.now();
    final done = _storage.isCardioCompletedOnDate(today);
    final weekCount = _storage.getWeeklyCardioCount(today);
    final goalReached = weekCount >= _cardioGoal;

    return GestureDetector(
      onTap: () async {
        await _storage.setCardioCompleted(today, !done);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: goalReached
                ? Colors.greenAccent.withOpacity(0.4)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  goalReached ? '\u{1F3C6}' : '\u{1F3C3}',
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    goalReached
                        ? 'Objectif cardio atteint !'
                        : 'Cardio : $weekCount/$_cardioGoal cette semaine',
                    style: TextStyle(
                      color: goalReached ? Colors.greenAccent : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: done
                        ? Colors.greenAccent.withOpacity(0.2)
                        : Colors.deepPurpleAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: done
                          ? Colors.greenAccent.withOpacity(0.5)
                          : Colors.deepPurpleAccent.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    done ? 'Fait \u2713' : 'Fait ?',
                    style: TextStyle(
                      color: done ? Colors.greenAccent : Colors.deepPurpleAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) {
                final monday = today.subtract(Duration(days: today.weekday - 1));
                final day = monday.add(Duration(days: i));
                final filled = _storage.isCardioCompletedOnDate(day);
                const dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                final isToday = day.day == today.day &&
                    day.month == today.month &&
                    day.year == today.year;
                return Column(
                  children: [
                    Text(
                      dayLabels[i],
                      style: TextStyle(
                        color: isToday
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      filled ? Icons.circle : Icons.circle_outlined,
                      size: 14,
                      color: filled
                          ? (goalReached ? Colors.greenAccent : Colors.deepPurpleAccent)
                          : Colors.white.withOpacity(0.15),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onStepBannerTap(StepStatus status, bool hasData) async {
    if (status == StepStatus.healthConnectUnavailable) {
      _waitingForHealthConnectReturn = true;
      await _steps.installHealthConnect();
    } else if (hasData) {
      await _steps.refreshSteps();
    } else {
      // Try the standard permission flow first
      final error = await _steps.requestPermissions();
      if (error == null) {
        await _steps.refreshSteps();
      } else if (mounted) {
        // Standard flow failed (MIUI etc.) — show manual instructions
        _showHealthConnectHelpDialog();
      }
    }
  }

  void _showHealthConnectHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.directions_walk, color: Colors.deepPurpleAccent),
            SizedBox(width: 12),
            Text(
              'Compteur de pas',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'L\'autorisation automatique ne fonctionne pas sur ce tel.\n\n'
              'Pour activer le compteur de pas :',
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 12),
            _helpStep('1', 'Ouvrir Health Connect'),
            _helpStep('2', 'Autorisations des applis'),
            _helpStep('3', 'Routine'),
            _helpStep('4', 'Activer "Pas"'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _waitingForHealthConnectReturn = true;
              _steps.openHealthConnectSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Ouvrir Health Connect'),
          ),
        ],
      ),
    );
  }

  Widget _helpStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.deepPurpleAccent.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.deepPurpleAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
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

  void _openSettings(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsPage(),
      ),
    );
    if (mounted) setState(() {});
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
