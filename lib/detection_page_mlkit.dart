import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter_tts/flutter_tts.dart';

class DetectionPageMLKit extends StatefulWidget {
  const DetectionPageMLKit({super.key});

  @override
  State<DetectionPageMLKit> createState() => _DetectionPageMLKitState();
}

class _DetectionPageMLKitState extends State<DetectionPageMLKit> {
  CameraController? _controller;
  bool _isDetecting = false;

  int detectedObjects = 0;
  bool personDetected = false;
  String personDistance = "";

  List<DetectedObject> detected = [];

  late final ObjectDetector _objectDetector;
  late final PoseDetector _poseDetector;

  // ✅ VOICE SYSTEM (OPTIMIZED)
  late FlutterTts _tts;
  bool _isSpeaking = false;
  String _lastAnnouncement = "";
  DateTime _lastSpeechTime = DateTime.now();
  static const int _speechCooldownMs = 2500;

  DateTime _lastRun = DateTime.now();

  int _poseFrameCount = 0;
  static const int _poseConfirmFrames = 5;

  @override
  void initState() {
    super.initState();

    _objectDetector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.stream,
        classifyObjects: true,
        multipleObjects: true,
      ),
    );

    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
      ),
    );

    // ✅ TTS setup
    _tts = FlutterTts();
    _tts.setLanguage("en-US");
    _tts.setSpeechRate(0.45);
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _initCamera();
  }

  // ✅ SMART SPEECH (NO SPAM + PRIORITY)
  Future<void> _speakSmart() async {
    final now = DateTime.now();

    if (_isSpeaking) return;
    if (now.difference(_lastSpeechTime).inMilliseconds < _speechCooldownMs) {
      return;
    }

    String message;

    if (personDetected) {
      message = "Person $personDistance";
    } else if (detectedObjects > 0) {
      message = "Obstacle ahead";
    } else {
      message = "Path clear";
    }

    // speak only if state changed
    if (message == _lastAnnouncement) return;

    _lastAnnouncement = message;
    _lastSpeechTime = now;
    _isSpeaking = true;

    await _tts.speak(message);
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final backCamera =
        cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);

    _controller = CameraController(
      backCamera,
      ResolutionPreset.low,
      enableAudio: false,
    );

    await _controller!.initialize();
    _controller!.startImageStream(_processCameraImage);

    setState(() {});
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;

    if (DateTime.now().difference(_lastRun).inMilliseconds < 250) return;
    _lastRun = DateTime.now();

    _isDetecting = true;

    final WriteBuffer buffer = WriteBuffer();
    for (final plane in image.planes) {
      buffer.putUint8List(plane.bytes);
    }

    final bytes = buffer.done().buffer.asUint8List();

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.yuv420,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );

    final objects = await _objectDetector.processImage(inputImage);
    final poses = await _poseDetector.processImage(inputImage);

    bool detectedPersonNow = false;
    String distanceLabel = "";

    if (poses.isNotEmpty) {
      _poseFrameCount++;

      final pose = poses.first;
      final head = pose.landmarks[PoseLandmarkType.nose];
      final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
      final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

      if (head != null && leftAnkle != null && rightAnkle != null) {
        final footY = (leftAnkle.y + rightAnkle.y) / 2;
        final pixelHeight = (footY - head.y).abs();

        final heightRatio = pixelHeight / image.width;

        if (heightRatio > 0.55) {
          distanceLabel = "very close";
        } else if (heightRatio > 0.38) {
          distanceLabel = "close";
        } else if (heightRatio > 0.22) {
          distanceLabel = "medium";
        } else {
          distanceLabel = "far";
        }

        detectedPersonNow = true;
      }
    } else {
      _poseFrameCount = 0;
    }

    personDetected =
        detectedPersonNow && _poseFrameCount >= _poseConfirmFrames;
    personDistance = distanceLabel;

    setState(() {
      detected = objects;
      detectedObjects = objects.length;
    });

    // ✅ OPTIMIZED VOICE CALL
    _speakSmart();

    _isDetecting = false;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _objectDetector.close();
    _poseDetector.close();
    _tts.stop();
    super.dispose();
  }

 @override
Widget build(BuildContext context) {
  if (_controller == null || !_controller!.value.isInitialized) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  final previewSize = _controller!.value.previewSize!;
  final screenSize = MediaQuery.of(context).size;

  final scaleX = screenSize.width / previewSize.height;
  final scaleY = screenSize.height / previewSize.width;

  return Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      title: const Text("AI Obstacle Detection"),
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    body: Stack(
      children: [
        CameraPreview(_controller!),

        /// Bounding Boxes
        ...detected.map((obj) {
          final rect = obj.boundingBox;

          String label = "Obstacle";
          if (obj.labels.isNotEmpty &&
              obj.labels.first.confidence > 0.7) {
            label = obj.labels.first.text;
          }

          return Positioned(
            left: rect.left * scaleX,
            top: rect.top * scaleY,
            width: rect.width * scaleX,
            height: rect.height * scaleY,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF4F46E5),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Positioned(
                  top: -2,
                  left: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        /// Modern Status Panel
        Positioned(
          bottom: 30,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: personDetected || detectedObjects > 0
                    ? Colors.redAccent
                    : Colors.greenAccent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  personDetected || detectedObjects > 0
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle,
                  color: personDetected || detectedObjects > 0
                      ? Colors.redAccent
                      : Colors.greenAccent,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    personDetected
                        ? "Person $personDistance"
                        : detectedObjects > 0
                            ? "$detectedObjects obstacle(s) detected"
                            : "Path clear",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
}
