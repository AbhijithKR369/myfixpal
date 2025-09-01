import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class HomeDashboardWorker extends StatefulWidget {
  const HomeDashboardWorker({super.key});

  @override
  State<HomeDashboardWorker> createState() => _HomeDashboardWorkerState();
}

class _HomeDashboardWorkerState extends State<HomeDashboardWorker> {
  final TextEditingController pincodeController = TextEditingController();
  String? selectedProfession;
  final List<String> professions = [
    'Painter',
    'Electrician',
    'Carpenter',
    'Plumber',
  ];

  File? _profilePhoto;

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
                  setState(() {
                    _profilePhoto = File(pickedFile.path);
                  });
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
                  setState(() {
                    _profilePhoto = File(pickedFile.path);
                  });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MyFixPal Worker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushNamed(context, '/update_profile_worker');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: GestureDetector(
                onTap: _pickProfilePhoto,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: _profilePhoto != null
                      ? FileImage(_profilePhoto!)
                      : const AssetImage('assets/default_profile.png')
                            as ImageProvider,
                  child: _profilePhoto == null
                      ? const Icon(
                          Icons.add_a_photo,
                          size: 30,
                          color: Colors.white70,
                        )
                      : null,
                ),
              ),
              accountName: const Text("Worker Name"),
              accountEmail: const Text(""),
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Update Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/update_profile_worker');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome, Worker!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              "Search Workers",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Profession',
                border: OutlineInputBorder(),
              ),
              initialValue: selectedProfession,
              items: professions.map((job) {
                return DropdownMenuItem(value: job, child: Text(job));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedProfession = val;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pincodeController,
              decoration: const InputDecoration(
                labelText: 'Enter Pincode',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (selectedProfession != null &&
                    pincodeController.text.isNotEmpty) {
                  Navigator.pushNamed(
                    context,
                    '/search_results',
                    arguments: {
                      'profession': selectedProfession,
                      'pincode': pincodeController.text,
                    },
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please select profession and enter pincode',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Search'),
            ),
            const SizedBox(height: 20),
            // Add your quick services or recent requests here...
          ],
        ),
      ),
    );
  }
}
