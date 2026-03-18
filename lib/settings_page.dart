import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_page.dart';
import 'personal_data_page.dart';
import 'app_settings.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _store = const AppSettingsStore();
  final _profileStorage = const FlutterSecureStorage();

  static const _kProfileName = "profile_name";
  static const _kProfilePhotoPath = "profile_photo_path";

  bool _loading = true;
  String _profileName = "User";
  String? _profilePhotoPath;

  bool voiceAlerts = AppSettings.defaults.voiceAlerts;
  bool vibrationAlerts = AppSettings.defaults.vibrationAlerts;
  bool lowLightEnhancement = AppSettings.defaults.lowLightEnhancement;
  bool privacyMode = AppSettings.defaults.privacyMode;

  double alertSensitivity = AppSettings.defaults.alertSensitivity;
  double confidenceThreshold = AppSettings.defaults.confidenceThreshold;

  void _vibrateOnChange() {
    if (vibrationAlerts) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _store.load();
    final profileName = await _profileStorage.read(key: _kProfileName);
    final profilePhotoPath =
        await _profileStorage.read(key: _kProfilePhotoPath);
    if (!mounted) return;
    setState(() {
      voiceAlerts = settings.voiceAlerts;
      vibrationAlerts = settings.vibrationAlerts;
      lowLightEnhancement = settings.lowLightEnhancement;
      privacyMode = settings.privacyMode;
      alertSensitivity = settings.alertSensitivity;
      confidenceThreshold = settings.confidenceThreshold;
      _profileName = (profileName == null || profileName.trim().isEmpty)
          ? "User"
          : profileName.trim();
      _profilePhotoPath = profilePhotoPath;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
          /// PROFILE CARD
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PersonalDataPage(),
                ),
              ).then((_) => _loadSettings());
            },
            child: _buildCard(
              child: Row(
                children: [
                  _buildProfileAvatar(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_profileName,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        const Text("Second Sight App",
                            style: TextStyle(color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          const _SectionTitle("Alert Preferences"),
          const SizedBox(height: 16),

          _buildSwitchTile(
            title: "Voice Alerts",
            subtitle: "Speak warning messages aloud",
            value: voiceAlerts,
            icon: Icons.volume_up,
            onChanged: (val) {
              setState(() => voiceAlerts = val);
              _store.update(voiceAlerts: val);
              _vibrateOnChange();
            },
          ),

          _buildSwitchTile(
            title: "Vibration Alerts",
            subtitle: "Vibrate when obstacle is detected",
            value: vibrationAlerts,
            icon: Icons.vibration,
            onChanged: (val) {
              setState(() => vibrationAlerts = val);
              _store.update(vibrationAlerts: val);
            },
          ),

          const SizedBox(height: 28),

          const _SectionTitle("Detection Settings"),
          const SizedBox(height: 16),

          _buildSwitchTile(
            title: "Low Light Enhancement",
            subtitle: "Improve detection in dark areas",
            value: lowLightEnhancement,
            icon: Icons.brightness_4,
            onChanged: (val) {
              setState(() => lowLightEnhancement = val);
              _store.update(lowLightEnhancement: val);
              _vibrateOnChange();
            },
          ),

          _buildSliderTile(
            title: "Alert Sensitivity",
            subtitle: "Higher sensitivity gives more warnings",
            icon: Icons.tune,
            value: alertSensitivity,
            min: 1,
            max: 10,
            divisions: 9,
            label: alertSensitivity.toStringAsFixed(0),
            onChanged: (val) {
              setState(() => alertSensitivity = val);
              _store.update(alertSensitivity: val);
              _vibrateOnChange();
            },
          ),

          _buildSliderTile(
            title: "Confidence Threshold",
            subtitle: "Lower value detects more objects",
            icon: Icons.analytics,
            value: confidenceThreshold,
            min: 0.30,
            max: 0.95,
            divisions: 13,
            label: confidenceThreshold.toStringAsFixed(2),
            onChanged: (val) {
              setState(() => confidenceThreshold = val);
              _store.update(confidenceThreshold: val);
              _vibrateOnChange();
            },
          ),

          const SizedBox(height: 28),

          const _SectionTitle("Privacy & Security"),
          const SizedBox(height: 16),

          _buildSwitchTile(
            title: "Privacy Mode",
            subtitle: "Camera works only when app is open",
            value: privacyMode,
            icon: Icons.lock,
            onChanged: (val) {
              setState(() => privacyMode = val);
              _store.update(privacyMode: val);
              _vibrateOnChange();
            },
          ),

          const SizedBox(height: 28),

          const _SectionTitle("Other"),
          const SizedBox(height: 16),

          _buildSimpleTile(
            title: "About App",
            subtitle: "Project details and version",
            icon: Icons.info_outline,
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("About"),
                  content: const Text(
                    "Second Sight - Obstacle Detection App\n\n"
                    "Version: 1.0\n\n"
                    "Detects obstacles using AI and provides "
                    "voice + vibration alerts.",
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("OK"))
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildProfileAvatar() {
    final path = _profilePhotoPath;
    final hasPhoto = path != null && File(path).existsSync();

    if (hasPhoto) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(path),
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.person,
        color: Color(0xFF4F46E5),
        size: 28,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _buildCard(
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF4F46E5),
          secondary: Icon(icon, color: const Color(0xFF4F46E5)),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
        ),
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required Function(double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF4F46E5)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text(label,
                    style: const TextStyle(
                        color: Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: label,
              activeColor: const Color(0xFF4F46E5),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _buildCard(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF4F46E5)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
