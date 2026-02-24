import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool voiceAlerts = true;
  bool vibrationAlerts = true;
  bool lowLightEnhancement = false;
  bool privacyMode = true;

  double alertSensitivity = 5;
  double confidenceThreshold = 0.60;

  void _vibrateOnChange() {
    if (vibrationAlerts) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [

          /// PROFILE CARD
          _buildCard(
            child: Row(
              children: [
                Container(
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
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("User",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text("Second Sight App",
                          style: TextStyle(color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
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
                  MaterialPageRoute(
                      builder: (_) => const LoginPage()),
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
          activeColor: const Color(0xFF4F46E5),
          secondary: Icon(icon, color: const Color(0xFF4F46E5)),
          title: Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w600)),
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
                      style: const TextStyle(
                          fontWeight: FontWeight.w600)),
                ),
                Text(label,
                    style: const TextStyle(
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            Text(subtitle,
                style:
                    const TextStyle(color: Color(0xFF64748B))),
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
        title: Text(title,
            style:
                const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16),
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