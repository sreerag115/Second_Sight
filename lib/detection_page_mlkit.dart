import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

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

  DateTime _lastRun = DateTime.now();

  // temporal pose validation
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

    _initCamera();
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

        // ✅ FIXED: correct reference dimension
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

    _isDetecting = false;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _objectDetector.close();
    _poseDetector.close();
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
      appBar: AppBar(title: const Text("Obstacle Detection")),
      body: Stack(
        children: [
          CameraPreview(_controller!),

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
                        color: Colors.orange,
                        width: 3,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      color: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: personDetected || detectedObjects > 0
                    ? Colors.red
                    : Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                personDetected
                    ? "🚶 Person $personDistance"
                    : detectedObjects > 0
                        ? "🚧 Obstacles: $detectedObjects"
                        : "✅ Path clear",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
