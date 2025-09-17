import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Define your app's color theme based on login/register pages
const Color kPrimaryColor = Color(0xFF6C63FF); // replace with your primary
const Color kAccentColor = Color(0xFFFFB300); // replace with your accent

final ThemeData appTheme = ThemeData(
  primaryColor: kPrimaryColor,
  colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
  appBarTheme: AppBarTheme(
    backgroundColor: kPrimaryColor,
    foregroundColor: Colors.white,
    elevation: 2,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(vertical: 16),
      elevation: 3,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey[100],
    labelStyle: TextStyle(color: kPrimaryColor),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: kPrimaryColor, width: 2),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    prefixIconColor: kPrimaryColor,
  ),
);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Services'),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: kPrimaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Profession',
                  border: InputBorder.none,
                ),
                initialValue: selectedProfession,
                items: professions
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) => setState(() => selectedProfession = val),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pincodeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter Pincode',
                prefixIcon: const Icon(Icons.location_on),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: selectedProfession == null
                  ? const Center(child: Text('Please select a profession'))
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
                          return const Center(child: Text('No workers found'));
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

                            return FutureBuilder<QuerySnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('worker_reviews')
                                  .where('workerId', isEqualTo: doc.id)
                                  .get(),
                              builder: (context, reviewsSnapshot) {
                                double avgRating = 0.0;
                                int reviewCount = 0;

                                if (reviewsSnapshot.hasData) {
                                  final reviews = reviewsSnapshot.data!.docs;
                                  reviewCount = reviews.length;
                                  if (reviewCount > 0) {
                                    double total = 0;
                                    for (var r in reviews) {
                                      total += (r['rating'] as num).toDouble();
                                    }
                                    avgRating = total / reviewCount;
                                  }
                                }

                                return Card(
                                  elevation: 3,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                              reviewCount > 0
                                                  ? '${avgRating.toStringAsFixed(1)} ($reviewCount)'
                                                  : 'No ratings yet',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
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
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
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
                                    onLongPress: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => RateWorkerScreen(
                                            workerId: doc.id,
                                            workerName: name,
                                          ),
                                        ),
                                      );
                                    },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Menu pressed')));
          // Add action to open drawer or menu
        },
        backgroundColor: kPrimaryColor,
        child: const Icon(Icons.menu),
      ),
    );
  }
}

// ServiceRequestScreen and RateWorkerScreen - same as before but styled with theme colors

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Request Service - ${widget.workerName}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: kPrimaryColor.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: kPrimaryColor,
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
              decoration: InputDecoration(
                labelText: 'Describe the issue',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (_) => setState(() {}),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed:
                    (selectedDate != null &&
                        descriptionController.text.trim().isNotEmpty)
                    ? _sendRequest
                    : null,
                child: const Text('Send Request'),
              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rate ${widget.workerName}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              'Give a rating to ${widget.workerName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              decoration: InputDecoration(
                labelText: 'Write a review',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (_) => setState(() {}),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed:
                    (rating > 0 && reviewController.text.trim().isNotEmpty)
                    ? _submitRating
                    : null,
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- UPDATED: Submit rating and recalculate average ----------
  Future<void> _submitRating() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login required')));
      return;
    }

    try {
      // 1) Add review doc
      final reviewData = {
        'userId': user.uid,
        'workerId': widget.workerId,
        'rating': rating,
        'review': reviewController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('worker_reviews')
          .add(reviewData);

      // 2) Recalculate average and count from all reviews for this worker
      final reviewsSnap = await FirebaseFirestore.instance
          .collection('worker_reviews')
          .where('workerId', isEqualTo: widget.workerId)
          .get();

      final allReviews = reviewsSnap.docs;
      final int newCount = allReviews.length;

      double total = 0.0;
      for (final rdoc in allReviews) {
        final rv = rdoc.data()['rating'];
        if (rv is int) {
          total += rv.toDouble();
        } else if (rv is double) {
          total += rv;
        } else {
          total += double.tryParse(rv?.toString() ?? '0') ?? 0.0;
        }
      }

      final double newAvg = newCount > 0 ? (total / newCount) : 0.0;

      // 3) Update worker document (merge so other fields preserved)
      final workerRef = FirebaseFirestore.instance
          .collection('workers')
          .doc(widget.workerId);

      await workerRef.set({
        'rating': newAvg,
        'ratingCount': newCount,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Review submitted')));

        Navigator.of(context).pop();
      }
    } catch (e, st) {
      // show error for visibility and log stacktrace to console
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit review: $e')));
      }
      // also print to console so you can inspect errors in debug console
      // ignore: avoid_print
      print('Error submitting rating: $e\n$st');
    }
  }
}
