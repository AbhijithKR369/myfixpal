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

    return Container(
      color: backgroundColor,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('work_requests')
            .where('workerId', isEqualTo: workerId)
            .where('status', whereIn: ['pending', 'accepted'])
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          }

          // ✅ Ensure only pending/accepted
          final docs = snap.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final s = data['status'] ?? 'pending';
            return s == 'pending' || s == 'accepted';
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

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData || !userSnap.data!.exists) {
                    return const ListTile(
                      title: Text(
                        'User not found',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final user = userSnap.data!.data() as Map<String, dynamic>;
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

  void _showJobDetailModal(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> job,
    Map<String, dynamic> user,
  ) {
    final status = job['status'] ?? 'pending';

    showModalBottomSheet(
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            if (status == 'pending')
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
                        Navigator.pop(context); // close modal instantly
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
                        Navigator.pop(context); // close modal instantly
                        await ref.update({'status': 'rejected'});
                      },
                    ),
                  ),
                ],
              )
            else
              Center(
                child: Text(
                  "STATUS: ${status.toUpperCase()}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: status == 'accepted' ? Colors.green : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
