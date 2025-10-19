import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ------------------- THEME -------------------
const Color kPrimaryColor = Color(0xFF00796B);
const Color kAccentColor = Color(0xFFFFD34E);
const Color kBackgroundColor = Color(0xFF222733);
const Color kCardColor = Color.fromARGB(255, 188, 117, 3);

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

/// --------------- SERVICE BROWSE SCREEN -----------------
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
        backgroundColor: kBackgroundColor,
        iconTheme: const IconThemeData(color: Colors.white),
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
                color: const Color.fromARGB(255, 161, 198, 234),
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButtonFormField<String>(
                // set dropdown background to white so item text (black) is visible
                dropdownColor: const Color.fromARGB(255, 161, 198, 234),
                // this style affects the selected value shown in the field
                style: const TextStyle(
                  color: Color.fromARGB(255, 161, 198, 234),
                ),
                decoration: const InputDecoration(
                  labelText: 'Select Profession',
                  prefixIcon: Icon(Icons.work),
                  border: InputBorder.none,
                ),
                items: professions
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        // make the menu items' text black
                        child: Text(
                          p,
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                    )
                    .toList(),
                initialValue: selectedProfession,
                onChanged: (val) => setState(() => selectedProfession = val),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(225, 161, 198, 234),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: pincodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter Pincode',
                  prefixIcon: Icon(Icons.location_on),
                  border: InputBorder.none,
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
                        final sortedDocs = [...docs];
                        sortedDocs.sort((a, b) {
                          final aData = a.data()! as Map<String, dynamic>;
                          final bData = b.data()! as Map<String, dynamic>;
                          final aRating = (aData['rating'] ?? 0).toDouble();
                          final bRating = (bData['rating'] ?? 0).toDouble();
                          final aCount = (aData['ratingCount'] ?? 0).toInt();
                          final bCount = (bData['ratingCount'] ?? 0).toInt();
                          if (bRating.compareTo(aRating) != 0) {
                            return bRating.compareTo(aRating);
                          } else {
                            return bCount.compareTo(aCount);
                          }
                        });

                        final filteredDocs = (pincodeController.text.isNotEmpty)
                            ? sortedDocs.where((doc) {
                                final pin = (doc['pincode'] ?? '')
                                    .toString()
                                    .trim();
                                return pin.startsWith(
                                  pincodeController.text.trim(),
                                );
                              }).toList()
                            : sortedDocs;

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

/// -------- SERVICE REQUEST SCREEN with REVIEWS section ---------
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
                        primary: const Color.fromARGB(255, 243, 30, 11),
                        onPrimary: Colors.white,
                        surface: const Color.fromARGB(255, 12, 3, 188),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(
                  255,
                  0,
                  150,
                  163,
                ), // change to the color you want
                foregroundColor: const Color.fromARGB(
                  255,
                  171,
                  184,
                  2,
                ), // text/icon color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed:
                  (selectedDate != null &&
                      descriptionController.text.trim().isNotEmpty)
                  ? _sendOrUpdateRequest
                  : null,
              child: Text(
                widget.workRequestId == null
                    ? 'Send Request'
                    : 'Update Request',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 18),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            Expanded(flex: 2, child: _buildReviewsSection()),
          ],
        ),
      ),
    );
  }

  /// Review list for worker -- with reviewer's profile image and name
  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Worker Reviews',
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
                  child: CircularProgressIndicator(color: kAccentColor),
                );
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No reviews yet for this worker',
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final review = docs[idx].data() as Map<String, dynamic>;
                  final rating = (review['rating'] ?? 0).toDouble();
                  final reviewText = review['review'] ?? '';
                  final userId = review['userId'] ?? '';

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .get(),
                    builder: (context, userSnap) {
                      String name = 'User';
                      String? photoUrl;
                      var userDoc = userSnap.data;

                      if (userSnap.hasData &&
                          userDoc != null &&
                          userDoc.exists) {
                        // Always use .data()?['field'] for optional fields
                        final data =
                            userDoc.data() as Map<String, dynamic>? ?? {};
                        name = data['fullName'] ?? 'User';
                        photoUrl = data['profilePhotoUrl']?.toString();
                      }

                      ImageProvider profileImage;
                      if (photoUrl != null && photoUrl.trim().isNotEmpty) {
                        profileImage = NetworkImage(photoUrl);
                      } else {
                        profileImage = const AssetImage(
                          'assets/default_profile.png',
                        );
                      }

                      return Card(
                        color: kBackgroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: kAccentColor,
                            radius: 20,
                            backgroundImage: profileImage,
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: reviewText.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    reviewText,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
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
