import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color kPrimaryColor = Color(0xFF00796B);
const Color kAccentColor = Color(0xFFFFD34E);
const Color kBackgroundColor = Color(0xFF222733);
const Color kCardColor = Color.fromARGB(255, 188, 117, 3);

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
