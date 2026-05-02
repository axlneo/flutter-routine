import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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
import '../services/firebase_sync_service.dart';
import '../theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final PolarService _polar = PolarService();
  final StepService _steps = StepService();
  final StorageService _storage = StorageService();
  final FirebaseSyncService _sync = FirebaseSyncService();
  static const int _stepGoal = 10000;
  static const int _cardioGoal = 5;
  bool _waitingForHealthConnectReturn = false;
  bool _isSyncing = false;

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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 17) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroDashboard(),
              const SizedBox(height: 16),

              // Navigation cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.0,
                  children: [
                    _ImageCard(
                      imageUrl:
                          'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400&h=400&fit=crop',
                      title: 'Routine Matin',
                      subtitle: '20 min',
                      fallbackColors: const [Color(0xFFFFB088), Color(0xFFFF8E53)],
                      onTap: () => _showH10Dialog(
                        context,
                        onProceed: () => _startMorningRoutine(context),
                      ),
                    ),
                    _ImageCard(
                      imageUrl:
                          'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=400&h=400&fit=crop',
                      title: 'Routine Soir',
                      subtitle: '40 min',
                      fallbackColors: const [Color(0xFF8E94B5), Color(0xFF4E54C8)],
                      onTap: () => _showH10Dialog(
                        context,
                        onProceed: () => _openDaySelector(context),
                      ),
                    ),
                    _ImageCard(
                      imageUrl:
                          'https://images.unsplash.com/photo-1506784983877-45594efa4cbe?w=400&h=400&fit=crop',
                      title: 'Semaine',
                      subtitle: 'Calendrier',
                      fallbackColors: const [Color(0xFF7BD0C7), Color(0xFF11998E)],
                      onTap: () => _openCalendar(context),
                    ),
                    _ImageCard(
                      imageUrl:
                          'https://images.unsplash.com/photo-1505576399279-0d754f0d8b19?w=400&h=400&fit=crop',
                      title: 'Planning & Médocs',
                      subtitle: 'Paramètres',
                      fallbackColors: const [Color(0xFFFAA0BE), Color(0xFFF857A6)],
                      onTap: () => _openSettings(context),
                    ),
                  ],
                ),
              ),

              const Center(
                child: Text(
                  'Reste constant, les résultats suivront.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ HERO DASHBOARD (noir, style Polar) ============

  Widget _buildHeroDashboard() {
    final today = DateTime.now();
    final dateLabel = DateFormat('EEEE d MMMM', 'fr_FR').format(today);
    final dateCap = dateLabel[0].toUpperCase() + dateLabel.substring(1);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.polarBlack,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row : date + greeting + status pills
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateCap,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textOnDarkMuted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textOnDark,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildPolarBadge(),
                  const SizedBox(height: 6),
                  _buildCloudBadge(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // KPIs : pas | cardio
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _buildStepKpi()),
                Container(width: 1, color: AppColors.polarBlackSurface),
                Expanded(child: _buildCardioKpi()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ BADGES (sur fond noir) ============

  Widget _buildPolarBadge() {
    return StreamBuilder<PolarConnectionState>(
      stream: _polar.connectionStateStream,
      builder: (context, snapshot) {
        final isConnected = _polar.isConnected;
        return _DarkPill(
          icon: isConnected ? Icons.favorite : Icons.favorite_border,
          label: isConnected ? 'H10' : 'H10',
          dotColor: isConnected ? AppColors.heart : AppColors.textOnDarkMuted,
          onTap: _openPolarConnect,
        );
      },
    );
  }

  // ============ KPIs ============

  Widget _buildStepKpi() {
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
            final goalReached = progress >= 1.0;

            return GestureDetector(
              onTap: () => _onStepBannerTap(status, hasData),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_walk, size: 14, color: AppColors.textOnDarkMuted),
                        const SizedBox(width: 4),
                        const Text(
                          'PAS',
                          style: TextStyle(
                            color: AppColors.textOnDarkMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const Spacer(),
                        if (hasData)
                          Text(
                            '$percent%',
                            style: TextStyle(
                              color: goalReached ? AppColors.heart : AppColors.textOnDarkMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasData ? formatter.format(steps) : '—',
                      style: const TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: hasData ? progress : 0,
                        minHeight: 4,
                        backgroundColor: AppColors.polarBlackSurface,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          goalReached ? AppColors.heart : AppColors.textOnDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasData
                          ? '/ $_stepGoal pas'
                          : (status == StepStatus.healthConnectUnavailable
                              ? 'Health Connect requis'
                              : 'Activer le compteur'),
                      style: const TextStyle(
                        color: AppColors.textOnDarkMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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

  Widget _buildCardioKpi() {
    final today = DateTime.now();
    final done = _storage.isCardioCompletedOnDate(today);
    final weekCount = _storage.getWeeklyCardioCount(today);
    final goalReached = weekCount >= _cardioGoal;
    final accent = goalReached ? AppColors.success : AppColors.heart;

    return GestureDetector(
      onTap: () async {
        await _storage.setCardioCompleted(today, !done);
        setState(() {});
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, size: 14, color: accent),
                const SizedBox(width: 4),
                const Text(
                  'CARDIO',
                  style: TextStyle(
                    color: AppColors.textOnDarkMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                if (done)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.heart,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$weekCount',
                  style: const TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    height: 1.0,
                  ),
                ),
                Text(
                  '/$_cardioGoal',
                  style: const TextStyle(
                    color: AppColors.textOnDarkMuted,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final monday = today.subtract(Duration(days: today.weekday - 1));
                final day = monday.add(Duration(days: i));
                final filled = _storage.isCardioCompletedOnDate(day);
                const dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                final isToday = day.day == today.day &&
                    day.month == today.month &&
                    day.year == today.year;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: filled ? accent : AppColors.polarBlackSurface,
                        shape: BoxShape.circle,
                        border: filled || !isToday
                            ? null
                            : Border.all(color: AppColors.textOnDarkMuted, width: 1),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dayLabels[i],
                      style: TextStyle(
                        color: isToday ? AppColors.textOnDark : AppColors.textOnDarkMuted,
                        fontSize: 9,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                      ),
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
      final error = await _steps.requestPermissions();
      if (error == null) {
        await _steps.refreshSteps();
      } else if (mounted) {
        _showHealthConnectHelpDialog();
      }
    }
  }

  void _showHealthConnectHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.directions_walk, color: AppColors.action),
            SizedBox(width: 12),
            Text('Compteur de pas'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'L\'autorisation automatique ne fonctionne pas sur ce téléphone.\n\n'
              'Pour activer le compteur de pas :',
              style: TextStyle(color: AppColors.textSecondary),
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
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _waitingForHealthConnectReturn = true;
              _steps.openHealthConnectSettings();
            },
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
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.action,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
        ],
      ),
    );
  }

  void _showH10Dialog(BuildContext context, {required VoidCallback onProceed}) {
    if (_polar.isConnected) {
      onProceed();
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.heartSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite, color: AppColors.heart, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Polar H10'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Veux-tu connecter ta ceinture Polar H10 pour enregistrer ta fréquence cardiaque ?',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.infoSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tu pourras voir ton HR en temps réel et revoir les données après.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
            child: const Text('Sans H10'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _openPolarConnectThenProceed(onProceed);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.heart),
            icon: const Icon(Icons.bluetooth, size: 18),
            label: const Text('Connecter H10'),
          ),
        ],
      ),
    );
  }

  // ============ CLOUD BACKUP ============

  Widget _buildCloudBadge() {
    return StreamBuilder<User?>(
      stream: _sync.authStateChanges,
      builder: (context, snapshot) {
        final isSignedIn = _sync.isSignedIn;
        return _DarkPill(
          icon: isSignedIn ? Icons.cloud_done : Icons.cloud_off,
          label: isSignedIn ? (_isSyncing ? 'Sync' : 'Cloud') : 'Local',
          dotColor: isSignedIn ? AppColors.success : AppColors.textOnDarkMuted,
          onTap: _showCloudDialog,
        );
      },
    );
  }

  void _showCloudDialog() {
    final isSignedIn = _sync.isSignedIn;
    final user = _sync.currentUser;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSignedIn ? Icons.cloud_done : Icons.cloud_off,
              color: isSignedIn ? AppColors.info : AppColors.textTertiary,
            ),
            const SizedBox(width: 12),
            const Text('Sauvegarde Cloud'),
          ],
        ),
        content: isSignedIn
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Connecté',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _handleBackup();
                          },
                          icon: const Icon(Icons.cloud_upload, size: 18),
                          label: const Text('Sauvegarder'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _handleRestore();
                          },
                          icon: const Icon(Icons.cloud_download, size: 18),
                          label: const Text('Restaurer'),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : const Text(
                'Connecte-toi avec Google pour sauvegarder tes données dans le cloud.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
        actions: [
          if (isSignedIn) ...[
            TextButton(
              onPressed: () async {
                await _sync.signOut();
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text(
                'Déconnecter',
                style: TextStyle(color: AppColors.heart, fontSize: 13),
              ),
            ),
          ] else ...[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await _handleSignIn();
              },
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Connexion Google'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleSignIn() async {
    try {
      await _sync.signInWithGoogle();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de connexion : $e')),
        );
      }
    }
  }

  Future<void> _handleBackup() async {
    setState(() => _isSyncing = true);
    try {
      final count = await _sync.backup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sauvegarde terminée ($count documents)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _handleRestore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurer la sauvegarde ?'),
        content: const Text(
          'Toutes les données locales seront remplacées par la sauvegarde cloud.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.heart),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSyncing = true);
    try {
      final count = await _sync.restore();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restauration terminée ($count documents)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _openPolarConnect() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PolarConnectPage()),
    );
  }

  void _openPolarConnectThenProceed(VoidCallback onProceed) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PolarConnectPage(onConnected: () {}, onSkipped: () {}),
      ),
    );
    if (mounted) onProceed();
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
          primaryColor: AppColors.action,
        ),
      ),
    );
  }

  void _openDaySelector(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const DaySelectorPage()));
  }

  void _openCalendar(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const WeekCalendarPage()));
  }

  void _openSettings(BuildContext context) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
    if (mounted) setState(() {});
  }
}

/// Pill statut sur fond noir (hero dashboard) — dot coloré + label compact.
class _DarkPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color dotColor;
  final VoidCallback onTap;
  const _DarkPill({
    required this.icon,
    required this.label,
    required this.dotColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.polarBlackSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Icon(icon, size: 12, color: AppColors.textOnDark),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textOnDark,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final List<Color> fallbackColors;
  final VoidCallback onTap;

  const _ImageCard({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.fallbackColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
        ),
        child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: fallbackColors,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: fallbackColors,
                  ),
                ),
              ),
            ),
            // Overlay sombre en bas pour lisibilité du texte
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
