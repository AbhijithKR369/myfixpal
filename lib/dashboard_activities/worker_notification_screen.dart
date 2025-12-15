import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../dashboard_activities/service_browse.dart';
import 'package:rxdart/rxdart.dart';

class WorkerNotificationScreen extends StatelessWidget {
  const WorkerNotificationScreen({super.key});

  Future<String> _getDisplayName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists && userDoc.data()?['fullName'] != null) {
        return userDoc['fullName'];
      }
    } catch (_) {}
    try {
      final workerDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(userId)
          .get();
      if (workerDoc.exists && workerDoc.data()?['fullName'] != null) {
        return workerDoc['fullName'];
      }
    } catch (_) {}
    return 'Unknown User';
  }

  Future<String> _getReviewerName(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists && doc.data()?['fullName'] != null) {
        return doc['fullName'];
      }
    } catch (_) {}
    return 'Anonymous';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
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

    final currentId = currentUser.uid;

    final assignedStream = FirebaseFirestore.instance
        .collection('work_requests')
        .where('workerId', isEqualTo: currentId)
        .snapshots();

    final createdStream = FirebaseFirestore.instance
        .collection('work_requests')
        .where('createdBy', isEqualTo: currentId)
        .snapshots();

    final reviewsStream = FirebaseFirestore.instance
        .collection('worker_reviews')
        .where('workerId', isEqualTo: currentId)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFF1B1E28),
      appBar: AppBar(
        title: const Text('Worker Notifications'),
        backgroundColor: const Color(0xFF222733),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<QuerySnapshot>>(
        stream: CombineLatestStream.list([
          assignedStream,
          createdStream,
          reviewsStream,
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD34E)),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final assignedDocs = snapshot.data![0].docs;
          final createdDocs = snapshot.data![1].docs;
          final reviewDocs = snapshot.data![2].docs;

          final allNotifications = <Map<String, dynamic>>[];

          for (var doc in assignedDocs) {
            final data = doc.data() as Map<String, dynamic>;
            data['docId'] = doc.id;
            data['type'] = 'assigned';
            allNotifications.add(data);
          }
          for (var doc in createdDocs) {
            final data = doc.data() as Map<String, dynamic>;
            data['docId'] = doc.id;
            data['type'] = 'created';
            allNotifications.add(data);
          }
          for (var doc in reviewDocs) {
            final data = doc.data() as Map<String, dynamic>;
            data['docId'] = doc.id;
            data['type'] = 'review';
            allNotifications.add(data);
          }

          if (allNotifications.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          allNotifications.sort((a, b) {
            final aTime = a['timestamp'] as Timestamp? ?? Timestamp(0, 0);
            final bTime = b['timestamp'] as Timestamp? ?? Timestamp(0, 0);
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: allNotifications.length,
            itemBuilder: (context, index) {
              final notif = allNotifications[index];
              final type = notif['type'];
              final timestamp =
                  notif['timestamp'] as Timestamp? ?? Timestamp.now();
              final date = timestamp.toDate();

              // REVIEWS
              if (type == 'review') {
                final rating = (notif['rating'] ?? 0).toDouble();
                final reviewText = notif['review'] ?? '';
                final userId = notif['userId'] ?? '';
                return FutureBuilder<String>(
                  future: _getReviewerName(userId),
                  builder: (context, snapshot) {
                    final reviewer = snapshot.data ?? 'User';
                    return _notificationCard(
                      icon: Icons.rate_review,
                      color: Colors.amberAccent,
                      title: 'New review from $reviewer',
                      description: reviewText.isNotEmpty
                          ? '"$reviewText"'
                          : 'No review message provided.',
                      date: date,
                      rating: rating,
                    );
                  },
                );
              }

              // JOBS CREATED BY WORKER (worker-worker requests, show workerName)
              if (type == 'created') {
                final status = notif['status'] ?? 'pending';
                final description = notif['fixDescription'] ?? '';
                final workerNameStr = notif['workerName'] ?? 'Worker';
                final workerId = notif['workerId'] ?? '';
                final workerMobile = notif['workerMobile'] ?? '';
                final requestedDate = notif['requestedDate'] as Timestamp?;
                final workRequestId = notif['docId'];

                IconData icon;
                Color color;
                String message;

                switch (status) {
                  case 'accepted':
                    icon = Icons.check_circle;
                    color = Colors.greenAccent;
                    message = '$workerNameStr accepted your job request';
                    break;

                  case 'rejected':
                    icon = Icons.cancel;
                    color = Colors.redAccent;
                    message = '$workerNameStr rejected your job request';
                    break;

                  case 'cancelled':
                    icon = Icons.cancel;
                    color = Colors.orangeAccent;
                    message = '$workerNameStr cancelled your job request';
                    break;

                  case 'completed':
                  case 'complete':
                    icon = Icons.done_all;
                    color = Colors.blueAccent;
                    message = '$workerNameStr completed the work';
                    break;

                  default:
                    icon = Icons.hourglass_empty;
                    color = Colors.amberAccent;
                    message = 'Job request pending with $workerNameStr';
                }


                return _notificationCard(
                  icon: icon,
                  color: color,
                  title: message,
                  description: description,
                  date: date,
                  trailing: (status == 'accepted' || status == 'cancelled')
                      ? TextButton.icon(
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
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirm Reschedule'),
                                content: const Text(
                                  'Do you want to reschedule this job request?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
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
                              await FirebaseFirestore.instance
                                  .collection('work_requests')
                                  .doc(workRequestId)
                                  .update({'status': 'pending'});

                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ServiceRequestScreen(
                                      workerId: workerId,
                                      workerName: workerNameStr,
                                      workerMobile: workerMobile,
                                      prefilledDescription: description,
                                      prefilledDate: requestedDate?.toDate(),
                                      workRequestId: workRequestId,
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to reschedule: $e',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                        )
                      : null,
                );
              }

              // JOBS ASSIGNED TO WORKER (fetch name from users or workers)
              final status = notif['status'] ?? 'pending';
              final description = notif['fixDescription'] ?? '';
              final userId = notif['userId'] ?? '';

              return FutureBuilder<String>(
                future: _getDisplayName(userId),
                builder: (context, snapshot) {
                  final userName = snapshot.data ?? 'User';
                  IconData icon;
                  Color color;
                  String message;

                  switch (status) {
                    case 'accepted':
                      icon = Icons.check_circle;
                      color = Colors.greenAccent;
                      message = 'You accepted a job from $userName';
                      break;

                    case 'rejected':
                      icon = Icons.cancel;
                      color = Colors.redAccent;
                      message = 'You rejected a job from $userName';
                      break;

                    case 'cancelled':
                      icon = Icons.cancel;
                      color = Colors.orangeAccent;
                      message = 'You cancelled a job from $userName';
                      break;

                    case 'completed':
                    case 'complete':
                      icon = Icons.done_all;
                      color = Colors.blueAccent;
                      message = 'You completed work for $userName';
                      break;

                    default:
                      icon = Icons.hourglass_empty;
                      color = Colors.amberAccent;
                      message = 'New job request from $userName';
                  }


                  return _notificationCard(
                    icon: icon,
                    color: color,
                    title: message,
                    description: description,
                    date: date,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _notificationCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required DateTime date,
    double rating = 0.0,
    Widget? trailing,
  }) {
    return Card(
      color: const Color(0xFF2B2F3A),
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (rating > 0)
              Row(
                children: List.generate(
                  5,
                  (star) => Icon(
                    Icons.star,
                    color: star < rating.round() ? Colors.yellow : Colors.grey,
                    size: 18,
                  ),
                ),
              ),
            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  description,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            const SizedBox(height: 6),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            if (trailing != null)
              Align(alignment: Alignment.centerRight, child: trailing),
          ],
        ),
      ),
    );
  }
}
