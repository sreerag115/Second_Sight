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

  static const double shakeThreshold = 23.0; // firmer shake
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

      if (!mounted) return;
      if (_isNavigating) return;

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

    // STOP listening immediately
    await _accelerometerSub?.cancel();
    _accelerometerSub = null;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DetectionPageMLKit(),
      ),
    );

    // Restart listening when returning
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Second Sight"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [

            Text(
              "Welcome 👋",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Text(
              "Shake firmly to open camera",
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
              ),
            ),

            SizedBox(height: 32),

            _DashboardContent(),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        _DashboardCard(
          icon: Icons.camera_alt,
          title: "Start Detection",
          subtitle: "Scan and detect objects using AI",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DetectionPageMLKit(),
              ),
            );
          },
        ),

        SizedBox(height: 20),

        _DashboardCard(
          icon: Icons.settings,
          title: "Settings",
          subtitle: "App preferences and configuration",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardCard({
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
              child: Icon(
                icon,
                color: const Color(0xFF4F46E5),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}