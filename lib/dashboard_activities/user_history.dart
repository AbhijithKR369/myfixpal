import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:myfixpal/dashboard_activities/woker_ratings.dart';
import 'package:myfixpal/report_issue_screen.dart';

const Color kAccentColor = Color(0xFFFFD34E);

class UserHistoryScreen extends StatefulWidget {
  const UserHistoryScreen({super.key});

  @override
  State<UserHistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  final DateFormat displayFormat = DateFormat('dd/MM/yyyy');

  DateTime getSortDate(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    if (data['requestedDate'] is Timestamp) {
      return (data['requestedDate'] as Timestamp).toDate();
    }
    if (data['timestamp'] is Timestamp) {
      return (data['timestamp'] as Timestamp).toDate();
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E2432),
      appBar: AppBar(
        title: const Text('My Job History'),
        backgroundColor: const Color(0xFF222733),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('work_requests')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: kAccentColor),
            );
          }

          final docs = snapshot.data!.docs;
          final now = DateTime.now();

          final completedJobs = docs
              .where((d) => (d['status'] ?? '') == 'completed')
              .toList()
            ..sort((a, b) => getSortDate(b).compareTo(getSortDate(a)));

          final overdueJobs = docs
              .where((d) {
                if (d['status'] != 'accepted' || d['requestedDate'] == null) {
                  return false;
                }
                final date = (d['requestedDate'] as Timestamp).toDate();
                return date.isBefore(DateTime(now.year, now.month, now.day));
              })
              .toList()
            ..sort((a, b) => getSortDate(b).compareTo(getSortDate(a)));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionTitle('Completed Jobs', Colors.greenAccent),
              completedJobs.isEmpty
                  ? _empty('No completed jobs')
                  : _buildJobList(completedJobs, isCompleted: true),

              const SizedBox(height: 24),

              _sectionTitle(
                'Accepted but Not Completed (Past Due)',
                Colors.orangeAccent,
              ),
              overdueJobs.isEmpty
                  ? _empty('No overdue jobs')
                  : _buildJobList(overdueJobs, isCompleted: false),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text, Color color) {
    return Text(
      text,
      style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _empty(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3243),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(color: Colors.white70)),
      ),
    );
  }

  Widget _buildJobList(
    List<QueryDocumentSnapshot> jobs, {
    required bool isCompleted,
  }) {
    return Column(
      children: jobs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final workerName = data['workerName'] ?? 'Worker';
        final workerId = data['workerId'] ?? '';
        final description = data['fixDescription'] ?? '';
        final date = data['requestedDate'] is Timestamp
            ? displayFormat.format(
                (data['requestedDate'] as Timestamp).toDate(),
              )
            : 'N/A';

        return Card(
          color: const Color(0xFF2C3243),
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.build, color: kAccentColor),
            title: Text(
              workerName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Date: $date\n$description',
              style: const TextStyle(color: Colors.white70),
            ),
            onTap: () {
              if (isCompleted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RateWorkerScreen(
                      workerId: workerId,
                      workerName: workerName,
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportIssueScreen(
                      workerId: workerId,
                      workerName: workerName,
                      workRequestId: doc.id,
                    ),
                  ),
                );
              }
            },
          ),
        );
      }).toList(),
    );
  }
}
