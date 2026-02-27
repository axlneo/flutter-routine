import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../services/notifications_service.dart';
import '../services/polar_service.dart';
import '../models/models.dart';
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

  // Controllers for settings
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
                    const Text(
                      '🔔 Planning & Médicaments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // ========== MEDICATIONS ==========
                    _buildSectionHeader('💊 Médicaments du jour'),
                    _buildDateSelector(),
                    const SizedBox(height: 12),
                    _buildMedCard('Matin - 7h', 'morning'),
                    const SizedBox(height: 12),
                    _buildMedCard('Soir - 19h', 'evening'),

                    const SizedBox(height: 32),

                    // ========== CARDIO ==========
                    _buildSectionHeader('🏃 Cardio'),
                    _buildCardioCard(),

                    const SizedBox(height: 32),

                    // ========== NOTIFICATIONS ==========
                    _buildSectionHeader('🔔 Notifications'),
                    _buildNotificationSettings(),

                    const SizedBox(height: 32),

                    // ========== POLAR H10 ==========
                    _buildSectionHeader('❤️ Polar H10'),
                    _buildPolarSettings(),

                    const SizedBox(height: 32),

                    // ========== HR SETTINGS ==========
                    _buildSectionHeader('⚙️ Paramètres HR'),
                    _buildHrSettings(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: () => _selectDate(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white70),
            const SizedBox(width: 12),
            Text(
              DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.white70),
          ],
        ),
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
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Widget _buildMedCard(String title, String slot) {
    final isTaken = _storage.areMedsTakenOnDate(_selectedDate, slot);
    final meds = slot == 'morning'
        ? StorageService.morningMeds
        : _storage.getEveningMeds(_selectedDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTaken
            ? Colors.green.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTaken ? Colors.green.withOpacity(0.5) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (isTaken)
                const Text('✅', style: TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 12),

          // Medication list
          ...meds.map((med) {
            final isOmega = med.contains('Oméga');
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.medication,
                    size: 16,
                    color: isOmega ? Colors.amber : Colors.white54,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      med,
                      style: TextStyle(
                        color: isOmega ? Colors.amber : Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),

          // Toggle button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _toggleMeds(slot),
              style: ElevatedButton.styleFrom(
                backgroundColor: isTaken ? Colors.red.withOpacity(0.8) : Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(isTaken ? 'Annuler' : 'Marquer comme pris'),
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

  Widget _buildCardioCard() {
    final done = _storage.isCardioCompletedOnDate(_selectedDate);
    final weekCount = _storage.getWeeklyCardioCount(_selectedDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: done
            ? Colors.redAccent.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done ? Colors.redAccent.withOpacity(0.5) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.circle_outlined,
                color: done ? Colors.redAccent : Colors.white54,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  done ? 'Séance faite' : 'Pas de séance ce jour',
                  style: TextStyle(
                    color: Colors.white.withOpacity(done ? 1 : 0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '$weekCount/5 semaine',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
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
              icon: Icon(done ? Icons.close : Icons.fitness_center, size: 18),
              label: Text(done ? 'Annuler' : 'Marquer comme fait'),
              style: ElevatedButton.styleFrom(
                backgroundColor: done ? Colors.red.shade700 : Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.amber),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Rappels quotidiens',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              Switch(
                value: _settings.notificationsEnabled,
                onChanged: (value) => _toggleNotifications(value),
                activeColor: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• 7h00 : Routine matin + médicaments\n• 19h00 : Routine soir + médicaments',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),

          // Test button
          OutlinedButton.icon(
            onPressed: () => _notifications.showTestNotification(),
            icon: const Icon(Icons.notifications, size: 18),
            label: const Text('Tester'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white30),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleNotifications(bool enabled) async {
    if (enabled) {
      final granted = await _notifications.requestPermissions();
      if (granted) {
        await _notifications.scheduleAllNotifications();
        _settings.notificationsEnabled = true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission refusée')),
        );
        return;
      }
    } else {
      await _notifications.cancelAllNotifications();
      _settings.notificationsEnabled = false;
    }
    
    await _storage.saveSettings(_settings);
    setState(() {});
  }

  Widget _buildPolarSettings() {
    return StreamBuilder<PolarConnectionState>(
      stream: _polar.connectionStateStream,
      initialData: _polar.connectionState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? PolarConnectionState.disconnected;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection status
              Row(
                children: [
                  Text(state.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Polar H10',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          state.label,
                          style: TextStyle(
                            color: state == PolarConnectionState.connected
                                ? Colors.green
                                : Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // HR display if connected
                  if (state == PolarConnectionState.connected)
                    StreamBuilder<int>(
                      stream: _polar.hrStream,
                      builder: (context, snapshot) {
                        final hr = snapshot.data;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            hr != null ? '❤️ $hr' : '❤️ --',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Action buttons
              if (state == PolarConnectionState.disconnected ||
                  state == PolarConnectionState.error) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startPolarScan,
                    icon: const Icon(Icons.bluetooth_searching),
                    label: const Text('Rechercher'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],

              if (state == PolarConnectionState.scanning) ...[
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                const SizedBox(height: 12),
                _buildDeviceList(),
              ],

              if (state == PolarConnectionState.connected) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _polar.disconnect,
                    icon: const Icon(Icons.bluetooth_disabled),
                    label: const Text('Déconnecter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
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
          return Text(
            'Recherche en cours...',
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          );
        }

        return Column(
          children: devices.map((device) {
            return ListTile(
              leading: const Icon(Icons.bluetooth, color: Colors.blue),
              title: Text(
                device.name,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                device.deviceId,
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
              onTap: () => _polar.connectToDevice(device.deviceId),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildHrSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Age
          _buildTextField(
            'Âge',
            _ageController,
            'ans',
            (value) {
              _settings.age = int.tryParse(value) ?? 40;
              _saveSettings();
            },
          ),
          const SizedBox(height: 16),

          // HR Rest
          _buildTextField(
            'FC repos (optionnel)',
            _hrRestController,
            'bpm',
            (value) {
              _settings.hrRest = int.tryParse(value);
              _saveSettings();
            },
          ),
          const SizedBox(height: 16),

          // HR Max override
          _buildTextField(
            'FC max custom (optionnel)',
            _hrMaxController,
            'bpm',
            (value) {
              _settings.hrMaxOverride = int.tryParse(value);
              _saveSettings();
            },
          ),
          const SizedBox(height: 16),

          // Karvonen toggle
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Formule Karvonen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Utilise la FC de repos pour plus de précision',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
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
                activeColor: Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Calculated values
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCalcValue('FC Max', '${_settings.hrMax} bpm'),
                if (_settings.hrRest != null)
                  _buildCalcValue(
                    'Réserve',
                    '${_settings.hrMax - _settings.hrRest!} bpm',
                  ),
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        suffixText: suffix,
        suffixStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildCalcValue(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    await _storage.saveSettings(_settings);
  }
}
