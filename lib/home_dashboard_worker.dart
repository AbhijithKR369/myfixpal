import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_activities/service_browse.dart';
import 'dashboard_activities/worker_profile_screen.dart';
import 'dashboard_activities/worker_jobs_screen.dart';
import 'package:myfixpal/dashboard_activities/worker_notification_screen.dart';

class HomeDashboardWorker extends StatefulWidget {
  const HomeDashboardWorker({super.key});
  @override
  State<HomeDashboardWorker> createState() => _HomeDashboardWorkerState();
}

class _HomeDashboardWorkerState extends State<HomeDashboardWorker> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const ServiceBrowseScreen(),
    const WorkerNotificationScreen(),
    const WorkerJobsScreen(),
    const WorkerProfileScreen(), // ✅ added missing screen
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF1B1E28),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD34E)),
            ),
          );
        }

        /*  final String workerName =
            (snapshot.hasData && snapshot.data?.data() != null)
            ? ((snapshot.data!.data() as Map<String, dynamic>)['fullName'] ??
                  'Worker')
            : 'Worker';
*/
        return Scaffold(
          /*   appBar: AppBar(
            title: Text("MyFixPal Worker - $workerName"),
            backgroundColor: const Color(0xFF222733),
            foregroundColor: Colors.white,
          ),*/
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            selectedItemColor: const Color(0xFFFFD34E),
            unselectedItemColor: Colors.white70,
            backgroundColor: const Color(0xFF222733),
            onTap: (index) {
              setState(() => _currentIndex = index);
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
