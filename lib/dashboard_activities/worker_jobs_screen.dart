import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

const Color kBackgroundColor = Color(0xFF222733);
const Color kCardColor = Color(0xFF2C3140);
const Color kAccentColor = Color(0xFFFFD34E);

class WorkerJobsScreen extends StatefulWidget {
  const WorkerJobsScreen({super.key});

  @override
  State<WorkerJobsScreen> createState() => _WorkerJobsScreenState();
}

class _WorkerJobsScreenState extends State<WorkerJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String workerId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    workerId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  /// 🔴 NEW: Past-date check (used only for filtering)
  bool _isPastDue(Map<String, dynamic> data) {
    if (data['requestedDate'] is! Timestamp) return false;
    final jobDate = (data['requestedDate'] as Timestamp).toDate();
    final now = DateTime.now();
    return jobDate.isBefore(DateTime(now.year, now.month, now.day));
  }

  @override
  Widget build(BuildContext context) {
    if (workerId.isEmpty) {
      return const Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(
          child: Text("Not logged in", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 2,
        title: const Text(
          "Jobs",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kAccentColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: "Jobs Pending"),
            Tab(text: "Job Requests"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildJobsPendingGrouped(),
          _buildJobRequestsGrouped(),
        ],
      ),
    );
  }

  /// ================= JOBS PENDING =================
  Widget _buildJobsPendingGrouped() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('work_requests')
          .where('workerId', isEqualTo: workerId)
          .where('status', isEqualTo: 'accepted')
          .orderBy('requestedDate')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: kAccentColor),
          );
        }

        /// 🔴 FILTER PAST-DUE JOBS HERE
        final docs = snap.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return !_isPastDue(data);
        }).toList();

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No jobs pending',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final Map<String, List<QueryDocumentSnapshot>> grouped = {};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final dateKey = (data['requestedDate'] as Timestamp?) != null
              ? DateFormat('yyyy-MM-dd')
                  .format((data['requestedDate'] as Timestamp).toDate())
              : '';
          grouped.putIfAbsent(dateKey, () => []).add(doc);
        }

        final datesSorted = grouped.keys.toList()..sort();

        return ListView.builder(
          itemCount: datesSorted.length,
          itemBuilder: (context, di) {
            final dateKey = datesSorted[di];
            final dateJobs = grouped[dateKey]!;
            final displayDate = dateKey.isNotEmpty
                ? DateFormat('dd/MM/yyyy - EEEE')
                    .format(DateFormat('yyyy-MM-dd').parse(dateKey))
                : 'Unknown Date';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (di > 0)
                  const Divider(color: Colors.white24, height: 32),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 0, 6),
                  child: Text(
                    displayDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                ...dateJobs.map((doc) {
                  final job = doc.data() as Map<String, dynamic>;
                  final userId = job['userId'];

                  return FutureBuilder<Map<String, dynamic>?>(
                    future: _getUserOrWorker(userId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data == null) {
                        return const SizedBox();
                      }
                      final user = snapshot.data!;
                      return _jobTile(
                        doc.reference,
                        job,
                        user,
                        pending: true,
                      );
                    },
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  /// ================= JOB REQUESTS =================
  Widget _buildJobRequestsGrouped() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('work_requests')
          .where('workerId', isEqualTo: workerId)
          .where('status', isEqualTo: 'pending')
          .orderBy('requestedDate')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: kAccentColor),
          );
        }

        /// 🔴 FILTER PAST-DUE JOBS HERE
        final docs = snap.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return !_isPastDue(data);
        }).toList();

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No job requests found',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final Map<String, List<QueryDocumentSnapshot>> grouped = {};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final dateKey = (data['requestedDate'] as Timestamp?) != null
              ? DateFormat('yyyy-MM-dd')
                  .format((data['requestedDate'] as Timestamp).toDate())
              : '';
          grouped.putIfAbsent(dateKey, () => []).add(doc);
        }

        final datesSorted = grouped.keys.toList()..sort();

        return ListView.builder(
          itemCount: datesSorted.length,
          itemBuilder: (context, di) {
            final dateKey = datesSorted[di];
            final dateJobs = grouped[dateKey]!;

            final displayDate = dateKey.isNotEmpty
                ? DateFormat('dd/MM/yyyy - EEEE')
                    .format(DateFormat('yyyy-MM-dd').parse(dateKey))
                : 'Unknown Date';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (di > 0)
                  const Divider(color: Colors.white24, height: 32),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 0, 6),
                  child: Text(
                    displayDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                ...dateJobs.map((doc) {
                  final job = doc.data() as Map<String, dynamic>;
                  final userId = job['userId'];

                  return FutureBuilder<Map<String, dynamic>?>(
                    future: _getUserOrWorker(userId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data == null) {
                        return const SizedBox();
                      }
                      final user = snapshot.data!;
                      return _jobTile(
                        doc.reference,
                        job,
                        user,
                        pending: false,
                      );
                    },
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  /// ================= SHARED TILE =================
  Widget _jobTile(
    DocumentReference ref,
    Map<String, dynamic> job,
    Map<String, dynamic> user, {
    required bool pending,
  }) {
    return Card(
      color: kCardColor,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 26,
          backgroundImage:
              user['profilePhotoUrl'] != null &&
                      (user['profilePhotoUrl'] as String).isNotEmpty
                  ? NetworkImage(user['profilePhotoUrl'])
                  : const AssetImage('assets/default_profile.png')
                      as ImageProvider,
        ),
        title: Text(
          user['fullName'] ?? "User",
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          job['fixDescription'] ?? "",
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: _statusChip(job['status']),
        onTap: () => pending
            ? _showPendingJobDetailModal(context, ref, job, user)
            : _showJobRequestDetailModal(context, ref, job, user),
      ),
    );
  }

  /// ================= HELPERS (UNCHANGED) =================
  Widget _statusChip(String? status) {
    final s = status?.toLowerCase() ?? '';
    Color color;
    switch (s) {
      case 'pending':
        color = kAccentColor;
        break;
      case 'accepted':
        color = Colors.green;
        break;
      case 'completed':
        color = Colors.blue;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.white24;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Text(
        s.toUpperCase(),
        style: TextStyle(
          color: s == 'pending' ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _getUserOrWorker(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) return userDoc.data();
    final workerDoc = await FirebaseFirestore.instance
        .collection('workers')
        .doc(userId)
        .get();
    if (workerDoc.exists) return workerDoc.data();
    return null;
  }

  /// 🔽 MODALS REMAIN 100% UNCHANGED BELOW
  /// (_showPendingJobDetailModal & _showJobRequestDetailModal)



  void _showPendingJobDetailModal(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> job,
    Map<String, dynamic> user,
  ) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: kCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      context: context,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.52,
        child: Scaffold(
          backgroundColor: kCardColor,
          appBar: AppBar(
            backgroundColor: kCardColor,
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
                    radius: 32,
                    backgroundImage:
                        user['profilePhotoUrl'] != null &&
                            (user['profilePhotoUrl'] as String).isNotEmpty
                        ? NetworkImage(user['profilePhotoUrl'])
                        : const AssetImage('assets/default_profile.png')
                              as ImageProvider,
                  ),
                  title: Text(
                    user['fullName'] ?? "User",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    user['mobile'] ?? user['phone'] ?? "",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                const Divider(color: Colors.white24, height: 22),
                ListTile(
                  title: Text(
                    "Service:",
                    style: TextStyle(
                      color: kAccentColor,
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
                            'dd MMM yyyy, hh:mm a',
                          ).format((job['requestedDate'] as Timestamp).toDate())
                        : "No date provided",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark as Completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                            backgroundColor: Colors.blueAccent,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showJobRequestDetailModal(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> job,
    Map<String, dynamic> user,
  ) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: kCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      context: context,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.45,
        child: Scaffold(
          backgroundColor: kCardColor,
          appBar: AppBar(
            backgroundColor: kCardColor,
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
                    radius: 32,
                    backgroundImage:
                        user['profilePhotoUrl'] != null &&
                            (user['profilePhotoUrl'] as String).isNotEmpty
                        ? NetworkImage(user['profilePhotoUrl'])
                        : const AssetImage('assets/default_profile.png')
                              as ImageProvider,
                  ),
                  title: Text(
                    user['fullName'] ?? "User",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    user['mobile'] ?? user['phone'] ?? "",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                const Divider(color: Colors.white24, height: 22),
                ListTile(
                  title: Text(
                    "Service:",
                    style: TextStyle(
                      color: kAccentColor,
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
                            'dd MMM yyyy, hh:mm a',
                          ).format((job['requestedDate'] as Timestamp).toDate())
                        : "No date provided",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 14),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm Reject'),
                              content: const Text(
                                'Are you sure you want to reject this request?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Yes, Reject'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await ref.update({'status': 'rejected'});
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Job request rejected'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
