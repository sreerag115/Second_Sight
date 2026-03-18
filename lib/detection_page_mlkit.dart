import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'app_settings.dart';
import 'database_helper.dart';

class DetectionPageMLKit extends StatefulWidget {
  const DetectionPageMLKit({super.key});

  @override
  State<DetectionPageMLKit> createState() => _DetectionPageMLKitState();
}

class _DetectionPageMLKitState extends State<DetectionPageMLKit>
    with WidgetsBindingObserver {
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
  int _processIntervalMs = 250;
  int _speechCooldownDynamicMs = _speechCooldownMs;

  int _poseFrameCount = 0;
  static const int _poseConfirmFrames = 5;

  final _settingsStore = const AppSettingsStore();
  AppSettings _settings = AppSettings.defaults;

  final _db = DatabaseHelper.instance;
  DateTime _lastDbLogTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _dbLogCooldownMs = 5000;

  bool _torchOn = false;
  DateTime _torchOnSince = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastTorchUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _torchMinUpdateIntervalMs = 1600;
  // 0..255 (Y plane). Lower => darker.
  static const int _torchOnThreshold = 40;
  static const int _torchOffThreshold = 115; // much higher than ON to avoid blinking
  static const int _torchRequiredConsecutiveChecks = 3;
  static const int _torchMinOnTimeMs = 6000;
  int _darkChecks = 0;
  int _brightChecks = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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

    _loadSettingsAndInit();
  }

  Future<void> _loadSettingsAndInit() async {
    _settings = await _settingsStore.load();
    _applySensitivity(_settings.alertSensitivity);
    await _initCamera();
  }

  void _applySensitivity(double sensitivity) {
    final s = sensitivity.clamp(1, 10);
    // Higher sensitivity => process more often + speak more often
    _processIntervalMs = (550 - (s * 40)).round().clamp(150, 550);
    _speechCooldownDynamicMs = (5200 - (s * 320)).round().clamp(1200, 5200);
  }

  // ✅ SMART SPEECH (NO SPAM + PRIORITY)
  Future<void> _speakSmart() async {
    if (!_settings.voiceAlerts) return;

    final now = DateTime.now();

    if (_isSpeaking) return;
    if (now.difference(_lastSpeechTime).inMilliseconds <
        _speechCooldownDynamicMs) {
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

    // Log real alerts to DB (rate-limited)
    if (message != "Path clear") {
      if (now.difference(_lastDbLogTime).inMilliseconds >= _dbLogCooldownMs) {
        _lastDbLogTime = now;
        try {
          await _db.logDetectionEvent(
            type: "alert",
            obstacleCount: detectedObjects,
            personDetected: personDetected,
            createdAt: now,
          );
        } catch (_) {}
      }
    }

    await _tts.speak(message);
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final backCamera =
        cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);

    _controller = CameraController(
      backCamera,
      // Better preview clarity without going "high" (keeps heat reasonable).
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();

    // Prefer camera-side improvements (cheap) over heavier ML work.
    try {
      await _controller!.setFocusMode(FocusMode.auto);
    } catch (_) {}
    try {
      await _controller!.setExposureMode(ExposureMode.auto);
    } catch (_) {}

    if (_settings.lowLightEnhancement) {
      try {
        // Bias towards brighter image when possible.
        final maxOffset = await _controller!.getMaxExposureOffset();
        final minOffset = await _controller!.getMinExposureOffset();
        final target = (maxOffset * 0.6).clamp(minOffset, maxOffset);
        await _controller!.setExposureOffset(target);
      } catch (_) {
        // Some devices/controllers don't support exposure controls.
      }
    }

    await _applyFlashlightFromSettings(force: true);

    _controller!.startImageStream(_processCameraImage);

    setState(() {});
  }

  Future<void> _applyFlashlightFromSettings({bool force = false}) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      if (!_settings.lowLightEnhancement) {
        if (force || _torchOn) {
          await controller.setFlashMode(FlashMode.off);
          _torchOn = false;
          _darkChecks = 0;
          _brightChecks = 0;
        }
        return;
      }

      // Low light enhancement enabled:
      // do NOT turn torch on immediately; we'll decide based on brightness.
      if (force) {
        await controller.setFlashMode(FlashMode.off);
        _torchOn = false;
        _torchOnSince = DateTime.fromMillisecondsSinceEpoch(0);
        _darkChecks = 0;
        _brightChecks = 0;
      }
    } catch (_) {
      // Some devices/cameras don't support torch.
    }
  }

  Future<void> _turnFlashlightOff() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.setFlashMode(FlashMode.off);
    } catch (_) {}
    _torchOn = false;
    _torchOnSince = DateTime.fromMillisecondsSinceEpoch(0);
    _darkChecks = 0;
    _brightChecks = 0;
  }

  int _estimateLuma(CameraImage image) {
    // Use Y plane (luminance) and sample sparsely for speed.
    final yPlane = image.planes.first;
    final bytes = yPlane.bytes;
    if (bytes.isEmpty) return 128;

    final int length = bytes.length;
    int sum = 0;
    int count = 0;
    // Sample ~1000 points max.
    final int step = (length / 1000).ceil().clamp(1, 5000);
    for (int i = 0; i < length; i += step) {
      sum += bytes[i];
      count++;
    }
    return count == 0 ? 128 : (sum / count).round();
  }

  Future<void> _updateTorchIfNeeded(CameraImage image) async {
    if (!_settings.lowLightEnhancement) return;

    final now = DateTime.now();
    if (now.difference(_lastTorchUpdate).inMilliseconds <
        _torchMinUpdateIntervalMs) {
      return;
    }
    _lastTorchUpdate = now;

    final controller = _controller;
    if (controller == null) return;

    final luma = _estimateLuma(image);

    // Debounce + hysteresis:
    // - Require several consecutive "dark" checks before turning ON.
    // - Require several consecutive "bright" checks before turning OFF.
    // - Once ON, keep ON for a minimum time (torch makes the scene brighter,
    //   so without this it can oscillate).
    if (luma <= _torchOnThreshold) {
      _darkChecks = (_darkChecks + 1).clamp(0, _torchRequiredConsecutiveChecks);
      _brightChecks = 0;
    } else if (luma >= _torchOffThreshold) {
      _brightChecks =
          (_brightChecks + 1).clamp(0, _torchRequiredConsecutiveChecks);
      _darkChecks = 0;
    } else {
      // In-between: decay counters slowly.
      _darkChecks = (_darkChecks - 1).clamp(0, _torchRequiredConsecutiveChecks);
      _brightChecks =
          (_brightChecks - 1).clamp(0, _torchRequiredConsecutiveChecks);
    }

    final bool shouldTurnOn =
        !_torchOn && _darkChecks >= _torchRequiredConsecutiveChecks;
    final bool allowedToTurnOff = _torchOn &&
        now.difference(_torchOnSince).inMilliseconds >= _torchMinOnTimeMs;
    final bool shouldTurnOff = allowedToTurnOff &&
        _brightChecks >= _torchRequiredConsecutiveChecks;

    try {
      if (shouldTurnOn) {
        await controller.setFlashMode(FlashMode.torch);
        _torchOn = true;
        _torchOnSince = now;
        _darkChecks = 0;
        _brightChecks = 0;
      } else if (shouldTurnOff) {
        await controller.setFlashMode(FlashMode.off);
        _torchOn = false;
        _torchOnSince = DateTime.fromMillisecondsSinceEpoch(0);
        _darkChecks = 0;
        _brightChecks = 0;
      }
    } catch (_) {
      // Ignore if torch unsupported or camera state changes.
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;

    if (DateTime.now().difference(_lastRun).inMilliseconds <
        _processIntervalMs) return;
    _lastRun = DateTime.now();

    _isDetecting = true;

    // Auto torch in dark environments (only if enabled).
    await _updateTorchIfNeeded(image);

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
      detectedObjects = objects.where((obj) {
        if (obj.labels.isEmpty) return true;
        return obj.labels.any(
          (l) => l.confidence >= _settings.confidenceThreshold,
        );
      }).length;
    });

    // ✅ OPTIMIZED VOICE CALL
    _speakSmart();

    // ✅ VIBRATION/HAPTIC ALERTS
    if (_settings.vibrationAlerts && (personDetected || detectedObjects > 0)) {
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}
    }

    _isDetecting = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Safety: never leave flashlight on in background.
      _turnFlashlightOff();

      // Stop streaming when app is not visible.
      if (_settings.privacyMode) {
        try {
          controller.stopImageStream();
        } catch (_) {}
      }
    } else if (state == AppLifecycleState.resumed) {
      // Reload latest settings (in case user changed them)
      _settingsStore.load().then((latest) {
        _settings = latest;
        _applySensitivity(_settings.alertSensitivity);
        _applyFlashlightFromSettings();
      });

      if (_settings.privacyMode) {
        // Resume streaming.
        try {
          if (!controller.value.isStreamingImages) {
            controller.startImageStream(_processCameraImage);
          }
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _turnFlashlightOff();
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
              obj.labels.first.confidence >= _settings.confidenceThreshold) {
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
