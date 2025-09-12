import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _email = '';
  String _tier = '';
  String? _avatarUrl;

  bool _loadingProfile = true;
  bool _saving = false;
  bool _uploading = false;
  bool _loggingOut = false;

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream;

  @override
  void initState() {
    super.initState();
    _initProfile();
  }

  Future<void> _initProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loadingProfile = false;
      });
      return;
    }

    _userStream = FirebaseFirestore.instance.collection('Users').doc(user.uid).snapshots();
    _userStream!.listen((snap) {
      if (!mounted) return;
      if (!snap.exists) {
        setState(() => _loadingProfile = false);
        return;
      }
      final data = snap.data()!;
      _nameCtrl.text = (data['Name'] ?? '').toString();
      _phoneCtrl.text = (data['Phone'] ?? '').toString();
      _email = (data['E-mail'] ?? '').toString();
      _tier = (data['Tier'] ?? '').toString();
      _avatarUrl = (data['AvatarUrl'] as String?);
      setState(() => _loadingProfile = false);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String message, {required bool success}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
        'Name': _nameCtrl.text.trim(),
        'Phone': _phoneCtrl.text.trim(),
        if (_avatarUrl != null) 'AvatarUrl': _avatarUrl,
      });
      _showSnack('Profile updated successfully.', success: true);
    } catch (e) {
      _showSnack('Update failed: $e', success: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      setState(() => _uploading = true);

      // Upload to Cloudinary
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/daxpkqhmd/image/upload');
      final req = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = '404notfound'
        ..files.add(await http.MultipartFile.fromPath('file', picked.path));

      final resp = await req.send();
      final body = await resp.stream.bytesToString();

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        _showSnack('Upload failed (${resp.statusCode}): $body', success: false);
        return;
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final secureUrl = (json['secure_url'] ?? json['url']) as String?;
      if (secureUrl == null) {
        _showSnack('Upload error: no URL returned.', success: false);
        return;
      }

      // Update Firestore immediately so không cần ấn Save
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
        'AvatarUrl': secureUrl,
      });

      setState(() {
        _avatarUrl = secureUrl;
      });

      _showSnack('Avatar updated successfully.', success: true);
    } catch (e) {
      _showSnack('Avatar upload error: $e', success: false);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      _showSnack('Signed out successfully.', success: true);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      _showSnack('Logout failed: $e', success: false);
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  // ===== Nút quay về =====
  void _goBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed('/');
    }
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (_loadingProfile)
            const Center(child: CircularProgressIndicator())
          else if (user == null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('You are not logged in.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamed('/login'),
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            )
          else
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'My Profile',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'View and update your personal information.',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Avatar — tap to change (no button)
                    Center(
                      child: GestureDetector(
                        onTap: _pickAndUploadAvatar,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 56,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage:
                                  _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                              child: _avatarUrl == null
                                  ? Icon(Icons.person,
                                      size: 56, color: Colors.grey.shade500)
                                  : null,
                            ),
                            // Small camera hint
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                                child: const Icon(Icons.camera_alt,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // E-mail (read-only)
                    TextFormField(
                      initialValue: _email,
                      readOnly: true,
                      decoration: _deco('E-mail', Icons.email_outlined).copyWith(
                        suffixIcon:
                            const Tooltip(message: 'Read-only', child: Icon(Icons.lock)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tier (read-only)
                    TextFormField(
                      initialValue: _tier.isEmpty ? '—' : _tier,
                      readOnly: true,
                      decoration: _deco('Tier', Icons.school_outlined).copyWith(
                        suffixIcon:
                            const Tooltip(message: 'Read-only', child: Icon(Icons.lock)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name (editable)
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _deco('Full Name', Icons.person_outline),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Phone (editable)
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: _deco('Phone Number', Icons.phone_outlined),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    // Save
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Change password
                    OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/change-password'),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.password),
                      label: const Text('Change Password'),
                    ),
                    const SizedBox(height: 12),

                    // Logout
                    TextButton.icon(
                      onPressed: _loggingOut ? null : _logout,
                      style: TextButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        foregroundColor: Colors.redAccent,
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                  ],
                ),
              ),
            ),

          // ===== Nút back nổi (ở trên nội dung, dưới overlay loading) =====
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ),

          // ===== Overlay loading states (uploading avatar / saving / logging out) =====
          if (_uploading || _saving || _loggingOut)
            ModalBarrier(
              dismissible: false,
              color: Colors.black.withOpacity(0.25),
            ),
          if (_uploading || _saving || _loggingOut)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _uploading
                        ? 'Uploading avatar...'
                        : _saving
                            ? 'Saving changes...'
                            : 'Signing out...',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
