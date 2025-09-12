import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Services')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label outside dropdown
            const Text(
              'Select Profession',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              value: selectedProfession,
              onChanged: (value) {
                setState(() {
                  selectedProfession = value;
                });
              },
              items: professions
                  .map(
                    (prof) => DropdownMenuItem(value: prof, child: Text(prof)),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            // Label outside pincode
            const Text(
              'Enter Pincode',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: pincodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: selectedProfession == null
                  ? const Center(child: Text('Please select a profession'))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('workers')
                          .where('profession', isEqualTo: selectedProfession)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No workers found'));
                        }

                        // Debug print for Firestore docs fetched
                        for (var doc in snapshot.data!.docs) {
                          debugPrint(
                            'Worker doc: ${doc.id}, profession: ${doc['profession']}, pincode: ${doc['pincode']}',
                          );
                        }

                        final filteredDocs = (pincodeController.text.isNotEmpty)
                            ? snapshot.data!.docs.where((doc) {
                                final pin = doc['pincode']?.toString() ?? '';
                                return pin.startsWith(pincodeController.text);
                              }).toList()
                            : snapshot.data!.docs;

                        if (filteredDocs.isEmpty) {
                          return const Center(child: Text('No workers found'));
                        }

                        return ListView(
                          children: filteredDocs.map((doc) {
                            final data = doc.data()! as Map<String, dynamic>;
                            final photoUrl = data['profilePhotoUrl'] as String?;
                            final name = data['fullName'] ?? 'No Name';
                            final rating = (data['rating'] ?? 0).toDouble();
                            final ratingCount = data['ratingCount'] ?? 0;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      (photoUrl != null && photoUrl.isNotEmpty)
                                      ? NetworkImage(photoUrl)
                                      : const AssetImage(
                                              'assets/default_profile.png',
                                            )
                                            as ImageProvider,
                                ),
                                title: Text(name),
                                subtitle: ratingCount > 0
                                    ? Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${rating.toStringAsFixed(1)} ($ratingCount)',
                                          ),
                                        ],
                                      )
                                    : const Text('No ratings yet'),
                                trailing: ElevatedButton(
                                  child: const Text('Request'),
                                  onPressed: () {
                                    _showRequestDialog(doc.id, name);
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestDialog(String workerId, String workerName) {
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Request Service from $workerName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  selectedDate == null
                      ? 'Select Date'
                      : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                ),
                onPressed: () async {
                  final now = DateTime.now();
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: now,
                    lastDate: DateTime(now.year + 1),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedDate == null
                  ? null
                  : () async {
                      await _submitServiceRequest(workerId, selectedDate!);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Request sent to $workerName'),
                          ),
                        );
                        Navigator.of(ctx).pop();
                      }
                    },
              child: const Text('Send Request'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitServiceRequest(String workerId, DateTime date) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to request')),
      );
      return;
    }

    final requestData = {
      'userId': user.uid,
      'workerId': workerId,
      'requestedDate': date,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    };

    await FirebaseFirestore.instance
        .collection('service_requests')
        .add(requestData);
  }
}
