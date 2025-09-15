import 'dart:async';
import 'dart:math';
import 'package:aspire_edge_404_notfound/constants/industries.dart';
import 'package:aspire_edge_404_notfound/utils/smtp_email_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'otp_verification_page.dart';

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

  String? _emailError;
  String? _phoneError;

  bool _isLoading = false;
  bool _isStepTwo = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  Future<bool> _isEmailTaken(String email) async {
    final usersRef = FirebaseFirestore.instance.collection('Users');
    final emailSnap = await usersRef
        .where('E-mail', isEqualTo: email)
        .limit(1)
        .get();
    return emailSnap.docs.isNotEmpty;
  }

  Future<bool> _isPhoneTaken(String phone) async {
    final usersRef = FirebaseFirestore.instance.collection('Users');
    final phoneSnap = await usersRef
        .where('Phone', isEqualTo: phone)
        .limit(1)
        .get();
    return phoneSnap.docs.isNotEmpty;
  }

  Future<void> _registerUser() async {
    setState(() {
      _emailError = null;
      _phoneError = null;
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });

    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Passwords do not match', Colors.red);
      return;
    }

    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    final emailTaken = await _isEmailTaken(email);
    final phoneTaken = await _isPhoneTaken(phone);

    if (emailTaken || phoneTaken) {
      setState(() {
        if (emailTaken) _emailError = 'This email is already in use';
        if (phoneTaken) _phoneError = 'This phone number is already in use';
      });
      return;
    }

    if (_selectedTierKey == 'professionals') {
      setState(() => _isStepTwo = true);
    } else {
      _goToOtpVerification(extraData: {});
    }
  }

  Future<void> _saveProfessionalInfo() async {
    if (_selectedIndustryId == null ||
        _selectedCareerId == null ||
        _selectedCareerPathId == null) {
      _showMessage('Please complete all fields', Colors.red);
      return;
    }

    _goToOtpVerification(
      extraData: {
        'IndustryId': _selectedIndustryId,
        'CareerBankId': _selectedCareerId,
        'CareerPathId': _selectedCareerPathId,
      },
    );
  }

  Future<void> _goToOtpVerification({
    required Map<String, dynamic> extraData,
  }) async {
    setState(() => _isLoading = true);

    final otp = (Random().nextInt(900000) + 100000).toString();
    final expiry = DateTime.now().add(const Duration(minutes: 1));

    final tempData = {
      'Name': _nameController.text.trim(),
      'E-mail': _emailController.text.trim(),
      'Password': _passwordController.text.trim(),
      'Phone': _phoneController.text.trim(),
      'Tier': _selectedTierKey,
      ...extraData,
      'otp': otp,
      'otpExpiry': expiry.toIso8601String(),
    };

    await SmtpEmailService.sendOtpEmail(
      toEmail: _emailController.text.trim(),
      otp: otp,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationPage(tempData: tempData),
        ),
      );
    }
  }

  void _showMessage(String text, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
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

  InputDecoration _buildInputDecoration(
    String label,
    IconData icon, {
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      errorText: errorText,
      prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
      filled: true,
      fillColor: Colors.grey.withOpacity(0.1),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: !_isStepTwo
                  ? _buildStepOne(context)
                  : _buildStepTwo(context),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildStepOne(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          TextFormField(
            controller: _nameController,
            decoration: _buildInputDecoration(
              'Full Name',
              Icons.person_outline,
            ),
            validator: (v) => v!.isEmpty ? 'Please enter your full name' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            decoration: _buildInputDecoration(
              'E-mail',
              Icons.email_outlined,
              errorText: _emailError,
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your email';
              if (!v.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            decoration: _buildInputDecoration('Password', Icons.lock_outline),
            obscureText: true,
            validator: (v) =>
                v!.length < 6 ? 'Password must be at least 6 characters' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: _buildInputDecoration(
              'Confirm Password',
              Icons.lock_outline,
            ),
            obscureText: true,
            validator: (v) {
              if (v!.isEmpty) return 'Please confirm your password';
              if (v != _passwordController.text)
                return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _phoneController,
            decoration: _buildInputDecoration(
              'Phone Number',
              Icons.phone_outlined,
              errorText: _phoneError,
            ),
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.isEmpty)
                return 'Please enter your phone number';
              if (v.length < 9) return 'Phone number seems too short';
              return null;
            },
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedTierKey,
            decoration: _buildInputDecoration(
              'I am a...',
              Icons.school_outlined,
            ),
            items: _tierOptions.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedTierKey = v),
            validator: (v) => v == null ? 'Please select an option' : null,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _registerUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
            ),
            child: Text(
              _selectedTierKey == 'professionals' ? 'Next Step' : 'Register',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Already have an account?",
                style: TextStyle(color: Colors.grey[700]),
              ),
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

  Widget _buildStepTwo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Just One More Step to Get Started',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        DropdownButtonFormField<String>(
          value: _selectedIndustryId,
          decoration: _buildInputDecoration(
            'Select Industry',
            Icons.work_outline,
          ),
          items: INDUSTRIES
              .map(
                (ind) => DropdownMenuItem(
                  value: ind.id,
                  child: Row(
                    children: [
                      Icon(ind.icon, size: 18),
                      const SizedBox(width: 8),
                      Text(ind.name),
                    ],
                  ),
                ),
              )
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
              if (docs.isEmpty) return const Text('No careers available.');
              return DropdownButtonFormField<String>(
                value: _selectedCareerId,
                decoration: _buildInputDecoration(
                  'Select Career',
                  Icons.cases_outlined,
                ),
                items: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(data['Title'] ?? 'Untitled'),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedCareerId = v;
                    _selectedCareerPathId = null;
                  });
                },
              );
            },
          ),
        const SizedBox(height: 20),
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
              if (docs.isEmpty) return const Text('No career paths available.');
              return DropdownButtonFormField<String>(
                value: _selectedCareerPathId,
                decoration: _buildInputDecoration(
                  'Select Career Path',
                  Icons.timeline,
                ),
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
        ElevatedButton(
          onPressed: _saveProfessionalInfo,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 5,
          ),
          child: const Text(
            'Continue',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
