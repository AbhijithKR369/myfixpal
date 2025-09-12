import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateProfileWorkerScreen extends StatefulWidget {
  const UpdateProfileWorkerScreen({super.key});

  @override
  State<UpdateProfileWorkerScreen> createState() =>
      _UpdateProfileWorkerScreenState();
}

class _UpdateProfileWorkerScreenState extends State<UpdateProfileWorkerScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController aadhaarController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();

  String? selectedProfession;
  final List<String> professions = [
    'Painter',
    'Electrician',
    'Carpenter',
    'Plumber',
  ];

  File? _profilePhoto;
  String? _existingPhotoUrl;
  bool _isLoading = false;

  static const Color backgroundColor = Color(0xFF222733);
  static const Color accentColor = Color(0xFFFFD34E);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        nameController.text = data['fullName'] ?? '';
        dobController.text = data['dob'] ?? '';
        addressController.text = data['address'] ?? '';
        locationController.text = data['location'] ?? '';
        pincodeController.text = data['pincode'] ?? '';
        aadhaarController.text = data['aadhaar'] ?? '';
        mobileController.text = data['mobile'] ?? '';
        whatsappController.text = data['whatsapp'] ?? '';
        selectedProfession = data['profession'];
        _existingPhotoUrl = data['profilePhotoUrl'];
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickProfilePhoto() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () async {
                Navigator.pop(ctx);
                final pickedFile = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                );
                if (pickedFile != null) {
                  setState(() => _profilePhoto = File(pickedFile.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final pickedFile = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                );
                if (pickedFile != null) {
                  setState(() => _profilePhoto = File(pickedFile.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dobController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not logged in')));
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? photoUrl = _existingPhotoUrl;

      if (_profilePhoto != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('worker_profile_photos')
            .child('${user.uid}.jpg');
        final uploadTask = storageRef.putFile(_profilePhoto!);
        final snapshot = await uploadTask.whenComplete(() {});
        photoUrl = await snapshot.ref.getDownloadURL();
      }

      final updatedData = <String, dynamic>{
        'fullName': nameController.text.trim(),
        'dob': dobController.text.trim(),
        'address': addressController.text.trim(),
        'location': locationController.text.trim(),
        'pincode': pincodeController.text.trim(),
        'aadhaar': aadhaarController.text.trim(),
        'mobile': mobileController.text.trim(),
        'whatsapp': whatsappController.text.trim(),
        'profession': selectedProfession,
        if (photoUrl != null) 'profilePhotoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(updatedData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: accentColor)
            : null,
        filled: true,
        fillColor: backgroundColor.withAlpha((0.8 * 255).toInt()),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white24, width: 1),
        ),
      ),
    );
  }

  // static const Color backgroundColor = Color(0xFF222733);
  // static const Color accentColor = Color(0xFFFFD34E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Worker Profile'),
        backgroundColor: backgroundColor,
      ),
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _profilePhoto != null
                            ? FileImage(_profilePhoto!)
                            : (_existingPhotoUrl != null
                                  ? NetworkImage(_existingPhotoUrl!)
                                        as ImageProvider
                                  : const AssetImage(
                                      'assets/default_profile.png',
                                    )),
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt, color: accentColor),
                        onPressed: _pickProfilePhoto,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: nameController,
                  labelText: 'Name',
                  prefixIcon: Icons.person,
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: dobController,
                  labelText: 'Date of Birth',
                  prefixIcon: Icons.calendar_today,
                  readOnly: true,
                  onTap: _selectDateOfBirth,
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: addressController,
                  labelText: 'Address',
                  prefixIcon: Icons.home,
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: locationController,
                  labelText: 'Location / City',
                  prefixIcon: Icons.location_city,
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: pincodeController,
                  labelText: 'Pincode',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.pin_drop,
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: aadhaarController,
                  labelText: 'Aadhaar Number',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.credit_card,
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: mobileController,
                  labelText: 'Mobile Number',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_android,
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: whatsappController,
                  labelText: 'WhatsApp Number',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.message,
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Job / Profession',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: selectedProfession,
                  items: professions
                      .map(
                        (job) => DropdownMenuItem(value: job, child: Text(job)),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() => selectedProfession = val);
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black87,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black87)
                      : const Text('Save'),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
