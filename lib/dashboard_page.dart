import 'package:flutter/material.dart';
import 'login_page.dart';
import 'detection_page.dart';
import 'camera_page.dart';
import 'settings_page.dart';
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Second Sight")),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.camera_alt),
          label: const Text("Start Obstacle Detection"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CameraPage()),
            );
          },
        ),
      ),
    );
  }
}


class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            const Text(
              "Welcome to Second Sight",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 40),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green, size: 35),
                title: const Text("Start Obstacle Detection"),
                subtitle: const Text("Camera + Voice Alerts"),
               onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const DetectionPage()),
  );
},

              ),
            ),

            const SizedBox(height: 15),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: const ListTile(
                leading: Icon(Icons.history, color: Colors.green, size: 35),
                title: Text("History"),
                subtitle: Text("View previous detections"),
              ),
            ),

            const SizedBox(height: 15),

           Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
    leading: const Icon(Icons.settings, color: Colors.green, size: 35),
    title: const Text("Settings"),
    subtitle: const Text("Voice, vibration, sensitivity"),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      );
    },
  ),
),

          ],
        ),
      ),
    );
  }
}
