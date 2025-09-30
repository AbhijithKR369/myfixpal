import 'package:flutter/material.dart';
import 'package:myfixpal/dashboard_activities/user_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_activities/service_browse.dart';

// Placeholder for the notification screen
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Notifications'));
}

// Placeholder for the top-rated workers screen
class TopRatedWorkersScreen extends StatelessWidget {
  const TopRatedWorkersScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Top Rated Workers'));
}

class HomeDashboardUser extends StatefulWidget {
  const HomeDashboardUser({super.key});

  @override
  State<HomeDashboardUser> createState() => _HomeDashboardUserState();
}

class _HomeDashboardUserState extends State<HomeDashboardUser> {
  int _currentIndex = 0;

  // Screens for the bottom navigation bar
  final List<Widget> _screens = const [
    ServiceBrowseScreen(), // Imported from service_browse.dart
    NotificationScreen(),
    TopRatedWorkersScreen(),
    UserProfileScreen(), // Imported from user_profile_screen.dart
  ];

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text('No user logged in')));
    }

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFFFD34E), // Accent color
        unselectedItemColor: Colors.white70,
        backgroundColor: const Color(0xFF222733), // Brand background
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Services'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Top Rated'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
