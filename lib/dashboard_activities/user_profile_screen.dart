import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  static const Color backgroundColor = Color(0xFF222733);
  static const Color accentColor = Color(0xFFFFD34E);

  void _changePassword(BuildContext context) {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          title: const Text(
            'Change Password',
            style: TextStyle(color: accentColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildPasswordField('Current Password', currentPassController),
                const SizedBox(height: 12),
                _buildPasswordField('New Password', newPassController),
                const SizedBox(height: 12),
                _buildPasswordField('Confirm Password', confirmPassController),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: accentColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black87,
              ),
              onPressed: () async {
                final currentPass = currentPassController.text.trim();
                final newPass = newPassController.text.trim();
                final confirmPass = confirmPassController.text.trim();

                if (newPass != confirmPass) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New passwords do not match')),
                  );
                  return;
                }
                if (newPass.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password should be at least 6 characters'),
                    ),
                  );
                  return;
                }
                try {
                  final user = FirebaseAuth.instance.currentUser!;
                  final cred = EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPass,
                  );
                  await user.reauthenticateWithCredential(cred);
                  await user.updatePassword(newPass);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully'),
                      ),
                    );
                    Navigator.of(ctx).pop();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to change password: $e')),
                  );
                }
              },
              child: const Text('Change'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: backgroundColor.withOpacity(0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
      ),
    );
  }

  Future<void> _launchGmail(BuildContext context) async {
    final Uri gmailUri = Uri.parse(
      'https://mail.google.com/mail/?view=cm&to=abhijithkraspd@gmail.com&su=Support%20Request',
    );
    if (await canLaunchUrl(gmailUri)) {
      await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open Gmail. Please install or configure the Gmail app.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text('No user logged in')));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: backgroundColor,
            body: Center(child: CircularProgressIndicator(color: accentColor)),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            backgroundColor: backgroundColor,
            body: Center(
              child: Text(
                'User data not found',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final data = snapshot.data!.data()! as Map<String, dynamic>;

        final existingPhotoUrl = data['profilePhotoUrl'];
        final userName = data['fullName'] ?? "User";
        final userMobile = data['mobile'] ?? "";
        final userEmail = FirebaseAuth.instance.currentUser?.email ?? "";

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: const Text("MyFixPal Profile"),
            backgroundColor: backgroundColor,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 42,
                  backgroundImage: existingPhotoUrl != null
                      ? NetworkImage(existingPhotoUrl)
                      : const AssetImage('assets/default_profile.png')
                            as ImageProvider,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  userEmail,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  userMobile,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 30),

              ListTile(
                leading: const Icon(Icons.edit, color: accentColor),
                title: const Text(
                  'Update Profile',
                  style: TextStyle(color: Colors.white),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                onTap: () => Navigator.pushNamed(context, '/update_profile'),
              ),
              ListTile(
                leading: const Icon(Icons.lock_reset, color: accentColor),
                title: const Text(
                  'Change Password',
                  style: TextStyle(color: Colors.white),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                onTap: () => _changePassword(context),
              ),
              ListTile(
                leading: const Icon(Icons.history, color: accentColor),
                title: const Text(
                  'View Past Activity / Requests',
                  style: TextStyle(color: Colors.white),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                onTap: () => Navigator.pushNamed(context, '/user_requests'),
              ),
              ListTile(
                leading: const Icon(Icons.support_agent, color: accentColor),
                title: const Text(
                  'Contact Support',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'abhijithkraspd@gmail.com',
                  style: TextStyle(color: Colors.white70),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                onTap: () => _launchGmail(context),
              ),
              const Divider(color: Colors.white30, height: 30),

              ListTile(
                leading: const Icon(Icons.logout, color: accentColor),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
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
        );
      },
    );
  }
}
