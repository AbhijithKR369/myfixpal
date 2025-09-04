import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart'; // Generated Firebase options
import 'home_dashboard_worker.dart';
import 'home_dashboard_user.dart';
import 'auth/register_screen.dart';
import 'auth/login_screen.dart'; // Import your login screen
import 'update_profile_screen.dart';
import 'update_profile_worker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable Storage emulator locally for development/testing
  // Remove or comment this line before releasing to production
  FirebaseStorage.instance.useStorageEmulator('localhost', 9199);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyFixPal',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/login', // Set login screen as the initial route
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home_user': (context) => const HomeDashboardUser(),
        '/home_worker': (context) => const HomeDashboardWorker(),
        '/update_profile': (context) => const UpdateProfileScreen(),
        '/update_profile_worker': (context) =>
            const UpdateProfileWorkerScreen(),
      },
    );
  }
}
