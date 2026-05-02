import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/polar_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';
import 'session_detail_page.dart';

class RoutinePlayerPage extends StatefulWidget {
  final RoutineType routineType;
  final List<Section> sections;
  final String routineTitle;
  final Color primaryColor;
  final int? eveningDay;

  const RoutinePlayerPage({
    super.key,
    required this.routineType,
    required this.sections,
    required this.routineTitle,
    required this.primaryColor,
    this.eveningDay,
  });

  @override
  State<RoutinePlayerPage> createState() => _RoutinePlayerPageState();
}

class _RoutinePlayerPageState extends State<RoutinePlayerPage>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _currentTime = 0;
  int _currentSectionIndex = 0;
  int _currentExerciseIndex = 0;
  bool _isPaused = false;
  bool _isRunning = false;
  bool _isCompleted = false;

  final FlutterTts _tts = FlutterTts();
  final StorageService _storage = StorageService();
  final PolarService _polar = PolarService();

  String? _sessionId;
  StreamSubscription<int>? _hrSubscription;
  int? _currentHr;
  UserSettings? _settings;

  final Map<int, bool> _expandedSections = {};

  late AnimationController _heartAnimController;
  late Animation<double> _heartAnimation;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadSettings();
    _subscribeToHr();
    _enableWakelock();
    _setupAnimations();
  }

  void _setupAnimations() {
    _heartAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _heartAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _heartAnimController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("fr-FR");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  void _loadSettings() {
    _settings = _storage.settings;
  }

  void _subscribeToHr() {
    _hrSubscription = _polar.hrStream.listen((hr) {
      setState(() => _currentHr = hr);
      if (_sessionId != null) {
        _storage.addHrPoint(_sessionId!, hr);
      }
    });
  }

  Future<void> _enableWakelock() async => WakelockPlus.enable();
  Future<void> _disableWakelock() async => WakelockPlus.disable();

  @override
  void dispose() {
    _timer?.cancel();
    _hrSubscription?.cancel();
    _heartAnimController.dispose();
    _disableWakelock();
    _tts.stop();
    super.dispose();
  }

  // ============ ROUTINE LOGIC ============

  void _startRoutine() async {
    _sessionId = await _storage.startSession(
      routineId: widget.routineType == RoutineType.morning ? 'morning' : 'evening',
      day: widget.eveningDay,
    );
    setState(() {
      _isRunning = true;
      _currentSectionIndex = 0;
      _currentExerciseIndex = 0;
    });
    _startExercise();
  }

  void _startExercise() {
    final exercise = _getCurrentExercise();
    if (exercise == null) return;
    setState(() {
      _currentTime = exercise.duration;
      _isPaused = false;
    });
    _announceExercise(exercise.title);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      setState(() => _currentTime--);

      final exercise = _getCurrentExercise();
      if (exercise == null) return;

      if (exercise.isBilateral && _currentTime == exercise.midPoint) {
        _playSound('mid');
      }
      if (_currentSectionIndex == 0 && exercise.duration == 60 && _currentTime == 20) {
        _playSound('rest');
      }
      if (_currentTime == 0) {
        _playSound('end').then((_) {
          _completeCurrentExercise();
          _moveToNextExercise();
        });
      }
    });
  }

  void _completeCurrentExercise() {
    final exercise = _getCurrentExercise();
    if (exercise != null) exercise.isCompleted = true;
  }

  void _moveToNextExercise() {
    final sections = widget.sections;
    final currentSection = sections[_currentSectionIndex];

    if (_currentExerciseIndex < currentSection.exercises.length - 1) {
      setState(() => _currentExerciseIndex++);
      _startExercise();
    } else if (_currentSectionIndex < sections.length - 1) {
      setState(() {
        _currentSectionIndex++;
        _currentExerciseIndex = 0;
      });
      _announceSection();
      _startExercise();
    } else {
      _completeRoutine();
    }
  }

  void _completeRoutine() async {
    _timer?.cancel();
    if (_sessionId != null) {
      await _storage.completeSession(_sessionId!, completed: true);
    }
    await _tts.speak("Bravo ! Routine terminée !");
    HapticFeedback.heavyImpact();
    setState(() {
      _isRunning = false;
      _isCompleted = true;
    });
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    _tts.speak(_isPaused ? "Pause" : "Reprise");
  }

  void _skipExercise() {
    _timer?.cancel();
    _completeCurrentExercise();
    _moveToNextExercise();
  }

  void _exitRoutine() async {
    _timer?.cancel();
    if (_sessionId != null) {
      await _storage.completeSession(_sessionId!, completed: false);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _playSound(String type) async {
    HapticFeedback.selectionClick();
    await _tts.stop();
    switch (type) {
      case 'mid':
        await _tts.speak("Change de côté");
        break;
      case 'rest':
        await _tts.speak("Repos");
        HapticFeedback.lightImpact();
        break;
      case 'end':
        await _tts.speak("Terminé");
        HapticFeedback.mediumImpact();
        break;
    }
  }

  Future<void> _announceExercise(String title) async {
    await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 150));
    await _tts.speak(title);
  }

  Future<void> _announceSection() async {
    final section = widget.sections[_currentSectionIndex];
    await _tts.stop();
    await _tts.speak("Section ${section.title}");
  }

  Exercise? _getCurrentExercise() {
    if (_currentSectionIndex >= widget.sections.length) return null;
    final section = widget.sections[_currentSectionIndex];
    if (_currentExerciseIndex >= section.exercises.length) return null;
    return section.exercises[_currentExerciseIndex];
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  int get _totalExercises =>
      widget.sections.fold(0, (sum, s) => sum + s.exercises.length);

  int get _completedExercises => widget.sections.fold(
        0,
        (sum, s) => sum + s.exercises.where((e) => e.isCompleted).length,
      );

  // ============ HR DISPLAYS ============

  Widget _buildHrCardLight() {
    if (_currentHr == null || _settings == null) {
      return AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const AppIconBadge(
              icon: Icons.favorite_border,
              color: AppColors.textTertiary,
              soft: AppColors.surfaceMuted,
              size: 36,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Polar H10 non connecté',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
          ],
        ),
      );
    }

    final percent = _settings!.calculateHrPercent(_currentHr!);
    final zone = _settings!.getZone(percent);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          AppIconBadge(
            icon: Icons.favorite,
            color: AppColors.heart,
            soft: AppColors.heartSoft,
            size: 36,
          ),
          const SizedBox(width: 12),
          Text(
            '$_currentHr',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'bpm',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: zone.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$percent% · ${zone.label}',
              style: TextStyle(
                color: zone.color,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHrCardDark() {
    if (_currentHr == null || _settings == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.polarBlackSurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, color: AppColors.textOnDarkMuted, size: 16),
            SizedBox(width: 8),
            Text(
              'H10 NON CONNECTÉ',
              style: TextStyle(
                color: AppColors.textOnDarkMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      );
    }

    final percent = _settings!.calculateHrPercent(_currentHr!);
    final zone = _settings!.getZone(percent);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.polarBlackSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: zone.color.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _heartAnimation,
            builder: (context, child) => Transform.scale(
              scale: _heartAnimation.value,
              child: Icon(Icons.favorite, color: zone.color, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$_currentHr',
            style: const TextStyle(
              color: AppColors.textOnDark,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              height: 1.0,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'bpm',
            style: TextStyle(color: AppColors.textOnDarkMuted, fontSize: 10, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: zone.color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$percent%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ BUILD ============

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) return _buildCompletionScreen();
    if (_isRunning) return _buildPlayerScreen();
    return _buildStartScreen();
  }

  Widget _buildStartScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(
            title: widget.routineTitle,
            subtitle: widget.routineType == RoutineType.morning ? 'Matin' : 'Soir',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                _buildHrCardLight(),
                const SizedBox(height: 20),
                const SectionHeader('Programme'),
                ...List.generate(widget.sections.length,
                    (i) => _buildSectionCard(widget.sections[i], i)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _startRoutine,
                icon: const Icon(Icons.play_arrow, size: 26),
                label: const Text(
                  'DÉMARRER',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.heart,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(Section section, int index) {
    final totalDuration = section.totalDuration;
    final minutes = totalDuration ~/ 60;
    final isExpanded = _expandedSections[index] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expandedSections[index] = !isExpanded),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: Text(section.emoji, style: const TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '${section.exercises.length} exercices · ~$minutes min',
                            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                      child: Column(
                        children: [
                          const Divider(color: AppColors.divider, height: 1),
                          const SizedBox(height: 8),
                          ...section.exercises.map(_buildExercisePreviewItem),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisePreviewItem(Exercise exercise) {
    final duration = exercise.duration;
    final mins = duration ~/ 60;
    final secs = duration % 60;
    final durationText =
        mins > 0 ? (secs > 0 ? '${mins}m${secs}s' : '${mins}m') : '${secs}s';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exercise.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        exercise.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (exercise.isBilateral)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'BILAT.',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$durationText — ${exercise.description}',
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
                if (exercise.instructions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ...exercise.instructions.map((i) => Text(
                        '• $i',
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerScreen() {
    final exercise = _getCurrentExercise();
    if (exercise == null) return const SizedBox.shrink();

    final section = widget.sections[_currentSectionIndex];
    final progress = _completedExercises / _totalExercises;

    return Scaffold(
      backgroundColor: AppColors.polarBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textOnDark),
                    onPressed: _showExitConfirmation,
                    padding: EdgeInsets.zero,
                  ),
                  Expanded(
                    child: Text(
                      '${section.emoji}  ${section.title.toUpperCase()}',
                      style: const TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.polarBlackSurface,
                  valueColor: const AlwaysStoppedAnimation(AppColors.heart),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_completedExercises / $_totalExercises',
                    style: const TextStyle(
                      color: AppColors.textOnDarkMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  _buildHrCardDark(),
                ],
              ),

              const Spacer(),

              Text(exercise.icon, style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 12),
              Text(
                exercise.title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textOnDark,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                exercise.description,
                style: const TextStyle(fontSize: 14, color: AppColors.textOnDarkMuted),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.polarBlackSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.heart, width: 2),
                ),
                child: Text(
                  _formatTime(_currentTime),
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textOnDark,
                    fontFamily: 'monospace',
                    height: 1.0,
                    letterSpacing: -2.0,
                  ),
                ),
              ),

              if (exercise.isBilateral) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'CHANGE DE CÔTÉ À MI-PARCOURS',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],

              const Spacer(),

              if (exercise.instructions.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.polarBlackSurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: exercise.instructions
                        .map((i) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• $i',
                                style: const TextStyle(color: AppColors.textOnDarkMuted, fontSize: 12),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: _skipExercise,
                    icon: const Icon(Icons.skip_next, size: 30),
                    color: AppColors.textOnDarkMuted,
                  ),
                  GestureDetector(
                    onTap: _togglePause,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        color: AppColors.heart,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0x40E40046), blurRadius: 16, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Icon(
                        _isPaused ? Icons.play_arrow : Icons.pause,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
    final session = _sessionId != null ? _storage.getSession(_sessionId!) : null;
    final avgHr = session?.averageHr;
    final hrCount = session?.hrTrace.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.polarBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.heart,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Color(0x60E40046), blurRadius: 32, spreadRadius: 4),
                  ],
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 56),
              ),
              const SizedBox(height: 28),
              const Text(
                'BRAVO',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textOnDark,
                  letterSpacing: 4.0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Routine terminée',
                style: TextStyle(fontSize: 14, color: AppColors.textOnDarkMuted, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 36),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.polarBlackSurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _statRow(Icons.fitness_center, 'Exercices', '$_totalExercises'),
                    const SizedBox(height: 14),
                    _statRow(
                      Icons.schedule,
                      'Durée',
                      '${widget.sections.fold<int>(0, (s, sec) => s + sec.totalDuration) ~/ 60} min',
                    ),
                    if (avgHr != null) ...[
                      const SizedBox(height: 14),
                      _statRow(Icons.favorite, 'FC moyenne', '$avgHr bpm', accent: AppColors.heart),
                    ],
                    if (hrCount > 0) ...[
                      const SizedBox(height: 14),
                      _statRow(Icons.show_chart, 'Échantillons HR', '$hrCount'),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (session != null && hrCount > 0) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SessionDetailPage(session: session)),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textOnDark,
                      side: const BorderSide(color: AppColors.polarBlackSurface, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('Voir les détails HR'),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.heart,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'RETOUR ACCUEIL',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(IconData icon, String label, String value, {Color? accent}) {
    return Row(
      children: [
        Icon(icon, color: accent ?? AppColors.textOnDarkMuted, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textOnDarkMuted, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: accent ?? AppColors.textOnDark,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter la routine ?'),
        content: const Text(
          'Ta progression sera enregistrée comme incomplète.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exitRoutine();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.heart),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }
}
