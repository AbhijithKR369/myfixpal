import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color kPrimaryColor = Color(0xFF00796B);
const Color kAccentColor = Color(0xFFFFD34E);
const Color kBackgroundColor = Color(0xFF222733);

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
  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: Text('Rate ${widget.workerName}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.star_rate_rounded,
                    color: kAccentColor,
                    size: 60,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How was your experience?',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final filled = index < _rating;
                return IconButton(
                  icon: Icon(
                    filled ? Icons.star_rounded : Icons.star_border_rounded,
                    color: kAccentColor,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() => _rating = index + 1.0);
                  },
                );
              }),
            ),

            const SizedBox(height: 20),

            // Review Box
            TextField(
              controller: _reviewController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Write a review (optional)',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'Describe your experience...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.edit_note, color: kAccentColor),
                filled: true,
                fillColor: const Color(0xFF2E3340),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: kAccentColor, width: 2),
                ),
              ),
            ),

            const Spacer(),

            // Submit Button
            ElevatedButton.icon(
              onPressed: _isSubmitting || _rating == 0 ? null : _submitReview,
              icon: const Icon(Icons.send_rounded),
              label: _isSubmitting
                  ? const Text('Submitting...')
                  : const Text('Submit Rating'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ------------------- SUBMIT REVIEW -------------------
  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);
    final user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in first')));
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      // Save new review
      await firestore.collection('worker_reviews').add({
        'workerId': widget.workerId,
        'userId': user.uid,
        'reviewText': _reviewController.text.trim(),
        'rating': _rating,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update worker average rating
      final reviews = await firestore
          .collection('worker_reviews')
          .where('workerId', isEqualTo: widget.workerId)
          .get();

      if (reviews.docs.isNotEmpty) {
        double total = 0;
        for (var doc in reviews.docs) {
          total += (doc['rating'] ?? 0).toDouble();
        }
        final avg = total / reviews.docs.length;

        await firestore.collection('workers').doc(widget.workerId).update({
          'rating': avg,
          'ratingCount': reviews.docs.length,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your feedback!'),
          backgroundColor: kPrimaryColor,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting review: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}
