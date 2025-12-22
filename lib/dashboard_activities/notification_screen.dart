import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../dashboard_activities/service_browse.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});
  Future<void> _cancelJobAsUser(
    BuildContext context,
    String workRequestId,
  ) async {
    final TextEditingController reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this job?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseFirestore.instance
        .collection('work_requests')
        .doc(workRequestId)
        .update({
          'status': 'cancelled',
          'cancelledBy': 'user',
          'cancelReason': reasonCtrl.text.trim(),
          'cancelledAt': FieldValue.serverTimestamp(),
        });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job cancelled successfully'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _confirmCompletionAsUser(
    BuildContext context,
    String workRequestId,
  ) async {
    final hoursCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Job Completion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hoursCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Hours Worked',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount Paid (₹)'),
            ),
          ],
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

    await FirebaseFirestore.instance
        .collection('work_requests')
        .doc(workRequestId)
        .update({
          'status': 'completed',
          'workHours': double.tryParse(hoursCtrl.text) ?? 0,
          'amountPaid': double.tryParse(amountCtrl.text) ?? 0,
          'completedAt': FieldValue.serverTimestamp(),
          'completionConfirmedByUser': true,
        });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _autoPromptCompletion(
    BuildContext context,
    String status,
    String workRequestId,
  ) {
    if (status == 'worker_completed') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confirmCompletionAsUser(context, workRequestId);
      });
    }
  }

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
        foregroundColor: Colors.white,
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
              _autoPromptCompletion(context, status, docs[index].id);

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

              // ✅ Status-based notifications
              if (status == 'accepted') {
                icon = Icons.check_circle;
                color = Colors.greenAccent;
                message = 'Your job request was accepted by $workerName';
              } else if (status == 'cancelled') {
                icon = Icons.warning_amber_rounded;
                color = Colors.orangeAccent;

                final cancelledBy = data['cancelledBy'];

                if (cancelledBy == 'user') {
                  message = 'You cancelled this job request';
                } else if (cancelledBy == 'worker') {
                  message = 'Your job was cancelled by $workerName';
                } else {
                  message = 'This job was cancelled';
                }
              } else if (status == 'rejected') {
                icon = Icons.cancel;
                color = Colors.redAccent;
                message = 'Your job request was rejected by $workerName';
              } else if (status == 'completed' || status == 'complete') {
                icon = Icons.done_all;
                color = Colors.blueAccent;
                message =
                    'Your job with $workerName has been marked as completed';
              } else if (status == 'worker_completed') {
                icon = Icons.assignment_turned_in;
                color = Colors.deepPurpleAccent;
                message =
                    'Worker $workerName requested job completion. Please confirm.';
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
                      if (status == 'pending' || status == 'accepted')
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              'Cancel Job',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                            onPressed: () =>
                                _cancelJobAsUser(context, docs[index].id),
                          ),
                        ),
                      if (status == 'accepted' || status == 'cancelled')
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

                              await FirebaseFirestore.instance
                                  .collection('work_requests')
                                  .doc(docs[index].id)
                                  .update({'status': 'pending'});

                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ServiceRequestScreen(
                                      workerId: workerId,
                                      workerName: workerName,
                                      workerMobile: workerMobile,
                                      prefilledDescription: description,
                                      prefilledDate:
                                          data['requestedDate'] != null
                                          ? (data['requestedDate'] as Timestamp)
                                                .toDate()
                                          : null,
                                      workRequestId: docs[index].id,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      if (status == 'worker_completed')
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Confirm Completion'),
                            onPressed: () => _confirmCompletionAsUser(
                              context,
                              docs[index].id,
                            ),
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
