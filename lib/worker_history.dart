import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

const Color kBg = Color(0xFF1E2432);
const Color kCard = Color(0xFF2C3243);
const Color kAccent = Color(0xFFFFD34E);

class WorkerHistoryScreen extends StatefulWidget {
  const WorkerHistoryScreen({super.key});

  @override
  State<WorkerHistoryScreen> createState() => _WorkerHistoryScreenState();
}

class _WorkerHistoryScreenState extends State<WorkerHistoryScreen> {
  final String myId = FirebaseAuth.instance.currentUser!.uid;
  final DateFormat df = DateFormat('dd MMM yyyy');

  bool _isOverdue(Map<String, dynamic> d) {
    if (d['requestedDate'] is! Timestamp) return false;
    final date = (d['requestedDate'] as Timestamp).toDate();
    final today = DateTime.now();
    return date.isBefore(DateTime(today.year, today.month, today.day));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Work History'),
        backgroundColor: kBg,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('work_requests')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: kAccent),
            );
          }

          final all = snap.data!.docs
              .map((d) => d.data() as Map<String, dynamic>)
              .toList();

          final completedByMe = all.where((d) =>
              d['workerId'] == myId && d['status'] == 'completed');

          final overdueByMe = all.where((d) =>
              d['workerId'] == myId &&
              d['status'] == 'accepted' &&
              _isOverdue(d));

          final completedForMe = all.where((d) =>
              d['userId'] == myId &&
              d['workerId'] != myId &&
              d['status'] == 'completed');

          final overdueForMe = all.where((d) =>
              d['userId'] == myId &&
              d['workerId'] != myId &&
              d['status'] == 'accepted' &&
              _isOverdue(d));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section('Works Completed by You', Colors.greenAccent),
              _list(completedByMe.toList()),

              const SizedBox(height: 24),
              _section('Accepted by You (Overdue)', Colors.orangeAccent),
              _list(overdueByMe.toList()),

              const SizedBox(height: 24),
              _section(
                'Your Requests Completed by Other Workers',
                Colors.lightBlueAccent,
              ),
              _list(completedForMe.toList()),

              const SizedBox(height: 24),
              _section(
                'Your Requests Pending with Other Workers',
                Colors.redAccent,
              ),
              _list(overdueForMe.toList()),
            ],
          );
        },
      ),
    );
  }

  Widget _section(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  /// ================= CORE FIX IS HERE =================
  Widget _list(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No records',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Column(
      children: items.map((d) {
        final bool iAmWorker = d['workerId'] == myId;
        final String otherId = iAmWorker ? d['userId'] : d['workerId'];

        final String date = d['requestedDate'] is Timestamp
            ? df.format((d['requestedDate'] as Timestamp).toDate())
            : 'N/A';

        // 🔁 TRY USERS FIRST
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(otherId)
              .get(),
          builder: (context, userSnap) {
            if (userSnap.hasData && userSnap.data!.exists) {
              final u = userSnap.data!.data() as Map<String, dynamic>;
              return _jobCard(
                name: u['fullName'] ?? 'User',
                date: date,
                d: d,
              );
            }

            // 🔁 FALLBACK TO WORKERS
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('workers')
                  .doc(otherId)
                  .get(),
              builder: (context, workerSnap) {
                String name = 'Unknown';

                if (workerSnap.hasData && workerSnap.data!.exists) {
                  final w =
                      workerSnap.data!.data() as Map<String, dynamic>;
                  name = w['fullName'] ?? 'Worker';
                }

                return _jobCard(
                  name: name,
                  date: date,
                  d: d,
                );
              },
            );
          },
        );
      }).toList(),
    );
  }

  Widget _jobCard({
    required String name,
    required String date,
    required Map<String, dynamic> d,
  }) {
    return Card(
      color: kCard,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.assignment, color: kAccent),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Date: $date\n${d['fixDescription'] ?? ''}',
          style: const TextStyle(color: Colors.white70),
        ),
        onTap: () => _details(context, d, name, date),
      ),
    );
  }

  void _details(
    BuildContext context,
    Map<String, dynamic> d,
    String name,
    String date,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kBg,
        title: Text(name, style: const TextStyle(color: kAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Status', d['status']),
            _row('Date', date),
            _row('Problem', d['fixDescription']),
            _row('Phone', d['userMobile'] ?? d['workerMobile']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: kAccent)),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, dynamic value) {
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
