import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ------------------- THEME -------------------
const Color kPrimaryColor = Color(0xFF00796B); // teal
const Color kAccentColor = Color(0xFFFFD34E); // yellow
const Color kBackgroundColor = Color(0xFF222733); // dark bg
const Color kCardColor = Color.fromARGB(255, 188, 117, 3); // contrast card bg

final ThemeData appTheme = ThemeData(
  scaffoldBackgroundColor: kBackgroundColor,
  primaryColor: kPrimaryColor,
  colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
  appBarTheme: const AppBarTheme(
    backgroundColor: kBackgroundColor,
    foregroundColor: Color.fromARGB(255, 34, 39, 51),
    elevation: 2,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: Colors.white),
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
    fillColor: kCardColor,
    labelStyle: const TextStyle(color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Browse Services',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor:
            kBackgroundColor, // <-- this sets the dark color explicitly
        iconTheme: const IconThemeData(color: Colors.white), // keep icons white
        // shape and other properties as needed
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(
                  255,
                  225,
                  233,
                  0,
                ), // Your desired background
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButtonFormField<String>(
                dropdownColor: const Color.fromARGB(255, 225, 233, 0),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Select Profession',
                  prefixIcon: Icon(Icons.work),
                  border:
                      InputBorder.none, // Optional: Remove border if desired
                ),
                items: professions
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          p,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
                value: selectedProfession,
                onChanged: (val) => setState(() => selectedProfession = val),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(
                  255,
                  225,
                  233,
                  0,
                ), // Your desired background color
                borderRadius: BorderRadius.circular(20), // for rounded look
              ),
              child: TextField(
                controller: pincodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter Pincode',
                  prefixIcon: Icon(Icons.location_on),
                  border: InputBorder.none, // remove extra border, optional
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => setState(() {}),
              ),
            ),

            const SizedBox(height: 16),
            Expanded(
              child: selectedProfession == null
                  ? const Center(
                      child: Text(
                        'Please select a profession',
                        style: TextStyle(color: Colors.white),
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
                            child: CircularProgressIndicator(
                              color: kAccentColor,
                            ),
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
                              color: kCardColor,
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
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
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
                                          style: const TextStyle(
                                            color: Colors.white70,
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
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: kAccentColor,
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
                                  setState(() {});
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
}

/// ------------------- SERVICE REQUEST SCREEN ------------------
class ServiceRequestScreen extends StatefulWidget {
  final String workerId;
  final String workerName;
  final String workerMobile;
  final String? workRequestId;
  final String? prefilledDescription;
  final DateTime? prefilledDate;

  const ServiceRequestScreen({
    super.key,
    required this.workerId,
    required this.workerName,
    required this.workerMobile,
    this.workRequestId,
    this.prefilledDescription,
    this.prefilledDate,
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
    if (widget.prefilledDescription != null) {
      descriptionController.text = widget.prefilledDescription!;
    }
    selectedDate = widget.prefilledDate;
    descriptionController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Request Service - ${widget.workerName}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: kBackgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: kCardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.phone, color: kAccentColor),
                title: Text(
                  widget.workerMobile,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today, color: kAccentColor),
              label: Text(
                selectedDate == null
                    ? 'Select Date'
                    : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                style: const TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? now,
                  firstDate: now,
                  lastDate: DateTime(now.year + 2),
                  builder: (context, child) => Theme(
                    data: appTheme.copyWith(
                      colorScheme: appTheme.colorScheme.copyWith(
                        primary: kAccentColor,
                        onPrimary: Colors.white,
                        background: kBackgroundColor,
                        surface: kCardColor,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => selectedDate = picked);
              },
              style: ElevatedButton.styleFrom(backgroundColor: kCardColor),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: descriptionController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Describe the issue',
                prefixIcon: Icon(Icons.description, color: kAccentColor),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed:
                  (selectedDate != null &&
                      descriptionController.text.trim().isNotEmpty)
                  ? _sendOrUpdateRequest
                  : null,
              child: Text(
                widget.workRequestId == null
                    ? 'Send Request'
                    : 'Update Request',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendOrUpdateRequest() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login required')));
      return;
    }

    try {
      if (widget.workRequestId == null) {
        await FirebaseFirestore.instance.collection('work_requests').add({
          'userId': user.uid,
          'createdBy': user.uid,
          'workerId': widget.workerId,
          'workerMobile': widget.workerMobile,
          'workerName': widget.workerName,
          'requestedDate': selectedDate,
          'fixDescription': descriptionController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request submitted successfully')),
        );
      } else {
        await FirebaseFirestore.instance
            .collection('work_requests')
            .doc(widget.workRequestId)
            .update({
              'requestedDate': selectedDate,
              'fixDescription': descriptionController.text.trim(),
              'status': 'pending',
            });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request updated successfully')),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    final doc = await FirebaseFirestore.instance
        .collection('worker_reviews')
        .doc("${widget.workerId}_${user.uid}")
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
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Rate ${widget.workerName}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: kBackgroundColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: kAccentColor))
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
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Write a review (optional)',
                      prefixIcon: Icon(Icons.rate_review, color: kAccentColor),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: rating > 0 ? _submitReview : null,
                    child: const Text('Submit Review'),
                  ),
                  const Divider(height: 32, color: Colors.white24),
                  const Text(
                    'All Reviews',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
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
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: kAccentColor,
                            ),
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
                                child: CircularProgressIndicator(
                                  color: kAccentColor,
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
                                  color: kCardColor,
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
                                            color: Colors.white,
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
                                            Text(
                                              userRating.toStringAsFixed(1),
                                              style: const TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    subtitle: reviewText != ''
                                        ? Text(
                                            reviewText,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                          )
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
      setState(() {});
    }
  }
}
