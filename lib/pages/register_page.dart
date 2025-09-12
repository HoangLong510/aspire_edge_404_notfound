import 'package:aspire_edge_404_notfound/config/industries.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ===================== Register Page =====================
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  final Map<String, String> _tierOptions = {
    'student': 'Student',
    'postgraduate': 'Undergraduates/Postgraduates',
    'professionals': 'Professionals',
  };

  String? _selectedTierKey;
  String? _selectedIndustryId;
  String? _selectedCareerId;
  String? _selectedCareerPathId;
  String? _userId;

  bool _isLoading = false;
  bool _isStepTwo = false; // flag cho bước 2

  // ================= Register User (Step 1) =================
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      _userId = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('Users').doc(_userId).set({
        'User_Id': _userId,
        'Name': _nameController.text.trim(),
        'E-mail': _emailController.text.trim(),
        'Phone': _phoneController.text.trim(),
        'Tier': _selectedTierKey,
        'IndustryId': null,
        'CareerBankId': null,
        'CareerPathId': null,
      });

      if (mounted) {
        if (_selectedTierKey == 'professionals') {
          // chuyển qua step 2 ngay trên RegisterPage
          setState(() {
            _isStepTwo = true;
          });
        } else {
          await FirebaseAuth.instance.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please log in.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred. Please try again.';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'This email is already in use.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= Save Professional Info (Step 2) =================
  Future<void> _saveProfessionalInfo() async {
    if (_selectedIndustryId == null ||
        _selectedCareerId == null ||
        _selectedCareerPathId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('Users').doc(_userId).update({
        'IndustryId': _selectedIndustryId,
        'CareerBankId': _selectedCareerId,
        'CareerPathId': _selectedCareerPathId,
      });

      if (mounted) {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please log in.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
      filled: true,
      fillColor: Colors.grey.withOpacity(0.1),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: !_isStepTwo ? _buildStepOne(context) : _buildStepTwo(context),
        ),
      ),
    );
  }

  // Step 1 UI
  Widget _buildStepOne(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create Account',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Join us to start your journey.',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Name
          TextFormField(
            controller: _nameController,
            decoration: _buildInputDecoration('Full Name', Icons.person_outline),
            validator: (v) =>
                v!.isEmpty ? 'Please enter your full name' : null,
          ),
          const SizedBox(height: 20),

          // Email
          TextFormField(
            controller: _emailController,
            decoration: _buildInputDecoration('E-mail', Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v!.isEmpty || !v.contains('@')
                ? 'Please enter a valid email'
                : null,
          ),
          const SizedBox(height: 20),

          // Password
          TextFormField(
            controller: _passwordController,
            decoration: _buildInputDecoration('Password', Icons.lock_outline),
            obscureText: true,
            validator: (v) => v!.length < 6
                ? 'Password must be at least 6 characters'
                : null,
          ),
          const SizedBox(height: 20),

          // Confirm password
          TextFormField(
            controller: _confirmPasswordController,
            decoration: _buildInputDecoration(
                'Confirm Password', Icons.lock_outline),
            obscureText: true,
            validator: (v) =>
                v!.isEmpty ? 'Please confirm your password' : null,
          ),
          const SizedBox(height: 20),

          // Phone
          TextFormField(
            controller: _phoneController,
            decoration:
                _buildInputDecoration('Phone Number', Icons.phone_outlined),
            keyboardType: TextInputType.phone,
            validator: (v) =>
                v!.isEmpty ? 'Please enter your phone number' : null,
          ),
          const SizedBox(height: 20),

          // Tier
          DropdownButtonFormField<String>(
            value: _selectedTierKey,
            decoration: _buildInputDecoration('I am a...', Icons.school_outlined),
            items: _tierOptions.entries
                .map((e) =>
                    DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) {
              setState(() {
                _selectedTierKey = v;
              });
            },
            validator: (v) => v == null ? 'Please select an option' : null,
          ),
          const SizedBox(height: 40),

          // Submit
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
          const SizedBox(height: 24),

          // Login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Already have an account?",
                  style: TextStyle(color: Colors.grey[700])),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Login',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 2 UI (professionals only)
  Widget _buildStepTwo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Complete Professional Info',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),

        // Industry
        DropdownButtonFormField<String>(
          value: _selectedIndustryId,
          decoration: _buildInputDecoration('Select Industry', Icons.work_outline),
          items: INDUSTRIES
              .map((ind) => DropdownMenuItem(
                    value: ind.id,
                    child: Row(
                      children: [
                        Icon(ind.icon, size: 18),
                        const SizedBox(width: 8),
                        Text(ind.name),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            setState(() {
              _selectedIndustryId = v;
              _selectedCareerId = null;
              _selectedCareerPathId = null;
            });
          },
        ),
        const SizedBox(height: 20),

        // CareerBank
        if (_selectedIndustryId != null)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('CareerBank')
                .where('IndustryId', isEqualTo: _selectedIndustryId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Text('No careers available.');
              }
              return DropdownButtonFormField<String>(
                value: _selectedCareerId,
                decoration: _buildInputDecoration(
                    'Select Career (CareerBank)', Icons.cases_outlined),
                items: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(data['Title'] ?? 'Untitled'),
                  );
                }).toList(),
                onChanged: (v) => setState(() {
                  _selectedCareerId = v;
                  _selectedCareerPathId = null;
                }),
              );
            },
          ),
        const SizedBox(height: 20),

        // CareerPaths (sub-collection)
        if (_selectedCareerId != null)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('CareerBank')
                .doc(_selectedCareerId)
                .collection('CareerPaths')
                .orderBy('Level_Order')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Text('No career paths available.');
              }
              return DropdownButtonFormField<String>(
                value: _selectedCareerPathId,
                decoration: _buildInputDecoration(
                    'Select Career Path (Level)', Icons.timeline),
                items: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(data['Level_Name'] ?? 'Untitled'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedCareerPathId = v),
              );
            },
          ),
        const SizedBox(height: 40),

        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: _saveProfessionalInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                child: const Text(
                  'Save Info',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
      ],
    );
  }
}
