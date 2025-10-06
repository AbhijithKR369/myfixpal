import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../dashboard_activities/service_browse.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1B1E28),
        body: Center(
          child: Text(
            'Please log in to view notifications',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1B1E28),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF222733),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('work_requests')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD34E)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';
              final workerName = data['workerName'] ?? 'Unknown';
              final workerId = data['workerId'] ?? '';
              final workerMobile = data['workerMobile'] ?? '';
              final description = data['fixDescription'] ?? '';
              final date = (data['timestamp'] != null)
                  ? (data['timestamp'] as Timestamp).toDate()
                  : DateTime.now();

              IconData icon;
              Color color;
              String message;

              if (status == 'accepted') {
                icon = Icons.check_circle;
                color = Colors.greenAccent;
                message = 'Your job request was accepted by $workerName';
              } else if (status == 'rejected') {
                icon = Icons.cancel;
                color = Colors.redAccent;
                message = 'Your job request was rejected by $workerName';
              } else {
                icon = Icons.hourglass_empty;
                color = Colors.amberAccent;
                message = 'Your job request is still pending.';
              }

              return Card(
                color: const Color(0xFF2B2F3A),
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: Icon(icon, color: color, size: 32),
                  title: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${date.day}/${date.month}/${date.year}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      if (status == 'accepted')
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(
                              Icons.refresh,
                              color: Color(0xFFFFD34E),
                            ),
                            label: const Text(
                              'Reschedule',
                              style: TextStyle(
                                color: Color(0xFFFFD34E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onPressed: () async {
                              // Step 1: Confirm reschedule
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Confirm Reschedule'),
                                  content: const Text(
                                    'Do you want to reschedule this job request?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Confirm'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed != true) return;

                              try {
                                // Step 2: Update status to pending
                                await FirebaseFirestore.instance
                                    .collection('work_requests')
                                    .doc(docs[index].id)
                                    .update({'status': 'pending'});

                                // Step 3: Navigate to service request page
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ServiceRequestScreen(
                                        workerId: workerId,
                                        workerName: workerName,
                                        workerMobile: workerMobile,
                                        prefilledDescription: description,
                                        prefilledDate:
                                            (data['requestedDate'] != null)
                                            ? (data['requestedDate']
                                                      as Timestamp)
                                                  .toDate()
                                            : null,
                                        workRequestId: docs[index]
                                            .id, // Pass the document ID here
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to reschedule: $e',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
