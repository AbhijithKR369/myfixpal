import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController aadhaarController = TextEditingController();

  bool isWorker = false;
  DateTime? selectedDob;
  String? selectedProfession;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  String get dobText => selectedDob != null
      ? DateFormat('yyyy-MM-dd').format(selectedDob!)
      : 'Select Date of Birth';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    locationController.dispose();
    pincodeController.dispose();
    aadhaarController.dispose();
    super.dispose();
  }

  Future<void> registerUser() async {
    if (passwordController.text != confirmPasswordController.text) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email and password are required")),
      );
      return;
    }

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          );

      if (!mounted) return;

      User? user = userCredential.user;

      if (user != null) {
        if (!isWorker) {
          // Regular user: write into 'users' collection only
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': emailController.text.trim(),
            'fullName': fullNameController.text.trim(),
            'mobile': mobileController.text.trim(),
            'dob': selectedDob != null ? dobText : null,
            'isWorker': false,
          });
        } else {
          // Worker: write into 'workers' collection only
          await _firestore.collection('workers').doc(user.uid).set({
            'uid': user.uid,
            'email': emailController.text.trim(),
            'fullName': fullNameController.text.trim(),
            'mobile': mobileController.text.trim(),
            'dob': selectedDob != null ? dobText : null,
            'isWorker': true,
            'location': locationController.text.trim(),
            'pincode': pincodeController.text.trim(),
            'profession': selectedProfession,
            'aadhaar': aadhaarController.text.trim(),
          });
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration successful!")),
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          isWorker ? '/home_worker' : '/home_user',
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        message = 'Email already in use';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An unexpected error occurred.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFF222733); // dark blue/gray
    const Color accentColor = Color(0xFFFFD34E); // yellow
    const Color primaryColor = Color(0xFF00796B); // teal

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: fullNameController,
                    labelText: 'Full Name',
                    prefixIcon: Icons.person,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: emailController,
                    labelText: 'Email',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: mobileController,
                    labelText: 'Mobile Number',
                    prefixIcon: Icons.phone_android,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordField(
                    controller: passwordController,
                    labelText: 'Password',
                    obscureText: _obscurePassword,
                    toggleVisibility: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordField(
                    controller: confirmPasswordController,
                    labelText: 'Confirm Password',
                    obscureText: _obscureConfirmPassword,
                    toggleVisibility: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Date of Birth',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () async {
                      DateTime initialDate = DateTime(
                        DateTime.now().year - 18,
                        1,
                        1,
                      );
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      setState(() => selectedDob = picked);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(
                          Icons.calendar_today,
                          color: Colors.white70,
                        ),
                        filled: true,
                        fillColor: backgroundColor.withAlpha(
                          (0.8 * 255).toInt(),
                        ),
                      ),
                      child: Text(
                        dobText,
                        style: TextStyle(
                          color: selectedDob != null
                              ? Colors.white
                              : Colors.white60,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text(
                      "Register as Worker",
                      style: TextStyle(color: Colors.white70),
                    ),
                    value: isWorker,
                    onChanged: (val) {
                      setState(() => isWorker = val ?? false);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (isWorker) ...[
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: locationController,
                      labelText: 'Location',
                      prefixIcon: Icons.location_on,
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: pincodeController,
                      labelText: 'Pincode',
                      prefixIcon: Icons.pin_drop,
                      keyboardType: TextInputType.number,
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Job/Profession',
                        prefixIcon: const Icon(
                          Icons.work,
                          color: Colors.white70,
                        ),
                        filled: true,
                        fillColor: backgroundColor.withAlpha(
                          (0.8 * 255).toInt(),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: accentColor, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white24,
                            width: 1,
                          ),
                        ),
                      ),
                      dropdownColor: backgroundColor,
                      initialValue: selectedProfession,
                      items:
                          const [
                                'Painter',
                                'Electrician',
                                'Carpenter',
                                'Plumber',
                              ]
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() => selectedProfession = value);
                      },
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: aadhaarController,
                      labelText: 'Aadhaar Number',
                      prefixIcon: Icons.credit_card,
                      keyboardType: TextInputType.number,
                      maxLength: 12,
                      accentColor: accentColor,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black87,
                        minimumSize: const Size(150, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: registerUser,
                      child: const Text('Register'),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Already have an account? Login',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    required Color accentColor,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(prefixIcon, color: accentColor),
        filled: true,
        fillColor: const Color(0xFF222733).withAlpha((0.8 * 255).toInt()),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white24, width: 1),
        ),
        counterText: '',
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required bool obscureText,
    required VoidCallback toggleVisibility,
    required Color accentColor,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(Icons.lock, color: accentColor),
        filled: true,
        fillColor: const Color(0xFF222733).withAlpha((0.8 * 255).toInt()),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white24, width: 1),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.white70,
          ),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }
}
