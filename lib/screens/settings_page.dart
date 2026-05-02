import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../services/notifications_service.dart';
import '../services/polar_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';
import 'package:polar/polar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final StorageService _storage = StorageService();
  final NotificationsService _notifications = NotificationsService();
  final PolarService _polar = PolarService();

  late UserSettings _settings;
  DateTime _selectedDate = DateTime.now();

  final _ageController = TextEditingController();
  final _hrRestController = TextEditingController();
  final _hrMaxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _settings = _storage.settings;
    _ageController.text = _settings.age.toString();
    _hrRestController.text = _settings.hrRest?.toString() ?? '';
    _hrMaxController.text = _settings.hrMaxOverride?.toString() ?? '';
  }

  @override
  void dispose() {
    _ageController.dispose();
    _hrRestController.dispose();
    _hrMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppHeader(
            title: 'Planning & Médicaments',
            subtitle: 'Paramètres',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const SectionHeader('Médicaments du jour'),
                _buildDateSelector(),
                const SizedBox(height: 10),
                _buildMedCard('Matin', 'morning'),
                const SizedBox(height: 10),
                _buildMedCard('Soir', 'evening'),

                const SizedBox(height: 22),
                const SectionHeader('Cardio'),
                _buildCardioCard(),

                const SizedBox(height: 22),
                const SectionHeader('Notifications'),
                _buildNotificationSettings(),

                const SizedBox(height: 22),
                const SectionHeader('Polar H10'),
                _buildPolarSettings(),

                const SizedBox(height: 22),
                const SectionHeader('Paramètres FC'),
                _buildHrSettings(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ DATE PICKER ============

  Widget _buildDateSelector() {
    return AppCard(
      onTap: _selectDate,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const AppIconBadge(
            icon: Icons.calendar_today,
            color: AppColors.action,
            soft: AppColors.surfaceMuted,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: AppColors.textTertiary),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      locale: const Locale('fr', 'FR'),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  // ============ MEDS ============

  Widget _buildMedCard(String title, String slot) {
    final isTaken = _storage.areMedsTakenOnDate(_selectedDate, slot);
    final meds = slot == 'morning'
        ? StorageService.morningMeds
        : _storage.getEveningMeds(_selectedDate);
    final hour = slot == 'morning' ? _settings.morningHour : _settings.eveningHour;
    final minute = slot == 'morning' ? _settings.morningMinute : _settings.eveningMinute;
    final timeStr = '${hour.toString().padLeft(2, '0')}h${minute.toString().padLeft(2, '0')}';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconBadge(
                icon: slot == 'morning' ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                color: isTaken ? AppColors.success : AppColors.textSecondary,
                soft: isTaken ? AppColors.successSoft : AppColors.surfaceMuted,
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (isTaken)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, color: Colors.white, size: 12),
                      SizedBox(width: 3),
                      Text(
                        'PRIS',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: meds.map((med) {
              final isOmega = med.contains('Oméga');
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isOmega ? const Color(0xFFFFF3E0) : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.medication, size: 12, color: isOmega ? AppColors.warning : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      med,
                      style: TextStyle(
                        color: isOmega ? AppColors.warning : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _toggleMeds(slot),
              icon: Icon(isTaken ? Icons.undo : Icons.check_circle_outline, size: 18),
              label: Text(isTaken ? 'Annuler' : 'Marquer comme pris'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isTaken ? AppColors.surfaceVariant : AppColors.success,
                foregroundColor: isTaken ? AppColors.textPrimary : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMeds(String slot) async {
    final isTaken = _storage.areMedsTakenOnDate(_selectedDate, slot);
    await _storage.setMedsTaken(_selectedDate, slot, !isTaken);
    setState(() {});
  }

  // ============ CARDIO ============

  Widget _buildCardioCard() {
    final done = _storage.isCardioCompletedOnDate(_selectedDate);
    final weekCount = _storage.getWeeklyCardioCount(_selectedDate);

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              AppIconBadge(
                icon: done ? Icons.directions_run : Icons.favorite_border,
                color: done ? AppColors.heart : AppColors.textTertiary,
                soft: done ? AppColors.heartSoft : AppColors.surfaceMuted,
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      done ? 'Séance faite' : 'Pas de séance ce jour',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$weekCount/5 cette semaine',
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await _storage.setCardioCompleted(_selectedDate, !done);
                setState(() {});
              },
              icon: Icon(done ? Icons.undo : Icons.fitness_center, size: 18),
              label: Text(done ? 'Annuler' : 'Marquer comme fait'),
              style: ElevatedButton.styleFrom(
                backgroundColor: done ? AppColors.surfaceVariant : AppColors.heart,
                foregroundColor: done ? AppColors.textPrimary : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ NOTIFICATIONS ============

  Widget _buildNotificationSettings() {
    final morning = TimeOfDay(hour: _settings.morningHour, minute: _settings.morningMinute);
    final evening = TimeOfDay(hour: _settings.eveningHour, minute: _settings.eveningMinute);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIconBadge(
                icon: Icons.notifications_active,
                color: AppColors.warning,
                soft: Color(0xFFFFF3E0),
                size: 36,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Rappels quotidiens',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              Switch(
                value: _settings.notificationsEnabled,
                onChanged: _toggleNotifications,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTimeRow(
            icon: '🌅',
            label: 'Matin (routine + médicaments)',
            time: morning,
            onPick: () => _pickTime(slot: 'morning', current: morning),
          ),
          const SizedBox(height: 8),
          _buildTimeRow(
            icon: '🌙',
            label: 'Soir (routine + médicaments)',
            time: evening,
            onPick: () => _pickTime(slot: 'evening', current: evening),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _notifications.showTestNotification(),
                icon: const Icon(Icons.notifications, size: 16),
                label: const Text('Tester'),
              ),
              OutlinedButton.icon(
                onPressed: _showPendingNotifications,
                icon: const Icon(Icons.list_alt, size: 16),
                label: const Text('Voir planifiées'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow({
    required String icon,
    required String label,
    required TimeOfDay time,
    required VoidCallback onPick,
  }) {
    final disabled = !_settings.notificationsEnabled;
    return InkWell(
      onTap: disabled ? null : onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: disabled ? AppColors.surfaceMuted.withValues(alpha: 0.5) : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(icon, style: TextStyle(fontSize: 18, color: disabled ? AppColors.textTertiary : null)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: disabled ? AppColors.textTertiary : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: disabled ? AppColors.surfaceVariant : AppColors.polarBlack,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatTime(time),
                style: TextStyle(
                  color: disabled ? AppColors.textTertiary : AppColors.textOnDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}h${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required String slot, required TimeOfDay current}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;

    if (slot == 'morning') {
      _settings.morningHour = picked.hour;
      _settings.morningMinute = picked.minute;
    } else {
      _settings.eveningHour = picked.hour;
      _settings.eveningMinute = picked.minute;
    }
    await _storage.saveSettings(_settings);

    if (_settings.notificationsEnabled) {
      await _notifications.scheduleAllNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${slot == 'morning' ? 'Matin' : 'Soir'} reprogrammé à ${_formatTime(picked)}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    setState(() {});
  }

  Future<void> _showPendingNotifications() async {
    final pending = await _notifications.pendingNotifications();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notifications planifiées'),
        content: SizedBox(
          width: double.maxFinite,
          child: pending.isEmpty
              ? const Text('Aucune notification planifiée.', style: TextStyle(color: AppColors.textSecondary))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: pending
                      .map((p) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '#${p.id} — ${p.title ?? ''}',
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                          ))
                      .toList(),
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _toggleNotifications(bool enabled) async {
    if (enabled) {
      final granted = await _notifications.requestPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission refusée')),
          );
        }
        return;
      }
      await _notifications.scheduleAllNotifications();
      _settings.notificationsEnabled = true;
    } else {
      await _notifications.cancelAllNotifications();
      _settings.notificationsEnabled = false;
    }
    await _storage.saveSettings(_settings);
    setState(() {});
  }

  // ============ POLAR ============

  Widget _buildPolarSettings() {
    return StreamBuilder<PolarConnectionState>(
      stream: _polar.connectionStateStream,
      initialData: _polar.connectionState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? PolarConnectionState.disconnected;
        final isConnected = state == PolarConnectionState.connected;

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppIconBadge(
                    icon: Icons.favorite,
                    color: isConnected ? AppColors.heart : AppColors.textTertiary,
                    soft: isConnected ? AppColors.heartSoft : AppColors.surfaceMuted,
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Polar H10',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          state.label,
                          style: TextStyle(
                            color: isConnected ? AppColors.success : AppColors.textTertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isConnected)
                    StreamBuilder<int>(
                      stream: _polar.hrStream,
                      builder: (context, snapshot) {
                        final hr = snapshot.data;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.heart,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.favorite, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                hr != null ? '$hr' : '--',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (state == PolarConnectionState.disconnected ||
                  state == PolarConnectionState.error) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startPolarScan,
                    icon: const Icon(Icons.bluetooth_searching, size: 18),
                    label: const Text('Rechercher'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.heart),
                  ),
                ),
              ],
              if (state == PolarConnectionState.scanning) ...[
                const Center(child: CircularProgressIndicator(color: AppColors.heart)),
                const SizedBox(height: 12),
                _buildDeviceList(),
              ],
              if (isConnected) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _polar.disconnect,
                    icon: const Icon(Icons.bluetooth_disabled, size: 18),
                    label: const Text('Déconnecter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.heart,
                      side: const BorderSide(color: AppColors.heart),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _startPolarScan() async {
    final hasPermission = await _polar.requestPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissions Bluetooth requises')),
        );
      }
      return;
    }
    await _polar.startScan();
  }

  Widget _buildDeviceList() {
    return StreamBuilder<List<PolarDeviceInfo>>(
      stream: _polar.devicesStream,
      initialData: const [],
      builder: (context, snapshot) {
        final devices = snapshot.data ?? [];
        if (devices.isEmpty) {
          return const Text(
            'Recherche en cours…',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          );
        }
        return Column(
          children: devices.map((device) {
            return ListTile(
              leading: const Icon(Icons.bluetooth, color: AppColors.info),
              title: Text(device.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
              subtitle: Text(device.deviceId, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
              onTap: () => _polar.connectToDevice(device.deviceId),
            );
          }).toList(),
        );
      },
    );
  }

  // ============ HR SETTINGS ============

  Widget _buildHrSettings() {
    return AppCard(
      child: Column(
        children: [
          _buildTextField('Âge', _ageController, 'ans', (value) {
            _settings.age = int.tryParse(value) ?? 40;
            _saveSettings();
          }),
          const SizedBox(height: 12),
          _buildTextField('FC repos (optionnel)', _hrRestController, 'bpm', (value) {
            _settings.hrRest = int.tryParse(value);
            _saveSettings();
          }),
          const SizedBox(height: 12),
          _buildTextField('FC max custom (optionnel)', _hrMaxController, 'bpm', (value) {
            _settings.hrMaxOverride = int.tryParse(value);
            _saveSettings();
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Formule Karvonen',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const Text(
                      'Utilise la FC de repos pour plus de précision',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _settings.useKarvonen,
                onChanged: (value) {
                  _settings.useKarvonen = value;
                  _saveSettings();
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCalcValue('FC MAX', '${_settings.hrMax}', 'bpm'),
                if (_settings.hrRest != null)
                  _buildCalcValue('RÉSERVE', '${_settings.hrMax - _settings.hrRest!}', 'bpm'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String suffix,
    Function(String) onChanged,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildCalcValue(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              unit,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    await _storage.saveSettings(_settings);
  }
}
