// lib/screens/service_browse.dart
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
    elevation: 2,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: Colors.white),
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

  String? selectedLocation;
  List<String> availableLocations = [];

  // ---------- HELPERS ----------
  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  String _normalize(String v) => v.trim().toLowerCase();

  @override
  void dispose() {
    pincodeController.dispose();
    super.dispose();
  }

  // ---------- FETCH LOCATIONS FOR EXACT PINCODE ----------
  Future<void> fetchLocationsForPincode(String pincode) async {
    selectedLocation = null;
    availableLocations.clear();

    if (pincode.length != 6) {
      setState(() {});
      return;
    }

    final snap = await FirebaseFirestore.instance
        .collection('workers')
        .where('isApproved', isEqualTo: true)
        .where('pincode', isEqualTo: pincode.trim())
        .get();

    final Set<String> locations = {};

    for (var doc in snap.docs) {
      final loc = (doc['location'] ?? '').toString().trim();
      if (loc.isNotEmpty) {
        locations.add(_normalize(loc));
      }
    }

    availableLocations = locations.toList()..sort();
    setState(() {});
  }

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
            /// -------- PROFESSION DROPDOWN --------
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 161, 198, 234),
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButtonFormField<String>(
                dropdownColor: const Color.fromARGB(255, 161, 198, 234),
                decoration: const InputDecoration(
                  labelText: 'Select Profession',
                  prefixIcon: Icon(Icons.work),
                  border: InputBorder.none,
                ),
                items: professions
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p,
                            style:
                                const TextStyle(color: Colors.black)),
                      ),
                    )
                    .toList(),
                value: selectedProfession,
                onChanged: (val) => setState(() => selectedProfession = val),
              ),
            ),

            const SizedBox(height: 16),

            /// -------- PINCODE FIELD --------
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
                onChanged: fetchLocationsForPincode,
              ),
            ),

            /// -------- LOCATION DROPDOWN --------
            if (availableLocations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 161, 198, 234),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButtonFormField<String>(
                  dropdownColor: const Color.fromARGB(255, 161, 198, 234),
                  decoration: const InputDecoration(
                    labelText: 'Select Location',
                    prefixIcon: Icon(Icons.place),
                    border: InputBorder.none,
                  ),
                  value: selectedLocation,
                  items: availableLocations
                      .map(
                        (loc) => DropdownMenuItem(
                          value: loc,
                          child: Text(
                            loc,
                            style:
                                const TextStyle(color: Colors.black),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setState(() => selectedLocation = val),
                ),
              ),
            ],

            const SizedBox(height: 16),

            /// -------- WORKER LIST (OLD DESIGN) --------
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
                          .where('profession',
                              isEqualTo: selectedProfession)
                          .where('isApproved', isEqualTo: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: kAccentColor),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        /// FILTER
                        final filteredDocs = docs.where((doc) {
                          final data =
                              doc.data() as Map<String, dynamic>;

                          if (pincodeController.text.trim().length ==
                              6) {
                            if (data['pincode']
                                    ?.toString()
                                    .trim() !=
                                pincodeController.text.trim()) {
                              return false;
                            }
                          }

                          if (selectedLocation != null) {
                            final loc =
                                _normalize(data['location'] ?? '');
                            if (loc != selectedLocation) return false;
                          }

                          return true;
                        }).toList();

                        /// SORT (OLD LOGIC)
                        filteredDocs.sort((a, b) {
                          final aData =
                              a.data() as Map<String, dynamic>;
                          final bData =
                              b.data() as Map<String, dynamic>;

                          final aRating = _toDouble(aData['rating']);
                          final bRating = _toDouble(bData['rating']);
                          final aCount =
                              _toInt(aData['ratingCount']);
                          final bCount =
                              _toInt(bData['ratingCount']);

                          if (bRating.compareTo(aRating) != 0) {
                            return bRating.compareTo(aRating);
                          }
                          return bCount.compareTo(aCount);
                        });

                        if (filteredDocs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No workers found',
                              style:
                                  TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: filteredDocs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final doc = filteredDocs[index];
                            final data =
                                doc.data() as Map<String, dynamic>;

                            final photoUrl =
                                data['profilePhotoUrl'] ?? '';
                            final name =
                                data['fullName'] ?? 'No Name';
                            final mobile =
                                data['mobile'] ?? 'No Number';
                            final avgRating =
                                _toDouble(data['rating']);
                            final ratingCount =
                                _toInt(data['ratingCount']);

                            return Card(
                              color: kCardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 26,
                                  backgroundImage: photoUrl != ''
                                      ? NetworkImage(photoUrl)
                                      : const AssetImage(
                                              'assets/default_profile.png')
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star,
                                            color: Colors.amber,
                                            size: 16),
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
                                        const Icon(Icons.phone,
                                            size: 16,
                                            color: Colors.green),
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
                                      builder: (_) =>
                                          ServiceRequestScreen(
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
  void dispose() {
    descriptionController.dispose();
    super.dispose();
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
