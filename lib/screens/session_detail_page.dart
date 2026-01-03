import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import 'dart:math' as math;

class SessionDetailPage extends StatefulWidget {
  final SessionRecord session;

  const SessionDetailPage({
    super.key,
    required this.session,
  });

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  final StorageService _storage = StorageService();
  late UserSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = _storage.settings;
  }

  // Calculate zone distribution
  Map<HrZone, int> _calculateZoneDistribution() {
    final zones = <HrZone, int>{};
    for (final zone in HrZone.values) {
      zones[zone] = 0;
    }

    for (final point in widget.session.hrTrace) {
      final percent = _settings.calculateHrPercent(point.hr);
      final zone = _settings.getZone(percent);
      zones[zone] = (zones[zone] ?? 0) + 1;
    }

    return zones;
  }

  int? get _minHr {
    if (widget.session.hrTrace.isEmpty) return null;
    return widget.session.hrTrace.map((p) => p.hr).reduce(math.min);
  }

  int? get _maxHr {
    if (widget.session.hrTrace.isEmpty) return null;
    return widget.session.hrTrace.map((p) => p.hr).reduce(math.max);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final hasHrData = session.hrTrace.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: CustomScrollView(
        slivers: [
          // App bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1a1a2e),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats cards
                _buildStatsCards(),
                const SizedBox(height: 24),

                // HR Chart
                if (hasHrData) ...[
                  _buildSectionTitle('📈 Fréquence cardiaque'),
                  const SizedBox(height: 12),
                  _buildHrChart(),
                  const SizedBox(height: 24),

                  // Zones breakdown
                  _buildSectionTitle('🎯 Zones d\'entraînement'),
                  const SizedBox(height: 12),
                  _buildZonesBreakdown(),
                  const SizedBox(height: 24),

                  // HR Summary
                  _buildSectionTitle('📊 Résumé FC'),
                  const SizedBox(height: 12),
                  _buildHrSummary(),
                ] else ...[
                  _buildNoHrData(),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final session = widget.session;
    final isMorning = session.routineId == 'morning';
    final emoji = isMorning ? '🌅' : '🌙';
    final title = isMorning ? 'Routine Matin' : 'Routine Soir';
    final dayText = session.day != null ? ' • Jour ${session.day}' : '';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isMorning ? Colors.orange.shade700 : Colors.indigo.shade700,
            isMorning ? Colors.deepOrange.shade900 : Colors.purple.shade900,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 8),
              Text(
                '$title$dayText',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat('EEEE d MMMM yyyy • HH:mm', 'fr_FR')
                    .format(session.tsStart),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final session = widget.session;
    final duration = session.durationMinutes;
    final avgHr = session.averageHr;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: '⏱️',
            label: 'Durée',
            value: '$duration min',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: '❤️',
            label: 'FC moyenne',
            value: avgHr != null ? '$avgHr bpm' : '--',
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: session.completed ? '✅' : '⏸️',
            label: 'Statut',
            value: session.completed ? 'Terminé' : 'Incomplet',
            color: session.completed ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildHrChart() {
    final hrTrace = widget.session.hrTrace;
    if (hrTrace.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        size: const Size(double.infinity, 188),
        painter: HrChartPainter(
          hrTrace: hrTrace,
          settings: _settings,
          minHr: _minHr ?? 60,
          maxHr: _maxHr ?? 180,
        ),
      ),
    );
  }

  Widget _buildZonesBreakdown() {
    final zones = _calculateZoneDistribution();
    final total = zones.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: HrZone.values.reversed.map((zone) {
          final count = zones[zone] ?? 0;
          final percent = total > 0 ? (count / total * 100) : 0.0;
          final minutes = (count / 60).round(); // Assuming ~1 sample per second

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: zone.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: Text(
                    zone.label,
                    style: TextStyle(
                      color: zone.color,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(zone.color),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 50,
                  child: Text(
                    '${percent.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHrSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildHrSummaryRow('FC minimum', '${_minHr ?? "--"} bpm', Colors.blue),
          const Divider(color: Colors.white12),
          _buildHrSummaryRow(
            'FC moyenne',
            '${widget.session.averageHr ?? "--"} bpm',
            Colors.green,
          ),
          const Divider(color: Colors.white12),
          _buildHrSummaryRow('FC maximum', '${_maxHr ?? "--"} bpm', Colors.red),
          const Divider(color: Colors.white12),
          _buildHrSummaryRow(
            'FC max théorique',
            '${_settings.hrMax} bpm',
            Colors.purple,
          ),
          const Divider(color: Colors.white12),
          _buildHrSummaryRow(
            'Échantillons',
            '${widget.session.hrTrace.length}',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildHrSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoHrData() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite_border,
            size: 60,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune donnée cardiaque',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connectez votre Polar H10 pour enregistrer\nvotre fréquence cardiaque',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Custom painter for HR chart
class HrChartPainter extends CustomPainter {
  final List<HrPoint> hrTrace;
  final UserSettings settings;
  final int minHr;
  final int maxHr;

  HrChartPainter({
    required this.hrTrace,
    required this.settings,
    required this.minHr,
    required this.maxHr,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hrTrace.isEmpty) return;

    final padding = 40.0;
    final chartWidth = size.width - padding;
    final chartHeight = size.height - 24;

    // Calculate HR range with some padding
    final hrMin = (minHr - 10).clamp(40, 200);
    final hrMax = (maxHr + 10).clamp(60, 220);
    final hrRange = hrMax - hrMin;

    // Draw zone backgrounds
    _drawZoneBackgrounds(canvas, size, padding, chartHeight, hrMin, hrRange);

    // Draw grid lines and labels
    _drawGrid(canvas, size, padding, chartHeight, hrMin, hrMax);

    // Draw HR line
    _drawHrLine(canvas, size, padding, chartWidth, chartHeight, hrMin, hrRange);

    // Draw time labels
    _drawTimeLabels(canvas, size, padding, chartWidth);
  }

  void _drawZoneBackgrounds(
    Canvas canvas,
    Size size,
    double padding,
    double chartHeight,
    int hrMin,
    int hrRange,
  ) {
    // Zone thresholds based on HRmax percentage
    final zones = [
      (HrZone.redZone, 0.90, 1.0),
      (HrZone.threshold, 0.80, 0.90),
      (HrZone.cardio, 0.70, 0.80),
      (HrZone.endurance, 0.60, 0.70),
      (HrZone.fatBurn, 0.50, 0.60),
      (HrZone.recovery, 0.0, 0.50),
    ];

    for (final (zone, minPct, maxPct) in zones) {
      final minZoneHr = (settings.hrMax * minPct).round();
      final maxZoneHr = (settings.hrMax * maxPct).round();

      final top = chartHeight - ((maxZoneHr - hrMin) / hrRange * chartHeight);
      final bottom = chartHeight - ((minZoneHr - hrMin) / hrRange * chartHeight);

      final paint = Paint()
        ..color = zone.color.withOpacity(0.1)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTRB(
          padding,
          top.clamp(0.0, chartHeight),
          size.width,
          bottom.clamp(0.0, chartHeight),
        ),
        paint,
      );
    }
  }

  void _drawGrid(
    Canvas canvas,
    Size size,
    double padding,
    double chartHeight,
    int hrMin,
    int hrMax,
  ) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    final labelStyle = TextStyle(
      color: Colors.white.withOpacity(0.5),
      fontSize: 10,
    );

    // Horizontal grid lines
    final hrStep = ((hrMax - hrMin) / 5).round();
    for (var hr = hrMin; hr <= hrMax; hr += hrStep) {
      final y = chartHeight - ((hr - hrMin) / (hrMax - hrMin) * chartHeight);

      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width, y),
        gridPaint,
      );

      // HR label
      final textPainter = TextPainter(
        text: TextSpan(text: '$hr', style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(5, y - textPainter.height / 2),
      );
    }
  }

  void _drawHrLine(
    Canvas canvas,
    Size size,
    double padding,
    double chartWidth,
    double chartHeight,
    int hrMin,
    int hrRange,
  ) {
    if (hrTrace.length < 2) return;

    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < hrTrace.length; i++) {
      final x = padding + (i / (hrTrace.length - 1) * chartWidth);
      final hr = hrTrace[i].hr;
      final y = chartHeight - ((hr - hrMin) / hrRange * chartHeight);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, chartHeight);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Fill gradient under line
    fillPath.lineTo(padding + chartWidth, chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.red.withOpacity(0.3),
          Colors.red.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));

    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final linePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);
  }

  void _drawTimeLabels(
    Canvas canvas,
    Size size,
    double padding,
    double chartWidth,
  ) {
    if (hrTrace.isEmpty) return;

    final labelStyle = TextStyle(
      color: Colors.white.withOpacity(0.5),
      fontSize: 10,
    );

    final startTime = hrTrace.first.t;
    final endTime = hrTrace.last.t;
    final duration = endTime.difference(startTime);

    // Draw start, middle, end time labels
    final times = [
      (0.0, startTime),
      (0.5, startTime.add(Duration(seconds: duration.inSeconds ~/ 2))),
      (1.0, endTime),
    ];

    for (final (pos, time) in times) {
      final x = padding + (pos * chartWidth);
      final label = DateFormat('HH:mm:ss').format(time);

      final textPainter = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      var xPos = x - textPainter.width / 2;
      if (pos == 0.0) xPos = padding;
      if (pos == 1.0) xPos = size.width - textPainter.width;

      textPainter.paint(
        canvas,
        Offset(xPos, size.height - 15),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
