import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';
import 'dart:math' as math;

class SessionDetailPage extends StatefulWidget {
  final SessionRecord session;

  const SessionDetailPage({super.key, required this.session});

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
    final isMorning = session.routineId == 'morning';
    final title = isMorning ? 'Routine Matin' : 'Routine Soir';
    final dayText = session.day != null ? ' · J${session.day}' : '';
    final dateLabel = DateFormat('EEEE d MMMM · HH:mm', 'fr_FR').format(session.tsStart);
    final dateCap = dateLabel[0].toUpperCase() + dateLabel.substring(1);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(title: '$title$dayText', subtitle: dateCap),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _buildStatsCards(),
                const SizedBox(height: 22),
                if (hasHrData) ...[
                  const SectionHeader('Fréquence cardiaque'),
                  _buildHrChart(),
                  const SizedBox(height: 22),
                  const SectionHeader('Zones d\'entraînement'),
                  _buildZonesBreakdown(),
                  const SizedBox(height: 22),
                  const SectionHeader('Résumé FC'),
                  _buildHrSummary(),
                ] else
                  _buildNoHrData(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final session = widget.session;
    final duration = session.durationMinutes;
    final avgHr = session.averageHr;
    final completed = session.completed;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.schedule,
            label: 'DURÉE',
            value: '$duration',
            unit: 'min',
            color: AppColors.action,
            soft: AppColors.surfaceMuted,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.favorite,
            label: 'FC MOY.',
            value: avgHr != null ? '$avgHr' : '—',
            unit: 'bpm',
            color: AppColors.heart,
            soft: AppColors.heartSoft,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: completed ? Icons.check : Icons.pause,
            label: 'STATUT',
            value: completed ? 'OK' : '—',
            unit: completed ? 'fini' : 'incomplet',
            color: completed ? AppColors.success : AppColors.warning,
            soft: completed ? AppColors.successSoft : const Color(0xFFFFF3E0),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    required Color soft,
  }) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
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
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHrChart() {
    final hrTrace = widget.session.hrTrace;
    if (hrTrace.isEmpty) return const SizedBox.shrink();

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        height: 200,
        child: CustomPaint(
          size: const Size(double.infinity, 188),
          painter: HrChartPainter(
            hrTrace: hrTrace,
            settings: _settings,
            minHr: _minHr ?? 60,
            maxHr: _maxHr ?? 180,
          ),
        ),
      ),
    );
  }

  Widget _buildZonesBreakdown() {
    final zones = _calculateZoneDistribution();
    final total = zones.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        children: HrZone.values.reversed.map((zone) {
          final count = zones[zone] ?? 0;
          final percent = total > 0 ? (count / total * 100) : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: zone.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 78,
                  child: Text(
                    zone.label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      backgroundColor: AppColors.surfaceMuted,
                      valueColor: AlwaysStoppedAnimation(zone.color),
                      minHeight: 7,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${percent.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
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
    return AppCard(
      child: Column(
        children: [
          _hrSummaryRow('FC minimum', '${_minHr ?? "—"}', AppColors.info),
          const Divider(height: 18, color: AppColors.divider),
          _hrSummaryRow('FC moyenne', '${widget.session.averageHr ?? "—"}', AppColors.success),
          const Divider(height: 18, color: AppColors.divider),
          _hrSummaryRow('FC maximum', '${_maxHr ?? "—"}', AppColors.heart),
          const Divider(height: 18, color: AppColors.divider),
          _hrSummaryRow('FC max théorique', '${_settings.hrMax}', AppColors.textSecondary),
          const Divider(height: 18, color: AppColors.divider),
          _hrSummaryRow('Échantillons', '${widget.session.hrTrace.length}', AppColors.action, suffix: ''),
        ],
      ),
    );
  }

  Widget _hrSummaryRow(String label, String value, Color color, {String suffix = 'bpm'}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 17,
                letterSpacing: -0.3,
              ),
            ),
            if (suffix.isNotEmpty) ...[
              const SizedBox(width: 3),
              Text(
                suffix,
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildNoHrData() {
    return AppCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          AppIconBadge(
            icon: Icons.favorite_border,
            color: AppColors.textTertiary,
            soft: AppColors.surfaceMuted,
            size: 56,
          ),
          const SizedBox(height: 14),
          const Text(
            'Aucune donnée cardiaque',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Connecte ta ceinture Polar H10 pour\nenregistrer ta fréquence cardiaque',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// HR chart painter (light theme)
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

    const padding = 36.0;
    final chartWidth = size.width - padding;
    final chartHeight = size.height - 24;

    final hrMin = (minHr - 10).clamp(40, 200);
    final hrMax = (maxHr + 10).clamp(60, 220);
    final hrRange = hrMax - hrMin;

    _drawZoneBackgrounds(canvas, size, padding, chartHeight, hrMin, hrRange);
    _drawGrid(canvas, size, padding, chartHeight, hrMin, hrMax);
    _drawHrLine(canvas, size, padding, chartWidth, chartHeight, hrMin, hrRange);
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
        ..color = zone.color.withValues(alpha: 0.08)
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
      ..color = AppColors.divider.withValues(alpha: 0.6)
      ..strokeWidth = 1;

    const labelStyle = TextStyle(
      color: AppColors.textTertiary,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    final hrStep = ((hrMax - hrMin) / 5).round();
    for (var hr = hrMin; hr <= hrMax; hr += hrStep) {
      final y = chartHeight - ((hr - hrMin) / (hrMax - hrMin) * chartHeight);
      canvas.drawLine(Offset(padding, y), Offset(size.width, y), gridPaint);

      final textPainter = TextPainter(
        text: TextSpan(text: '$hr', style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(2, y - textPainter.height / 2));
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
      final y = chartHeight - ((hrTrace[i].hr - hrMin) / hrRange * chartHeight);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, chartHeight);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(padding + chartWidth, chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.heart.withValues(alpha: 0.25),
          AppColors.heart.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppColors.heart
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);
  }

  void _drawTimeLabels(Canvas canvas, Size size, double padding, double chartWidth) {
    if (hrTrace.isEmpty) return;

    const labelStyle = TextStyle(
      color: AppColors.textTertiary,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    final startTime = hrTrace.first.t;
    final endTime = hrTrace.last.t;
    final duration = endTime.difference(startTime);

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
      textPainter.paint(canvas, Offset(xPos, size.height - 14));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
