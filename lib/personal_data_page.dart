import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'emergency_contacts_store.dart';

class PersonalDataPage extends StatefulWidget {
  const PersonalDataPage({super.key});

  @override
  State<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends State<PersonalDataPage> {
  static const _kEmail = "loggedInEmail";
  static const _kName = "profile_name";
  static const _kAge = "profile_age";
  static const _kPhone = "profile_phone";
  static const _kAddress = "profile_address";
  static const _kProfilePhotoPath = "profile_photo_path";

  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  final _emergencyStore = const EmergencyContactsStore();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String? _profilePhotoPath;
  List<EmergencyContact> _emergencyContacts = const [];

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final email = await _storage.read(key: _kEmail);
    final name = await _storage.read(key: _kName);
    final age = await _storage.read(key: _kAge);
    final phone = await _storage.read(key: _kPhone);
    final address = await _storage.read(key: _kAddress);
    final photoPath = await _storage.read(key: _kProfilePhotoPath);
    final emergencyContacts = await _emergencyStore.load();

    if (!mounted) return;
    setState(() {
      _emailController.text = email ?? "";
      _nameController.text = name ?? "";
      _ageController.text = age ?? "";
      _phoneController.text = phone ?? "";
      _addressController.text = address ?? "";
      _profilePhotoPath = photoPath;
      _emergencyContacts = emergencyContacts;
      _loading = false;
    });
  }

  Future<void> _refreshEmergencyContacts() async {
    final emergencyContacts = await _emergencyStore.load();
    if (!mounted) return;
    setState(() => _emergencyContacts = emergencyContacts);
  }

  Future<void> _addOrEditEmergencyContact({int? editIndex}) async {
    final isEdit = editIndex != null;
    final existing = isEdit ? _emergencyContacts[editIndex] : null;

    final nameController =
        TextEditingController(text: existing?.name ?? "");
    final phoneController =
        TextEditingController(text: existing?.phone ?? "");
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? "Edit Emergency Contact" : "Add Emergency Contact"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r"[a-zA-Z\s\.\-']"),
                    ),
                    LengthLimitingTextInputFormatter(60),
                  ],
                  decoration: const InputDecoration(
                    labelText: "Name",
                    hintText: "Contact name",
                  ),
                  validator: (v) {
                    final value = (v ?? "").trim();
                    if (value.isEmpty) return "Name is required";
                    if (value.length < 2) return "Name is too short";
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    hintText: "Digits only",
                  ),
                  validator: (v) {
                    final value = (v ?? "").trim();
                    if (value.isEmpty) return "Phone number is required";
                    if (value.length < 8) return "Too short";
                    if (value.length > 15) return "Too long";
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final ok = formKey.currentState?.validate() ?? false;
                if (!ok) return;
                Navigator.pop(context, true);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (result != true) return;
    final contact = EmergencyContact(
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
    );

    if (isEdit) {
      await _emergencyStore.updateAt(editIndex, contact);
    } else {
      await _emergencyStore.add(contact);
    }
    await _refreshEmergencyContacts();
  }

  Future<void> _deleteEmergencyContact(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Contact"),
        content: const Text("Are you sure you want to delete this emergency contact?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _emergencyStore.deleteAt(index);
    await _refreshEmergencyContacts();
  }

  Future<void> _pickProfilePhoto() async {
    final XFile? picked =
        await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final ext = p.extension(picked.path);
    final fileName = "profile_photo${ext.isNotEmpty ? ext : ".jpg"}";
    final savedPath = p.join(dir.path, fileName);

    await File(picked.path).copy(savedPath);
    await _storage.write(key: _kProfilePhotoPath, value: savedPath);

    if (!mounted) return;
    setState(() {
      _profilePhotoPath = savedPath;
    });
  }

  Future<void> _removeProfilePhoto() async {
    final existing = _profilePhotoPath;
    await _storage.delete(key: _kProfilePhotoPath);

    if (existing != null) {
      try {
        final f = File(existing);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _profilePhotoPath = null;
    });
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _saving = true);
    try {
      await _storage.write(key: _kName, value: _nameController.text.trim());
      await _storage.write(key: _kAge, value: _ageController.text.trim());
      await _storage.write(key: _kPhone, value: _phoneController.text.trim());
      await _storage.write(
          key: _kAddress, value: _addressController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Saved")),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Personal Data"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const Text(
                        "Your Information",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Update your personal details below. Some fields have strict input rules (for example: phone number must be digits only).",
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 22),

                      _buildProfilePhotoSection(),
                      const SizedBox(height: 18),

                      _buildEmergencyContactsSection(),
                      const SizedBox(height: 18),

                      _buildField(
                        label: "Email",
                        hint: "you@example.com",
                        icon: Icons.email,
                        controller: _emailController,
                        enabled: false,
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        label: "Name",
                        hint: "Your full name",
                        icon: Icons.person,
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r"[a-zA-Z\s\.\-']"),
                          ),
                          LengthLimitingTextInputFormatter(60),
                        ],
                        validator: (v) {
                          final value = (v ?? "").trim();
                          if (value.isEmpty) return "Name is required";
                          if (value.length < 2) {
                            return "Name is too short";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: "Age",
                              hint: "e.g. 21",
                              icon: Icons.cake,
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                              validator: (v) {
                                final raw = (v ?? "").trim();
                                if (raw.isEmpty) return "Age is required";
                                final age = int.tryParse(raw);
                                if (age == null) return "Enter a valid number";
                                if (age < 1 || age > 120) {
                                  return "Age must be 1–120";
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildField(
                              label: "Phone Number",
                              hint: "Digits only",
                              icon: Icons.phone,
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(15),
                              ],
                              validator: (v) {
                                final raw = (v ?? "").trim();
                                if (raw.isEmpty) {
                                  return "Phone number is required";
                                }
                                if (raw.length < 8) {
                                  return "Too short";
                                }
                                if (raw.length > 15) {
                                  return "Too long";
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        label: "Address",
                        hint: "Street, city, etc.",
                        icon: Icons.location_on,
                        controller: _addressController,
                        keyboardType: TextInputType.streetAddress,
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(140),
                        ],
                        maxLines: 3,
                        validator: (v) {
                          final value = (v ?? "").trim();
                          if (value.isEmpty) return "Address is required";
                          if (value.length < 6) return "Address is too short";
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(_saving ? "Saving..." : "Save"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF4F46E5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lock,
                              size: 20,
                              color: Color(0xFF4F46E5),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "These details are saved locally on this device for your convenience.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    final photoPath = _profilePhotoPath;
    final hasPhoto = photoPath != null && File(photoPath).existsSync();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: const Color(0xFF4F46E5).withOpacity(0.12),
            backgroundImage: hasPhoto ? FileImage(File(photoPath)) : null,
            child: hasPhoto
                ? null
                : const Icon(Icons.person, size: 34, color: Color(0xFF4F46E5)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Profile Photo",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  "Add a photo to personalize your profile.",
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              ElevatedButton(
                onPressed: _pickProfilePhoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(hasPhoto ? "Change" : "Add"),
              ),
              const SizedBox(height: 8),
              if (hasPhoto)
                TextButton(
                  onPressed: _removeProfilePhoto,
                  child: const Text(
                    "Remove",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Emergency Contacts",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Add people to contact in emergencies.",
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _addOrEditEmergencyContact(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text("Add"),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_emergencyContacts.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                "No emergency contacts yet.",
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            )
          else
            ..._emergencyContacts.asMap().entries.map((entry) {
              final idx = entry.key;
              final c = entry.value;
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(top: 10),
                color: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEEF2FF),
                    child: Icon(Icons.phone, color: Color(0xFF4F46E5)),
                  ),
                  title: Text(
                    c.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(c.phone),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: "Edit",
                        onPressed: () => _addOrEditEmergencyContact(editIndex: idx),
                        icon: const Icon(Icons.edit, color: Color(0xFF4F46E5)),
                      ),
                      IconButton(
                        tooltip: "Delete",
                        onPressed: () => _deleteEmergencyContact(idx),
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF4F46E5),
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
