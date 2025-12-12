// lib/screens/worker_history.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color kBackgroundColor = Color(0xFF222733);
const Color kCardColor = Color.fromARGB(255, 188, 117, 3);
const Color kAccentColor = Color(0xFFFFD34E);

class WorkerHistoryScreen extends StatelessWidget {
  const WorkerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          title: const Text('Job History'),
          backgroundColor: kBackgroundColor,
        ),
        body: const Center(
          child: Text('Please login', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final workerId = user.uid;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Completed Jobs (Worker)'),
        backgroundColor: kBackgroundColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('work_requests')
            .where('status', isEqualTo: 'completed')
            .where('workerId', isEqualTo: workerId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text(
                'Error: ${snap.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

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

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final req = docs[i].data()! as Map<String, dynamic>;

              // userId might be stored as userId or createdBy; coerce to string safely
              final rawUserId = (req['userId'] ?? req['createdBy'] ?? '')
                  .toString()
                  .trim();
              if (rawUserId.isEmpty) {
                // nothing we can show for this row
                return const SizedBox.shrink();
              }
              final userId = rawUserId;

              final requestedDate = req['requestedDate'];
              final fixDescription = (req['fixDescription'] ?? '').toString();
              final timestamp = req['timestamp'] as Timestamp?;
              final tsText = timestamp != null
                  ? timestamp.toDate().toLocal().toString()
                  : '';

              // fetch customer profile
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get(),
                builder: (context, userSnap) {
                  // show a light placeholder while loading profile
                  if (userSnap.connectionState == ConnectionState.waiting) {
                    return Card(
                      color: kCardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: const [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white12,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Loading customer...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // defaults
                  String name = 'Customer';
                  String address = req['location']?.toString() ?? '';
                  String phone = req['workerMobile']?.toString() ?? '';
                  String? photoUrl;

                  if (userSnap.hasData && userSnap.data!.exists) {
                    final data =
                        userSnap.data!.data() as Map<String, dynamic>? ?? {};
                    name = (data['fullName'] ?? name).toString();
                    address = (data['location'] ?? data['address'] ?? address)
                        .toString();
                    phone = (data['mobile'] ?? phone).toString();
                    photoUrl = data['profilePhotoUrl']?.toString();
                  }

                  final ImageProvider imageProvider =
                      (photoUrl != null && photoUrl.trim().isNotEmpty)
                      ? NetworkImage(photoUrl)
                      : const AssetImage('assets/default_profile.png');

                  return Card(
                    color: kCardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: imageProvider,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (address.isNotEmpty)
                                  Text(
                                    address,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  'Phone: ${phone}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Job: $fixDescription',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 6),
                                if (requestedDate != null)
                                  Text(
                                    'Requested: ${_formatDateLike(requestedDate)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                if (tsText.isNotEmpty)
                                  Text(
                                    'Completed: $tsText',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.phone, color: Colors.green),
                            onPressed: () {
                              // optional: dial phone using url_launcher
                            },
                          ),
                        ],
                      ),
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
}

String _formatDateLike(dynamic value) {
  try {
    if (value is Timestamp) return value.toDate().toLocal().toString();
    if (value is DateTime) return value.toLocal().toString();
    return value?.toString() ?? '';
  } catch (_) {
    return value?.toString() ?? '';
  }
}
