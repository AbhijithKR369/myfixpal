import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ------------------- THEME -------------------
const Color kPrimaryColor = Color(0xFF00796B); // teal
const Color kAccentColor = Color(0xFFFFD34E); // yellow
const Color kBackgroundColor = Color(0xFF222733); // dark bg

final ThemeData appTheme = ThemeData(
  scaffoldBackgroundColor: kBackgroundColor,
  primaryColor: kPrimaryColor,
  colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
  appBarTheme: const AppBarTheme(
    backgroundColor: kPrimaryColor,
    foregroundColor: Colors.white,
    elevation: 2,
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kAccentColor,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    labelStyle: const TextStyle(color: Colors.black87),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: kAccentColor, width: 2),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
    prefixIconColor: kAccentColor,
  ),
);

/// ------------------- SERVICE BROWSE SCREEN -------------------
class ServiceBrowseScreen extends StatefulWidget {
  const ServiceBrowseScreen({super.key});

  @override
  State<ServiceBrowseScreen> createState() => _ServiceBrowseScreenState();
}

class _ServiceBrowseScreenState extends State<ServiceBrowseScreen> {
  final List<String> professions = [
    'Painter',
    'Electrician',
    'Carpenter',
    'Plumber',
  ];
  String? selectedProfession;
  final TextEditingController pincodeController = TextEditingController();

  bool isResetting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Services'),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset All Ratings',
            onPressed: isResetting ? null : _confirmResetRatings,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Profession',
                prefixIcon: Icon(Icons.work),
              ),
              initialValue: selectedProfession,
              items: professions
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (val) => setState(() => selectedProfession = val),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pincodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter Pincode',
                prefixIcon: Icon(Icons.location_on),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: selectedProfession == null
                  ? const Center(
                      child: Text(
                        'Please select a profession',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('workers')
                          .where('profession', isEqualTo: selectedProfession)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs = snapshot.data!.docs;
                        final filteredDocs = (pincodeController.text.isNotEmpty)
                            ? docs.where((doc) {
                                final pin = (doc['pincode'] ?? '')
                                    .toString()
                                    .trim();
                                return pin.startsWith(
                                  pincodeController.text.trim(),
                                );
                              }).toList()
                            : docs;

                        if (filteredDocs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No workers found',
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: filteredDocs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final doc = filteredDocs[index];
                            final data = doc.data()! as Map<String, dynamic>;
                            final photoUrl = data['profilePhotoUrl'] ?? '';
                            final name = data['fullName'] ?? 'No Name';
                            final mobile = data['mobile'] ?? 'No Number';
                            final avgRating = (data['rating'] ?? 0).toDouble();
                            final ratingCount = (data['ratingCount'] ?? 0)
                                .toInt();

                            return Card(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 26,
                                  backgroundImage: photoUrl != ''
                                      ? NetworkImage(photoUrl)
                                      : const AssetImage(
                                              'assets/default_profile.png',
                                            )
                                            as ImageProvider,
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          ratingCount > 0
                                              ? '${avgRating.toStringAsFixed(1)} ($ratingCount)'
                                              : 'No ratings yet',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.phone,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          mobile,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: kPrimaryColor,
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ServiceRequestScreen(
                                        workerId: doc.id,
                                        workerName: name,
                                        workerMobile: mobile,
                                      ),
                                    ),
                                  );
                                },
                                onLongPress: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => RateWorkerScreen(
                                        workerId: doc.id,
                                        workerName: name,
                                      ),
                                    ),
                                  );
                                  setState(() {}); // Refresh after rating
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show confirmation dialog before resetting ratings
  Future<void> _confirmResetRatings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Ratings?'),
        content: const Text(
          'This will clear all ratings and rating counts for all workers. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _resetWorkerRatings();
    }
  }

  /// Reset rating and ratingCount fields in all workers documents
  Future<void> _resetWorkerRatings() async {
    setState(() => isResetting = true);

    try {
      final workersSnap = await FirebaseFirestore.instance
          .collection('workers')
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in workersSnap.docs) {
        batch.set(doc.reference, {
          'rating': 0,
          'ratingCount': 0,
        }, SetOptions(merge: true));
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All ratings have been reset')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error resetting ratings: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => isResetting = false);
      }
    }
  }
}

/// ------------------- SERVICE REQUEST SCREEN -------------------
class ServiceRequestScreen extends StatefulWidget {
  final String workerId;
  final String workerName;
  final String workerMobile;

  const ServiceRequestScreen({
    super.key,
    required this.workerId,
    required this.workerName,
    required this.workerMobile,
  });

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  DateTime? selectedDate;
  final TextEditingController descriptionController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    descriptionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Request Service - ${widget.workerName}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.phone, color: kPrimaryColor),
                title: Text(
                  widget.workerMobile,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(
                selectedDate == null
                    ? 'Select Date'
                    : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
              ),
              onPressed: () async {
                final now = DateTime.now();
                final date = await showDatePicker(
                  context: context,
                  initialDate: now,
                  firstDate: now,
                  lastDate: DateTime(now.year + 2),
                );
                if (date != null) setState(() => selectedDate = date);
              },
            ),
            const SizedBox(height: 24),
            TextField(
              controller: descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Describe the issue',
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed:
                  (selectedDate != null &&
                      descriptionController.text.trim().isNotEmpty)
                  ? _sendRequest
                  : null,
              child: const Text('Send Request'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendRequest() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login required')));
      return;
    }
    final requestData = {
      'userId': user.uid,
      'workerId': widget.workerId,
      'workerMobile': widget.workerMobile,
      'workerName': widget.workerName,
      'requestedDate': selectedDate,
      'fixDescription': descriptionController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    };
    await FirebaseFirestore.instance
        .collection('work_requests')
        .add(requestData);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request submitted')));
      Navigator.of(context).pop();
    }
  }
}

/// ------------------- RATE WORKER SCREEN -------------------
class RateWorkerScreen extends StatefulWidget {
  final String workerId;
  final String workerName;

  const RateWorkerScreen({
    super.key,
    required this.workerId,
    required this.workerName,
  });

  @override
  State<RateWorkerScreen> createState() => _RateWorkerScreenState();
}

class _RateWorkerScreenState extends State<RateWorkerScreen> {
  double rating = 0;
  final TextEditingController reviewController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  String? reviewDocId;

  Map<String, Map<String, String>> userCache = {};

  @override
  void initState() {
    super.initState();
    _loadExistingReview();
  }

  Future<void> _loadExistingReview() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    final docId = "${widget.workerId}_${user.uid}";
    final doc = await FirebaseFirestore.instance
        .collection('worker_reviews')
        .doc(docId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      rating = (data['rating'] ?? 0).toDouble();
      reviewController.text = data['review'] ?? '';
      reviewDocId = doc.id;
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rate ${widget.workerName}')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Give a rating to ${widget.workerName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (i) => IconButton(
                        icon: Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          color: kAccentColor,
                          size: 36,
                        ),
                        onPressed: () => setState(() => rating = i + 1.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: reviewController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Write a review (optional)',
                      prefixIcon: Icon(Icons.rate_review),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: rating > 0 ? _submitReview : null,
                    child: const Text('Submit Review'),
                  ),
                  const Divider(height: 32),
                  const Text(
                    'All Reviews',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('worker_reviews')
                          .where('workerId', isEqualTo: widget.workerId)
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        final userIds = docs
                            .map((doc) => doc['userId'] as String)
                            .toSet()
                            .toList();

                        return FutureBuilder<List<DocumentSnapshot>>(
                          future: Future.wait(
                            userIds.map(
                              (id) => FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(id)
                                  .get(),
                            ),
                          ),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState !=
                                ConnectionState.done) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (userSnapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Error loading user info: ${userSnapshot.error}',
                                ),
                              );
                            }

                            userCache.clear();
                            for (var userDoc in userSnapshot.data ?? []) {
                              if (userDoc.exists) {
                                final data =
                                    userDoc.data() as Map<String, dynamic>;
                                userCache[userDoc.id] = {
                                  'fullName':
                                      data['fullName']?.toString() ??
                                      'Anonymous',
                                  'profilePhoto':
                                      data['profilePhotoUrl']?.toString() ?? '',
                                };
                              }
                            }

                            return ListView.separated(
                              itemCount: docs.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final review =
                                    docs[index].data() as Map<String, dynamic>;

                                final userId = review['userId'] as String;
                                final userData = userCache[userId];
                                final userName =
                                    userData?['fullName'] ?? 'Anonymous';
                                final userPhotoUrl =
                                    userData?['profilePhoto'] ?? '';

                                final userRating = (review['rating'] as num)
                                    .toDouble();
                                final reviewText = review['review'] ?? '';

                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      radius: 20,
                                      backgroundImage: userPhotoUrl.isNotEmpty
                                          ? NetworkImage(userPhotoUrl)
                                          : const AssetImage(
                                                  'assets/default_profile.png',
                                                )
                                                as ImageProvider,
                                    ),
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          userName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(userRating.toStringAsFixed(1)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    subtitle: reviewText != ''
                                        ? Text(reviewText)
                                        : null,
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _submitReview() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login required')));
      return;
    }

    final docId = "${widget.workerId}_${user.uid}";
    final reviewRef = FirebaseFirestore.instance
        .collection('worker_reviews')
        .doc(docId);
    final workerRef = FirebaseFirestore.instance
        .collection('workers')
        .doc(widget.workerId);

    final batch = FirebaseFirestore.instance.batch();

    batch.set(reviewRef, {
      'workerId': widget.workerId,
      'userId': user.uid,
      'rating': rating,
      'review': reviewController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Recalculate rating average and count
    final reviewsSnapshot = await FirebaseFirestore.instance
        .collection('worker_reviews')
        .where('workerId', isEqualTo: widget.workerId)
        .get();

    final ratings = reviewsSnapshot.docs
        .map((d) => (d.data()['rating'] as num).toDouble())
        .toList();
    final totalRatings = ratings.length;
    final avgRating = totalRatings > 0
        ? ratings.reduce((a, b) => a + b) / totalRatings
        : 0;

    await workerRef.set({
      'rating': avgRating,
      'ratingCount': totalRatings,
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Review submitted')));
      setState(() {
        // Optionally clear form if needed
        // rating = 0;
        // reviewController.clear();
      });
    }
  }
}
