import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text('No user logged in')));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workers') // <-- Changed to 'workers' collection
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Worker data not found')),
          );
        }

        final data = snapshot.data!.data()! as Map<String, dynamic>;

        final existingPhotoUrl = data['profilePhotoUrl'];
        final workerName = data['fullName'] ?? "Worker";
        final workerMobile = data['mobile'] ?? "";

        return Scaffold(
          appBar: AppBar(title: const Text("MyFixPal Worker")),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  currentAccountPicture: CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        (existingPhotoUrl != null &&
                            existingPhotoUrl.isNotEmpty)
                        ? NetworkImage(existingPhotoUrl)
                        : const AssetImage('assets/default_profile.png')
                              as ImageProvider,
                  ),
                  accountName: Text(workerName),
                  accountEmail: Text(workerMobile),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
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
                  onTap: () async {
                    Navigator.pop(context);
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    }
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
                  "Welcome, $workerName!",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
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
                  items: professions
                      .map(
                        (job) => DropdownMenuItem(value: job, child: Text(job)),
                      )
                      .toList(),
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
      },
    );
  }
}
