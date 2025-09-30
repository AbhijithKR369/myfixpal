import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import your existing ServiceBrowseScreen here
import 'dashboard_activities/service_browse.dart';
import 'dashboard_activities/worker_profile_screen.dart'; // Use this import only

// Placeholder for Notifications
class WorkerNotificationScreen extends StatelessWidget {
  const WorkerNotificationScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Notifications'));
}

// Placeholder for Worker Jobs/Requests
class WorkerJobListScreen extends StatelessWidget {
  const WorkerJobListScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Job List & Requests'));
}

// Remove this placeholder WorkerProfileScreen class completely.

// Rest of your code unchanged...

class HomeDashboardWorker extends StatefulWidget {
  const HomeDashboardWorker({super.key});
  @override
  State<HomeDashboardWorker> createState() => _HomeDashboardWorkerState();
}

class _HomeDashboardWorkerState extends State<HomeDashboardWorker> {
  int _currentIndex = 0;

  // Exclude profile screen from tab views because we will navigate to it separately
  late final List<Widget> _screens = [
    const ServiceBrowseScreen(),
    const WorkerNotificationScreen(),
    const WorkerJobListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('No user logged in')));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workers')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final String workerName =
            (snapshot.hasData && snapshot.data?.data() != null)
            ? ((snapshot.data!.data() as Map<String, dynamic>)['fullName'] ??
                  'Worker')
            : 'Worker';

        return Scaffold(
          appBar: AppBar(title: Text("MyFixPal Worker - $workerName")),
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            selectedItemColor: const Color(0xFFFFD34E),
            unselectedItemColor: Colors.white70,
            backgroundColor: const Color(0xFF222733),
            onTap: (index) {
              if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkerProfileScreen(),
                  ),
                );
              } else {
                setState(() => _currentIndex = index);
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.miscellaneous_services),
                label: 'Services',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications),
                label: 'Notifications',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment),
                label: 'Jobs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
