import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class DetectionPage extends StatefulWidget {
  const DetectionPage({super.key});

  @override
  State<DetectionPage> createState() => _DetectionPageState();
}

class _DetectionPageState extends State<DetectionPage> {
  // ✅ Camera variables
  CameraController? _controller;
  bool isCameraReady = false;

  // ✅ Zone variables
  String zone = "GREEN"; // GREEN, YELLOW, RED
  String statusText = "Safe Area";
  IconData statusIcon = Icons.check_circle;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  // ✅ CAMERA INIT (your same code)
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        debugPrint("No cameras found on device.");
        return;
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (!mounted) return;

      setState(() {
        isCameraReady = true;
      });
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // ✅ Zone change
  void changeZone(String newZone) {
    setState(() {
      zone = newZone;

      if (zone == "GREEN") {
        statusText = "Safe Area (No Alert)";
        statusIcon = Icons.check_circle;
      } else if (zone == "YELLOW") {
        statusText = "Caution (Warning Alert)";
        statusIcon = Icons.warning;
      } else {
        statusText = "Danger (Strong Alert)";
        statusIcon = Icons.dangerous;
      }
    });
  }

  Color zoneColor() {
    if (zone == "GREEN") return Colors.green;
    if (zone == "YELLOW") return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("Obstacle Detection"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),

          // ✅ CAMERA PREVIEW
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(15),
              ),
              child: (isCameraReady &&
                      _controller != null &&
                      _controller!.value.isInitialized)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: CameraPreview(_controller!),
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
          ),

          const SizedBox(height: 15),

          // ✅ Status Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: zoneColor().withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: zoneColor(), width: 2),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: zoneColor(), size: 35),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: zoneColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ✅ Zone Buttons (Demo Testing)
          const Text(
            "Test Zones (for demo)",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => changeZone("GREEN"),
                child: const Text("GREEN"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () => changeZone("YELLOW"),
                child: const Text("YELLOW"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => changeZone("RED"),
                child: const Text("RED"),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ✅ Voice Alert Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.all(15),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Voice Alert Triggered: $statusText"),
                    ),
                  );
                },
                icon: const Icon(Icons.volume_up),
                label: const Text(
                  "Play Voice Alert",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
