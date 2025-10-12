import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:myfixpal/dashboard_activities/woker_ratings.dart'; // double check this import path

const Color kPrimaryColor = Color(0xFF00796B);
const Color kAccentColor = Color(0xFFFFD34E);
const Color kBackgroundColor = Color(0xFF222733);

class UserHistoryScreen extends StatefulWidget {
  const UserHistoryScreen({super.key});

  @override
  State<UserHistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final DateFormat displayFormat = DateFormat('dd/MM/yyyy, EEEE');

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E2432),
      appBar: AppBar(
        title: const Text('My Job History'),
        backgroundColor: const Color(0xFF222733),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('work_requests')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD34E)),
            );
          }

          final docs = snapshot.data!.docs;
          final now = DateTime.now();

          final completedJobs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'completed';
          }).toList();

          final expiredPendingJobs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['status'] != 'accepted' || data['requestedDate'] == null)
              return false;
            try {
              final jobDate = (data['requestedDate'] as Timestamp).toDate();
              return jobDate.isBefore(DateTime(now.year, now.month, now.day));
            } catch (_) {
              return false;
            }
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Completed Jobs',
                  style: TextStyle(
                    color: Color(0xFFFFD34E),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                completedJobs.isEmpty
                    ? _noDataCard('No completed jobs found')
                    : _buildJobList(completedJobs, Colors.greenAccent),

                const SizedBox(height: 24),

                const Text(
                  'Accepted but Not Completed (Past Due)',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                expiredPendingJobs.isEmpty
                    ? _noDataCard('No pending overdue jobs')
                    : _buildJobList(expiredPendingJobs, Colors.orangeAccent),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _noDataCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3243),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(message, style: const TextStyle(color: Colors.white70)),
      ),
    );
  }

  Widget _buildJobList(List<QueryDocumentSnapshot> jobs, Color color) {
    return Column(
      children: jobs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final workerName = data['workerName'] ?? 'Unknown Worker';
        final description = data['fixDescription'] ?? '';
        final status = data['status'] ?? 'N/A';
        final workerId = data['workerId'] ?? '';
        String displayDate = 'N/A';
        if (data['requestedDate'] != null &&
            data['requestedDate'] is Timestamp) {
          displayDate = displayFormat.format(
            (data['requestedDate'] as Timestamp).toDate(),
          );
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('workers')
              .doc(workerId)
              .get(),
          builder: (context, snapshot) {
            String profession = 'Unknown Profession';
            if (data['profession'] != null &&
                (data['profession'] as String).isNotEmpty) {
              profession = data['profession'];
            } else if (snapshot.hasData && snapshot.data!.exists) {
              profession = snapshot.data!['profession'] ?? 'Unknown Profession';
            }
            return Card(
              color: const Color(0xFF2C3243),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: Icon(Icons.build_circle, color: color, size: 32),
                title: Text(
                  workerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '$profession\nDate: $displayDate\nDetails: $description\nStatus: $status',
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: workerId.toString().isNotEmpty
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RateWorkerScreen(
                            workerId: workerId,
                            workerName: workerName,
                          ),
                        ),
                      )
                    : null,
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
