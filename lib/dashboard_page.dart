import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'detection_page_mlkit.dart';
import 'settings_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  StreamSubscription<AccelerometerEvent>? _accelerometerSub;
  DateTime _lastShakeTime = DateTime.now();

  static const double shakeThreshold = 23.0;
  static const int shakeCooldownMs = 2500;

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _accelerometerSub?.cancel();

    _accelerometerSub =
        accelerometerEvents.listen((AccelerometerEvent event) {

      if (!mounted || _isNavigating) return;

      double acceleration =
          event.x.abs() + event.y.abs() + event.z.abs();

      if (acceleration > shakeThreshold) {
        final now = DateTime.now();

        if (now.difference(_lastShakeTime).inMilliseconds >
            shakeCooldownMs) {

          _lastShakeTime = now;
          _openCamera();
        }
      }
    });
  }

  void _openCamera() async {
    if (_isNavigating) return;

    _isNavigating = true;

    await _accelerometerSub?.cancel();
    _accelerometerSub = null;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DetectionPageMLKit(),
      ),
    );

    _isNavigating = false;
    _startListening();
  }

  @override
  void dispose() {
    _accelerometerSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Second Sight"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Header
            const Text(
              "Dashboard",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "${now.day}/${now.month}/${now.year}",
              style: const TextStyle(
                color: Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 24),

            // Stats Grid
            Row(
              children: const [
                Expanded(
                  child: _StatCard(
                    title: "AI Engine",
                    value: "Active",
                    icon: Icons.memory,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: "System",
                    value: "Online",
                    icon: Icons.cloud_done,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: const [
                Expanded(
                  child: _StatCard(
                    title: "Obstacles",
                    value: "34",
                    icon: Icons.warning_amber,
                    color: Colors.redAccent,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: "Alerts Today",
                    value: "12",
                    icon: Icons.notifications_active,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            _ActionCard(
              icon: Icons.camera_alt,
              title: "Start Detection",
              subtitle: "Scan and detect objects using AI",
              onTap: _openCamera,
            ),

            const SizedBox(height: 16),

            _ActionCard(
              icon: Icons.settings,
              title: "Settings",
              subtitle: "Manage app preferences",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            const Text(
              "AI Tip",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                "Shake your phone firmly while on this screen to instantly launch the AI detection camera.",
                style: TextStyle(
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------ STAT CARD ------------------

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------ ACTION CARD ------------------

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon,
                  color: const Color(0xFF4F46E5), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}