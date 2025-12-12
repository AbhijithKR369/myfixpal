// lib/screens/customer_history.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color kBackgroundColor = Color(0xFF222733);
const Color kCardColor = Color.fromARGB(255, 188, 117, 3);
const Color kAccentColor = Color(0xFFFFD34E);

class CustomerHistoryScreen extends StatelessWidget {
  const CustomerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          title: const Text('Your History'),
          backgroundColor: kBackgroundColor,
        ),
        body: const Center(
          child: Text('Please login', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final userId = user.uid;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Completed Jobs (Customer)'),
        backgroundColor: kBackgroundColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('work_requests')
            .where('status', isEqualTo: 'completed')
            .where('userId', isEqualTo: userId)
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
                'No completed requests yet',
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
              final workerId = (req['workerId'] ?? '').toString().trim();

              // Skip rows without a valid workerId
              if (workerId.isEmpty) {
                return const SizedBox.shrink();
              }

              final fixDescription = (req['fixDescription'] ?? '').toString();
              final requestedDate = req['requestedDate'];
              final timestamp = req['timestamp'] as Timestamp?;
              final tsText = timestamp != null
                  ? timestamp.toDate().toLocal().toString()
                  : '';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('workers')
                    .doc(workerId)
                    .get(),
                builder: (context, workerSnap) {
                  // Default/fallback values
                  String name = 'Worker';
                  String address = req['location']?.toString() ?? '';
                  String phone = req['workerMobile']?.toString() ?? '';
                  String? photoUrl;

                  if (workerSnap.connectionState == ConnectionState.waiting) {
                    // Lightweight placeholder while worker profile loads
                    return Card(
                      color: kCardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white12,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  SizedBox(height: 4),
                                  Text(
                                    'Loading...',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (workerSnap.hasData && workerSnap.data!.exists) {
                    final data =
                        workerSnap.data!.data() as Map<String, dynamic>? ?? {};
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
                              // optionally launch dialer with url_launcher
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
