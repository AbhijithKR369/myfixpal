import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WorkerJobsScreen extends StatelessWidget {
  const WorkerJobsScreen({super.key});

  static const backgroundColor = Color(0xFF222733);
  static const accentColor = Color(0xFFFFD34E);

  @override
  Widget build(BuildContext context) {
    final workerId = FirebaseAuth.instance.currentUser?.uid;
    if (workerId == null) {
      return const Center(child: Text('Not logged in'));
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 2,
        title: const Text(
          'Job Request',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('work_requests')
            .where('workerId', isEqualTo: workerId)
            .where('status', whereIn: ['pending', 'accepted', 'completed'])
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          }

          final docs = snap.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final s = data['status'] ?? 'pending';
            return ['pending', 'accepted', 'completed'].contains(s);
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No job requests found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final job = docs[i].data() as Map<String, dynamic>;
              final userId = job['userId'];

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getUserOrWorker(userId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const ListTile(
                      title: Text(
                        'User not found',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final user = snapshot.data!;
                  return Card(
                    color: backgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 14,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            user['profilePhotoUrl'] != null &&
                                user['profilePhotoUrl'].isNotEmpty
                            ? NetworkImage(user['profilePhotoUrl'])
                            : const AssetImage('assets/default_profile.png')
                                  as ImageProvider,
                        radius: 28,
                      ),
                      title: Text(
                        user['fullName'] ?? "User",
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['mobile'] ?? user['phone'] ?? '',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            user['address'] ??
                                user['city'] ??
                                user['pincode'] ??
                                "not given",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white30,
                            ),
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (job['status'] == 'accepted')
                              ? Colors.green
                              : (job['status'] == 'completed')
                              ? Colors.blue
                              : accentColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          (job['status'] ?? 'pending').toUpperCase(),
                          style: TextStyle(
                            color: (job['status'] == 'pending')
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ),
                      onTap: () => _showJobDetailModal(
                        context,
                        docs[i].reference,
                        job,
                        user,
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

  Future<Map<String, dynamic>?> _getUserOrWorker(String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (userDoc.exists) return userDoc.data() as Map<String, dynamic>;

    final workerDoc = await FirebaseFirestore.instance
        .collection('workers')
        .doc(userId)
        .get();

    if (workerDoc.exists) return workerDoc.data() as Map<String, dynamic>;
    return null;
  }

  void _showJobDetailModal(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> job,
    Map<String, dynamic> user,
  ) {
    final status = job['status'] ?? 'pending';

    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      context: context,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              "Job Request",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        user['profilePhotoUrl'] != null &&
                            user['profilePhotoUrl'].isNotEmpty
                        ? NetworkImage(user['profilePhotoUrl'])
                        : const AssetImage('assets/default_profile.png')
                              as ImageProvider,
                    radius: 32,
                  ),
                  title: Text(
                    user['fullName'] ?? "User",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['mobile'] ?? user['phone'] ?? "",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        user['address'] ??
                            user['city'] ??
                            user['pincode'] ??
                            "not given",
                        style: const TextStyle(color: Colors.white30),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 24),
                ListTile(
                  title: Text(
                    "Service:",
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    job['fixDescription'] ?? "",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.date_range, color: Colors.white),
                  title: Text(
                    job['requestedDate'] != null
                        ? DateFormat(
                            'dd MMMM yyyy, hh:mm a',
                          ).format((job['requestedDate'] as Timestamp).toDate())
                        : "No date provided",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                if (status == 'pending') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(44),
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            await ref.update({'status': 'accepted'});
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.clear),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(44),
                          ),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirm Reject'),
                                content: const Text(
                                  'Are you sure you want to reject and permanently delete this request?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Yes, Reject'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              try {
                                await ref.delete();
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Job request rejected and deleted',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error deleting request: $e',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ] else if (status == 'accepted') ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Mark as Completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Mark as Completed'),
                          content: const Text(
                            'Are you sure you want to mark this job as completed?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Confirm'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ref.update({'status': 'completed'});
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Job marked as completed!'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.blueAccent,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ] else ...[
                  Center(
                    child: Text(
                      "STATUS: ${status.toUpperCase()}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
