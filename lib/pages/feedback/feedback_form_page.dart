import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../home/notifications_center_page.dart';

class FeedbackFormPage extends StatefulWidget {
  const FeedbackFormPage({super.key});

  @override
  State<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends State<FeedbackFormPage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  String _email = '';
  bool _loadingProfile = true;
  bool _submitting = false;
  int _rating = 0;
  bool _anonymous = false;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  @override
  void initState() {
    super.initState();
    _prefillFromUser();
  }

  Future<void> _prefillFromUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loadingProfile = false);
      return;
    }

    _userSub = FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (snap) {
            if (!mounted) return;
            if (!snap.exists) {
              setState(() => _loadingProfile = false);
              return;
            }
            final data = snap.data()!;
            _nameCtrl.text = (data['Name'] ?? '').toString();
            _phoneCtrl.text = (data['Phone'] ?? '').toString();
            _email = (data['E-mail'] ?? '').toString();
            setState(() => _loadingProfile = false);
          },
          onError: (_) {
            if (!mounted) return;
            setState(() => _loadingProfile = false);
          },
        );
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _contentCtrl.dispose();
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

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
    filled: true,
    fillColor: Colors.grey.withOpacity(0.1),
    contentPadding: const EdgeInsets.symmetric(
      vertical: 18.0,
      horizontal: 12.0,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
    ),
  );

  IconData _iconFor(int r) {
    switch (r) {
      case 1:
        return Icons.sentiment_very_dissatisfied;
      case 2:
        return Icons.sentiment_dissatisfied;
      case 3:
        return Icons.sentiment_neutral;
      case 4:
        return Icons.sentiment_satisfied;
      case 5:
        return Icons.sentiment_very_satisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  Color _iconColorFor(int r) {
    final primary = Theme.of(context).primaryColor;
    switch (r) {
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber[700]!;
      case 4:
        return primary;
      case 5:
        return Colors.green;
      default:
        return primary;
    }
  }

  Widget _emojiFace() {
    final icon = _iconFor(_rating);
    final color = _iconColorFor(_rating);

    return CircleAvatar(
      radius: 34,
      backgroundColor: color.withOpacity(.12),
      child: Icon(icon, color: color, size: 36),
    );
  }

  Widget _stars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final starIndex = i + 1;
        final selected = starIndex <= _rating;
        return IconButton(
          onPressed: _submitting
              ? null
              : () => setState(() => _rating = starIndex),
          icon: Icon(
            selected ? Icons.star : Icons.star_border_rounded,
            color: selected ? Colors.amber[700] : Colors.grey.shade500,
            size: 30,
          ),
        );
      }),
    );
  }

  Future<String> _pickPositiveReply() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('FeedbackAutoReplies')
          .where('type', isEqualTo: 'positive')
          .where('active', isEqualTo: true)
          .limit(20)
          .get();

      final candidates = snap.docs
          .map((d) => (d.data()['message'] ?? '').toString().trim())
          .where((m) => m.isNotEmpty)
          .toList();

      if (candidates.isNotEmpty) {
        final idx = DateTime.now().millisecondsSinceEpoch % candidates.length;
        return candidates[idx];
      }
    } catch (_) {}

    return "Thank you for your feedback!";
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('You are not signed in.', success: false);
      return;
    }

    final isAnon = _anonymous;
    final content = _contentCtrl.text.trim();

    if (_rating == 0 || content.isEmpty) {
      _showSnack(
        'Please enter your feedback and choose a star rating.',
        success: false,
      );
      return;
    }

    String name = _nameCtrl.text.trim();
    String phone = _phoneCtrl.text.trim();
    String email = _email;

    if (isAnon) {
      name = 'Anonymous user';
      phone = '';
    } else {
      if (name.isEmpty || phone.isEmpty) {
        _showSnack(
          'Please fill in your name and phone number, or switch to anonymous.',
          success: false,
        );
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      Map<String, dynamic>? replyPayload;
      String status = 'pending';

      if (_rating >= 4) {
        final replyMsg = await _pickPositiveReply();
        replyPayload = {
          'message': replyMsg,
          'repliedAt': FieldValue.serverTimestamp(),
        };
        status = 'replied';

        await NotiAdminApi.sendReplyToUser(
          toUserId: user.uid,
          replyMsg: replyMsg,
          fromName: name,
        );
      }

      await FirebaseFirestore.instance.collection('Feedbacks').add({
        'UserId': user.uid,
        'IsAnonymous': isAnon,
        'E-mail': email,
        'Name': name,
        'Phone': phone,
        'Content': content,
        'Rating': _rating,
        'CreatedAt': FieldValue.serverTimestamp(),
        'Status': status,
        if (replyPayload != null) 'Reply': replyPayload,
      });

      await NotiAdminApi.sendFeedbackToAdmins(
        userId: user.uid,
        content: content,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _showSnack('Failed to submit feedback: $e', success: false);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _goBack() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final lockName = _anonymous || _submitting;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (_loadingProfile)
            const Center(child: CircularProgressIndicator())
          else
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Back',
                        onPressed: _goBack,
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    Text(
                      'Feedback',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Center(child: _emojiFace()),
                    const SizedBox(height: 8),
                    _stars(),
                    const SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      value: _anonymous,
                      onChanged: _submitting
                          ? null
                          : (v) => setState(() => _anonymous = v),
                      title: const Text('Submit anonymously'),
                      subtitle: const Text(
                        'Your name and phone number will be hidden.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_email.isNotEmpty) ...[
                      TextFormField(
                        initialValue: _email,
                        readOnly: true,
                        decoration: _deco('E-mail', Icons.email).copyWith(
                          suffixIcon: const Tooltip(
                            message: 'Read-only',
                            child: Icon(Icons.lock),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    AbsorbPointer(
                      absorbing: lockName,
                      child: Opacity(
                        opacity: lockName ? 0.5 : 1,
                        child: TextFormField(
                          controller: _nameCtrl,
                          decoration: _deco('Full Name', Icons.person),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _deco('Phone Number', Icons.phone),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentCtrl,
                      maxLines: 5,
                      decoration: _deco('Your Feedback', Icons.feedback),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        _submitting ? 'Submitting...' : 'Submit Feedback',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
