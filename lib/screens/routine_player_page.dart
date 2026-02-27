import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/polar_service.dart';
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

  // Track expanded sections in preview
  final Map<int, bool> _expandedSections = {};

  // Animation for heart
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
      
      // Record HR to session
      if (_sessionId != null) {
        _storage.addHrPoint(_sessionId!, hr);
      }
    });
  }

  Future<void> _enableWakelock() async {
    await WakelockPlus.enable();
  }

  Future<void> _disableWakelock() async {
    await WakelockPlus.disable();
  }

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
    // Create session
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

      setState(() {
        _currentTime--;
      });

      final exercise = _getCurrentExercise();
      if (exercise == null) return;

      // Check for bilateral mid-point
      if (exercise.isBilateral && _currentTime == exercise.midPoint) {
        _playSound('mid');
      }

      // Check for HIIT rest announcement (at 20 seconds for 60s exercises in section 0)
      if (_currentSectionIndex == 0 &&
          exercise.duration == 60 &&
          _currentTime == 20) {
        _playSound('rest');
      }

      // Check for completion
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
    if (exercise != null) {
      exercise.isCompleted = true;
    }
  }

  void _moveToNextExercise() {
    final sections = widget.sections;
    final currentSection = sections[_currentSectionIndex];

    if (_currentExerciseIndex < currentSection.exercises.length - 1) {
      // Next exercise in same section
      setState(() {
        _currentExerciseIndex++;
      });
      _startExercise();
    } else if (_currentSectionIndex < sections.length - 1) {
      // Next section
      setState(() {
        _currentSectionIndex++;
        _currentExerciseIndex = 0;
      });
      _announceSection();
      _startExercise();
    } else {
      // Routine complete
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
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _tts.speak("Pause");
    } else {
      _tts.speak("Reprise");
    }
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

    if (mounted) {
      Navigator.pop(context);
    }
  }

  // ============ TTS & SOUNDS ============

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

  // ============ HELPERS ============

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

  int get _totalExercises {
    return widget.sections.fold(0, (sum, s) => sum + s.exercises.length);
  }

  int get _completedExercises {
    return widget.sections.fold(
      0,
      (sum, s) => sum + s.exercises.where((e) => e.isCompleted).length,
    );
  }

  // ============ HR DISPLAY ============

  Widget _buildHrDisplay() {
    if (_currentHr == null || _settings == null) {
      // Show placeholder when not connected
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              color: Colors.grey.withOpacity(0.5),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'H10 non connecté',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final percent = _settings!.calculateHrPercent(_currentHr!);
    final zone = _settings!.getZone(percent);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            zone.color.withOpacity(0.3),
            zone.color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: zone.color.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: zone.color.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated heart icon
          AnimatedBuilder(
            animation: _heartAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _heartAnimation.value,
                child: Icon(
                  Icons.favorite,
                  color: zone.color,
                  size: 24,
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          // BPM value (large)
          Text(
            '$_currentHr',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'bpm',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  color: zone.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Zone badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: zone.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              zone.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.primaryColor.withOpacity(0.8),
              widget.primaryColor,
              widget.primaryColor.withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: _isCompleted
              ? _buildCompletionScreen()
              : _isRunning
                  ? _buildPlayerScreen()
                  : _buildStartScreen(),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  widget.routineTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // HR Display (always show, connected or not)
          Center(child: _buildHrDisplay()),
          const SizedBox(height: 20),

          // Sections overview
          Expanded(
            child: ListView.builder(
              itemCount: widget.sections.length,
              itemBuilder: (context, index) {
                final section = widget.sections[index];
                return _buildSectionCard(section, index);
              },
            ),
          ),

          // Start button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _startRoutine,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: widget.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                '▶️ DÉMARRER',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Section header (tappable)
          InkWell(
            onTap: () {
              setState(() {
                _expandedSections[index] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    section.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${section.exercises.length} exercices • ~$minutes min',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.chevron_right,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Exercise list (expandable)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      children: [
                        Divider(color: Colors.white.withOpacity(0.15), height: 1),
                        const SizedBox(height: 8),
                        ...section.exercises.map((exercise) =>
                            _buildExercisePreviewItem(exercise)),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisePreviewItem(Exercise exercise) {
    final duration = exercise.duration;
    final mins = duration ~/ 60;
    final secs = duration % 60;
    final durationText = mins > 0
        ? (secs > 0 ? '${mins}m${secs}s' : '${mins}m')
        : '${secs}s';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exercise.icon, style: const TextStyle(fontSize: 22)),
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
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (exercise.isBilateral)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Bilatéral',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$durationText — ${exercise.description}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                if (exercise.instructions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ...exercise.instructions.map((i) => Text(
                        '• $i',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                        ),
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

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Header with section info
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => _showExitConfirmation(),
              ),
              Expanded(
                child: Text(
                  '${section.emoji} ${section.title}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),

          // Progress bar
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 6,
            ),
          ),
          Text(
            '$_completedExercises / $_totalExercises exercices',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),

          // HR Display
          const SizedBox(height: 16),
          _buildHrDisplay(),

          const Spacer(),

          // Exercise icon
          Text(
            exercise.icon,
            style: const TextStyle(fontSize: 80),
          ),

          // Exercise title
          const SizedBox(height: 16),
          Text(
            exercise.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          // Exercise description
          Text(
            exercise.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),

          const SizedBox(height: 24),

          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatTime(_currentTime),
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'monospace',
              ),
            ),
          ),

          // Bilateral indicator
          if (exercise.isBilateral) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🔔 Change de côté à mi-parcours',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],

          const Spacer(),

          // Instructions
          if (exercise.instructions.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: exercise.instructions
                    .map((i) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $i',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Skip button
              IconButton(
                onPressed: _skipExercise,
                icon: const Icon(Icons.skip_next, size: 32),
                color: Colors.white.withOpacity(0.7),
              ),

              // Pause/Play button
              GestureDetector(
                onTap: _togglePause,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPaused ? Icons.play_arrow : Icons.pause,
                    size: 40,
                    color: widget.primaryColor,
                  ),
                ),
              ),

              // Placeholder for symmetry
              const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    // Get session to show HR stats
    final session = _sessionId != null ? _storage.getSession(_sessionId!) : null;
    final avgHr = session?.averageHr;
    final hrCount = session?.hrTrace.length ?? 0;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🎉',
            style: TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 24),
          const Text(
            'Bravo !',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Routine terminée avec succès',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 40),

          // Stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildStatRow('📊 Exercices', '$_totalExercises complétés'),
                const Divider(color: Colors.white24),
                _buildStatRow(
                  '⏱️ Durée',
                  '${widget.sections.fold<int>(0, (s, sec) => s + sec.totalDuration) ~/ 60} min',
                ),
                if (avgHr != null) ...[
                  const Divider(color: Colors.white24),
                  _buildStatRow('❤️ FC moyenne', '$avgHr bpm'),
                ],
                if (hrCount > 0) ...[
                  const Divider(color: Colors.white24),
                  _buildStatRow('📈 Échantillons HR', '$hrCount points'),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // View details button (if HR data available)
          if (session != null && hrCount > 0) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionDetailPage(session: session),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.analytics_outlined, color: Colors.white),
                label: const Text(
                  'Voir les détails HR',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Return button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: widget.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Retour à l\'accueil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter la routine ?'),
        content: const Text(
          'Ta progression sera enregistrée comme incomplète.',
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }
}
