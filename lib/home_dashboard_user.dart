import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeDashboardUser extends StatefulWidget {
  const HomeDashboardUser({super.key});

  @override
  State<HomeDashboardUser> createState() => _HomeDashboardUserState();
}

class _HomeDashboardUserState extends State<HomeDashboardUser> {
  final TextEditingController pincodeController = TextEditingController();
  String? selectedProfession;
  final List<String> professions = [
    'Painter',
    'Electrician',
    'Carpenter',
    'Plumber',
  ];

  String? _existingPhotoUrl;
  String? _userName;
  String? _userMobile;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload profile data every time the widget rebuilds (e.g., after navigation back)
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _userName = data['fullName'] ?? "User";
        _userMobile = data['mobile'] ?? "";
        _existingPhotoUrl = data['profilePhotoUrl'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MyFixPal")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: CircleAvatar(
                radius: 40,
                backgroundImage: _existingPhotoUrl != null
                    ? NetworkImage(_existingPhotoUrl!)
                    : const AssetImage('assets/default_profile.png')
                          as ImageProvider,
              ),
              accountName: Text(_userName ?? "Loading..."),
              accountEmail: Text(_userMobile ?? ""),
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Update Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/update_profile');
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
            Text(
              "Welcome, ${_userName ?? 'User'}!",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }
}
