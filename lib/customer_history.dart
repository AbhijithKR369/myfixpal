// lib/screens/customer_history.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Color kBackgroundColor = Color(0xFF222733);
const Color kCardColor = Color.fromARGB(255, 188, 117, 3);
const Color kAccentColor = Color(0xFFFFD34E);

class CustomerHistoryScreen extends StatelessWidget {
  const CustomerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login')),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Completed Jobs'),
        backgroundColor: kBackgroundColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('work_requests')
            .where('userId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'completed')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: kAccentColor),
            );
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No completed jobs yet',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final req = docs[i].data() as Map<String, dynamic>;
              final workerId = req['workerId'] ?? '';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('workers')
                    .doc(workerId)
                    .get(),
                builder: (context, workerSnap) {
                  String name = 'Worker';
                  String profession = 'Service';
                  String? photoUrl;

                  if (workerSnap.hasData && workerSnap.data!.exists) {
                    final w =
                        workerSnap.data!.data() as Map<String, dynamic>? ?? {};
                    name = w['fullName'] ?? name;
                    profession = w['profession'] ?? profession;
                    photoUrl = w['profilePhotoUrl'];
                  }

                  return Card(
                    color: kCardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundImage:
                            (photoUrl != null && photoUrl.isNotEmpty)
                                ? NetworkImage(photoUrl)
                                : const AssetImage(
                                        'assets/default_profile.png')
                                    as ImageProvider,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        profession,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: kAccentColor,
                      ),
                      onTap: () => _showDetails(context, req, name, profession,
                          photoUrl),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// -------- DETAILS BOTTOM SHEET --------
  void _showDetails(
    BuildContext context,
    Map<String, dynamic> req,
    String name,
    String profession,
    String? photoUrl,
  ) {
    final DateTime? requestedDate =
        (req['requestedDate'] is Timestamp)
            ? (req['requestedDate'] as Timestamp).toDate()
            : null;

    final DateTime? completedDate =
        (req['timestamp'] is Timestamp)
            ? (req['timestamp'] as Timestamp).toDate()
            : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: kBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage:
                        (photoUrl != null && photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : const AssetImage(
                                    'assets/default_profile.png')
                                as ImageProvider,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        profession,
                        style: const TextStyle(color: kAccentColor),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 24),
              _detailRow('Problem', req['fixDescription']),
              _detailRow(
                'Requested',
                requestedDate != null
                    ? DateFormat('dd MMM yyyy').format(requestedDate)
                    : 'N/A',
              ),
              _detailRow(
                'Completed',
                completedDate != null
                    ? DateFormat('dd MMM yyyy').format(completedDate)
                    : 'N/A',
              ),
              _detailRow('Phone', req['workerMobile']),
              _detailRow('Address', req['location']),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }
}
