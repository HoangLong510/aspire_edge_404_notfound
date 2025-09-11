import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    'postgraduate': 'Postgraduate',
    'expert': 'Expert',
  };
  String? _selectedTierKey;
  bool _isLoading = false;

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    if (_passwordController.text != _confirmPasswordController.text) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Passwords do not match!')));
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final uid = cred.user!.uid;

      await FirebaseFirestore.instance.collection('Users').doc(uid).set({
        'User_Id': uid,
        'Name': _nameController.text.trim(),
        'E-mail': _emailController.text.trim(),
        'Phone': _phoneController.text.trim(),
        'Tier': _selectedTierKey,
        'hasOnboarded': false,
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/achievements', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred. Check the console for details.';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'This email is already in use.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
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
      contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
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
                TextFormField(
                  controller: _nameController,
                  decoration: _buildInputDecoration('Full Name', Icons.person_outline),
                  validator: (v) => v!.isEmpty ? 'Please enter your full name' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: _buildInputDecoration('E-mail', Icons.email_outlined),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v!.isEmpty || !v.contains('@') ? 'Please enter a valid email' : null,
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
                  decoration:
                      _buildInputDecoration('Confirm Password', Icons.lock_outline),
                  obscureText: true,
                  validator: (v) =>
                      v!.isEmpty ? 'Please confirm your password' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _phoneController,
                  decoration:
                      _buildInputDecoration('Phone Number', Icons.phone_outlined),
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v!.isEmpty ? 'Please enter your phone number' : null,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedTierKey,
                  decoration: _buildInputDecoration('I am a...', Icons.school_outlined),
                  items: _tierOptions.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedTierKey = v),
                  validator: (v) => v == null ? 'Please select an option' : null,
                ),
                const SizedBox(height: 40),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
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
                        child: const Text(
                          'Register',
                          style:
                              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account?",
                        style: TextStyle(color: Colors.grey[700])),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushReplacementNamed('/login'),
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
          ),
        ),
      ),
    );
  }
}
