import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EmergencyContact {
  final String name;
  final String phone;

  const EmergencyContact({
    required this.name,
    required this.phone,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: (json['name'] as String? ?? '').trim(),
      phone: (json['phone'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
      };
}

class EmergencyContactsStore {
  static const _kEmergencyContacts = "emergency_contacts_v1";
  final FlutterSecureStorage _storage;

  const EmergencyContactsStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<List<EmergencyContact>> load() async {
    final raw = await _storage.read(key: _kEmergencyContacts);
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final contacts = decoded
          .whereType<Map>()
          .map((m) => EmergencyContact.fromJson(
              m.map((k, v) => MapEntry(k.toString(), v))))
          .where((c) => c.name.isNotEmpty && c.phone.isNotEmpty)
          .toList(growable: false);
      return contacts;
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<EmergencyContact> contacts) async {
    final cleaned = contacts
        .map((c) => EmergencyContact(name: c.name.trim(), phone: c.phone.trim()))
        .where((c) => c.name.isNotEmpty && c.phone.isNotEmpty)
        .toList(growable: false);

    final raw = jsonEncode(cleaned.map((c) => c.toJson()).toList());
    await _storage.write(key: _kEmergencyContacts, value: raw);
  }

  Future<void> add(EmergencyContact contact) async {
    final current = await load();
    final next = [...current, contact];
    await save(next);
  }

  Future<void> updateAt(int index, EmergencyContact contact) async {
    final current = await load();
    if (index < 0 || index >= current.length) return;
    final mutable = current.toList();
    mutable[index] = contact;
    await save(mutable);
  }

  Future<void> deleteAt(int index) async {
    final current = await load();
    if (index < 0 || index >= current.length) return;
    final mutable = current.toList()..removeAt(index);
    await save(mutable);
  }
}

