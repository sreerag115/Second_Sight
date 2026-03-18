import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppSettings {
  final bool voiceAlerts;
  final bool vibrationAlerts;
  final bool lowLightEnhancement;
  final bool privacyMode;
  final double alertSensitivity; // 1..10
  final double confidenceThreshold; // 0.30..0.95

  const AppSettings({
    required this.voiceAlerts,
    required this.vibrationAlerts,
    required this.lowLightEnhancement,
    required this.privacyMode,
    required this.alertSensitivity,
    required this.confidenceThreshold,
  });

  static const defaults = AppSettings(
    voiceAlerts: true,
    vibrationAlerts: true,
    lowLightEnhancement: false,
    privacyMode: true,
    alertSensitivity: 5,
    confidenceThreshold: 0.60,
  );

  AppSettings copyWith({
    bool? voiceAlerts,
    bool? vibrationAlerts,
    bool? lowLightEnhancement,
    bool? privacyMode,
    double? alertSensitivity,
    double? confidenceThreshold,
  }) {
    return AppSettings(
      voiceAlerts: voiceAlerts ?? this.voiceAlerts,
      vibrationAlerts: vibrationAlerts ?? this.vibrationAlerts,
      lowLightEnhancement: lowLightEnhancement ?? this.lowLightEnhancement,
      privacyMode: privacyMode ?? this.privacyMode,
      alertSensitivity: alertSensitivity ?? this.alertSensitivity,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
    );
  }
}

class AppSettingsStore {
  static const _kVoiceAlerts = "settings_voiceAlerts";
  static const _kVibrationAlerts = "settings_vibrationAlerts";
  static const _kLowLightEnhancement = "settings_lowLightEnhancement";
  static const _kPrivacyMode = "settings_privacyMode";
  static const _kAlertSensitivity = "settings_alertSensitivity";
  static const _kConfidenceThreshold = "settings_confidenceThreshold";

  final FlutterSecureStorage _storage;

  const AppSettingsStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<AppSettings> load() async {
    final voice = await _storage.read(key: _kVoiceAlerts);
    final vibration = await _storage.read(key: _kVibrationAlerts);
    final lowLight = await _storage.read(key: _kLowLightEnhancement);
    final privacy = await _storage.read(key: _kPrivacyMode);
    final sensitivity = await _storage.read(key: _kAlertSensitivity);
    final threshold = await _storage.read(key: _kConfidenceThreshold);

    return AppSettings(
      voiceAlerts: _parseBool(voice, AppSettings.defaults.voiceAlerts),
      vibrationAlerts:
          _parseBool(vibration, AppSettings.defaults.vibrationAlerts),
      lowLightEnhancement:
          _parseBool(lowLight, AppSettings.defaults.lowLightEnhancement),
      privacyMode: _parseBool(privacy, AppSettings.defaults.privacyMode),
      alertSensitivity: _parseDouble(
        sensitivity,
        AppSettings.defaults.alertSensitivity,
      ),
      confidenceThreshold: _parseDouble(
        threshold,
        AppSettings.defaults.confidenceThreshold,
      ),
    );
  }

  Future<void> save(AppSettings settings) async {
    await _storage.write(key: _kVoiceAlerts, value: settings.voiceAlerts.toString());
    await _storage.write(
        key: _kVibrationAlerts, value: settings.vibrationAlerts.toString());
    await _storage.write(
        key: _kLowLightEnhancement,
        value: settings.lowLightEnhancement.toString());
    await _storage.write(key: _kPrivacyMode, value: settings.privacyMode.toString());
    await _storage.write(
        key: _kAlertSensitivity, value: settings.alertSensitivity.toString());
    await _storage.write(
        key: _kConfidenceThreshold,
        value: settings.confidenceThreshold.toString());
  }

  Future<void> update({
    bool? voiceAlerts,
    bool? vibrationAlerts,
    bool? lowLightEnhancement,
    bool? privacyMode,
    double? alertSensitivity,
    double? confidenceThreshold,
  }) async {
    final current = await load();
    final next = current.copyWith(
      voiceAlerts: voiceAlerts,
      vibrationAlerts: vibrationAlerts,
      lowLightEnhancement: lowLightEnhancement,
      privacyMode: privacyMode,
      alertSensitivity: alertSensitivity,
      confidenceThreshold: confidenceThreshold,
    );
    await save(next);
  }

  static bool _parseBool(String? raw, bool fallback) {
    if (raw == null) return fallback;
    return raw.toLowerCase() == "true";
  }

  static double _parseDouble(String? raw, double fallback) {
    if (raw == null) return fallback;
    return double.tryParse(raw) ?? fallback;
  }
}

