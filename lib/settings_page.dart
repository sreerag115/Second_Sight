import 'package:flutter/material.dart';
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

  double alertSensitivity = 5; // 1 to 10
  double confidenceThreshold = 0.60; // 0.30 to 0.95

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "User",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Obstacle Detection App",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit, color: Colors.green),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            "Alert Preferences",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // ✅ Voice Alerts Toggle
          buildSwitchTile(
            title: "Voice Alerts",
            subtitle: "Speak warning messages aloud",
            value: voiceAlerts,
            onChanged: (val) => setState(() => voiceAlerts = val),
            icon: Icons.volume_up,
          ),

          // ✅ Vibration Toggle
          buildSwitchTile(
            title: "Vibration Alerts",
            subtitle: "Vibrate when obstacle is detected",
            value: vibrationAlerts,
            onChanged: (val) => setState(() => vibrationAlerts = val),
            icon: Icons.vibration,
          ),

          const SizedBox(height: 18),

          const Text(
            "Detection Settings",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // ✅ Low Light Enhancement
          buildSwitchTile(
            title: "Low Light Enhancement",
            subtitle: "Improve detection in dark areas",
            value: lowLightEnhancement,
            onChanged: (val) => setState(() => lowLightEnhancement = val),
            icon: Icons.brightness_4,
          ),

          // ✅ Alert Sensitivity Slider
          buildSliderTile(
            title: "Alert Sensitivity",
            subtitle: "Higher sensitivity gives more warnings",
            icon: Icons.tune,
            value: alertSensitivity,
            min: 1,
            max: 10,
            divisions: 9,
            label: alertSensitivity.toStringAsFixed(0),
            onChanged: (val) => setState(() => alertSensitivity = val),
          ),

          // ✅ Confidence Threshold Slider
          buildSliderTile(
            title: "Confidence Threshold",
            subtitle: "Lower value gives more detections (may be wrong)",
            icon: Icons.analytics,
            value: confidenceThreshold,
            min: 0.30,
            max: 0.95,
            divisions: 13,
            label: confidenceThreshold.toStringAsFixed(2),
            onChanged: (val) => setState(() => confidenceThreshold = val),
          ),

          const SizedBox(height: 18),

          const Text(
            "Privacy & Security",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // ✅ Privacy Mode
          buildSwitchTile(
            title: "Privacy Mode",
            subtitle: "Camera works only when app is open",
            value: privacyMode,
            onChanged: (val) => setState(() => privacyMode = val),
            icon: Icons.lock,
          ),

          const SizedBox(height: 18),

          const Text(
            "Other",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          buildSimpleTile(
            title: "About App",
            subtitle: "Project details and version",
            icon: Icons.info_outline,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("About"),
                  content: const Text(
                    "Obstacle Detection System for Visually Impaired\n\nVersion: 1.0\n\nThis app detects obstacles using camera and provides audio alerts.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            },
          ),

          buildSimpleTile(
            title: "Reset Settings",
            subtitle: "Restore default options",
            icon: Icons.refresh,
            onTap: () {
              setState(() {
                voiceAlerts = true;
                vibrationAlerts = true;
                lowLightEnhancement = false;
                privacyMode = true;
                alertSensitivity = 5;
                confidenceThreshold = 0.60;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Settings Reset Done ✅")),
              );
            },
          ),

          const SizedBox(height: 25),

          // ✅ Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.all(14),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text(
                "Logout",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Switch Tile Widget
  Widget buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.green,
        secondary: Icon(icon, color: Colors.green),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }

  // ✅ Slider Tile Widget
  Widget buildSliderTile({
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(label, style: const TextStyle(color: Colors.green)),
            ],
          ),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: label,
            activeColor: Colors.green,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ✅ Simple Tap Tile Widget
  Widget buildSimpleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
