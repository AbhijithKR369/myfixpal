import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color kBg = Color(0xFF222733);
const Color kAccent = Color(0xFFFFD34E);

class ReportIssueScreen extends StatefulWidget {
  final String workerName;
  final String workerId;
  final String workRequestId;

  const ReportIssueScreen({
    super.key,
    required this.workerName,
    required this.workerId,
    required this.workRequestId,
  });

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final TextEditingController _descCtrl = TextEditingController();
  bool submitting = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final user = FirebaseAuth.instance.currentUser;

    // 🔒 Auth check
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to report')),
      );
      return;
    }

    // 📝 Validation
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue')),
      );
      return;
    }

    setState(() => submitting = true);

    try {
      await FirebaseFirestore.instance.collection('job_reports').add({
        'reporterId': user.uid,
        'workerId': widget.workerId,
        'workRequestId': widget.workRequestId,
        'workerName': widget.workerName,
        'issueType': 'Accepted but not completed',
        'description': _descCtrl.text.trim(),
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => submitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Report Issue'),
        backgroundColor: kBg,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Worker: ${widget.workerName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Describe the issue',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: kBg.withOpacity(0.85),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kAccent, width: 2),
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: submitting ? null : _submitReport,
              child: submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'Submit Report',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
