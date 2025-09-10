import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _yearsCtl = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  final Map<String, String> _tierOptions = const {
    'student': 'Student',
    'postgraduate': 'Postgraduate',
    'expert': 'Expert',
  };

  String? _tierKey;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    final me = _auth.currentUser;
    if (me == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final snap = await _db.collection('Users').doc(me.uid).get();
      final data = snap.data() ?? {};
      _nameCtl.text = (data['Name'] ?? me.displayName ?? '').toString();
      _emailCtl.text = (data['E-mail'] ?? me.email ?? '').toString();
      _phoneCtl.text = (data['Phone'] ?? '').toString();
      _tierKey = (data['Tier'] ?? 'student').toString();
      _yearsCtl.text = (data['YearsExperience'] ?? '').toString();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  InputDecoration _dec(String label, IconData icon) {
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final me = _auth.currentUser;
    if (me == null) return;

    setState(() => _saving = true);
    try {
      await _db.collection('Users').doc(me.uid).set({
        'User_Id': me.uid,
        'Name': _nameCtl.text.trim(),
        'E-mail': _emailCtl.text.trim(),
        'Phone': _phoneCtl.text.trim(),
        'Tier': _tierKey,
        if (_tierKey == 'expert') 'YearsExperience': _yearsCtl.text.trim(),
      }, SetOptions(merge: true));

      if (me.displayName != _nameCtl.text.trim()) {
        await me.updateDisplayName(_nameCtl.text.trim());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    _yearsCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'My Profile',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          TextFormField(
            controller: _nameCtl,
            decoration: _dec('Full Name', Icons.person_outline),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _emailCtl,
            readOnly: true,
            decoration: _dec('E-mail (read-only)', Icons.email_outlined),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _phoneCtl,
            decoration: _dec('Phone Number', Icons.phone_outlined),
            keyboardType: TextInputType.phone,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your phone number' : null,
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _tierKey,
            decoration: _dec('I am a...', Icons.school_outlined),
            items: _tierOptions.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _tierKey = v),
            validator: (v) => v == null ? 'Please select an option' : null,
          ),
          const SizedBox(height: 16),

          if (_tierKey == 'expert')
            Column(
              children: [
                TextFormField(
                  controller: _yearsCtl,
                  decoration: _dec('Years of Experience', Icons.work_history_outlined),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (_tierKey != 'expert') return null;
                    if (v == null || v.trim().isEmpty) return 'Please enter years of experience';
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 0 || n > 60) return 'Enter a valid number (0–60)';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),

          const SizedBox(height: 8),
          _saving
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                  ),
                  child: const Text('Save', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
        ],
      ),
    );
  }
}
