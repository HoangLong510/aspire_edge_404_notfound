import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
        .listen((snap) {
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
    }, onError: (_) {
      if (!mounted) return;
      setState(() => _loadingProfile = false);
    });
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

  String _emojiFor(int r) {
    switch (r) {
      case 1:
        return '😡';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '🤩';
      default:
        return '🙂';
    }
  }

  Color _emojiColorFor(int r) {
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
    final emoji = _emojiFor(_rating);
    final color = _emojiColorFor(_rating);

    return TweenAnimationBuilder<double>(
      key: ValueKey(_rating),
      tween: Tween(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return AnimatedRotation(
          turns: _rating == 0 ? 0 : 0.01 * (_rating - 3),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: Transform.scale(
            scale: scale,
            child: CircleAvatar(
              radius: 34,
              backgroundColor: color.withOpacity(.12),
              child: Text(
                _rating == 0 ? '🙂' : emoji,
                style: TextStyle(fontSize: 34, color: color),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final starIndex = i + 1;
        final selected = starIndex <= _rating;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.5),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: selected ? 1.15 : 1.0),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: IconButton(
                  onPressed: _submitting
                      ? null
                      : () => setState(() => _rating = starIndex),
                  icon: Icon(
                    selected ? Icons.star : Icons.star_border_rounded,
                    color: selected ? Colors.amber[700] : Colors.grey.shade500,
                    size: 30,
                  ),
                ),
              );
            },
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

    final fallbacks = <String>[
      "Thank you for using our website!",
      "Thanks for your positive rating!",
      "We truly appreciate your feedback!",
      "Your support means a lot to us!",
      "We’re glad you had a great experience!",
      "Thanks for taking the time to review us!",
      "Your feedback helps us improve!",
      "We’re thrilled to hear your thoughts!",
      "Thanks for choosing our service!",
      "You made our day—thank you!"
    ];
    return fallbacks[DateTime.now().millisecondsSinceEpoch % fallbacks.length];
    }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('You are not signed in.', success: false);
      return;
    }
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty || content.isEmpty || _rating == 0) {
      _showSnack('Please fill in all fields and choose a star rating.', success: false);
      return;
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
      }

      await FirebaseFirestore.instance.collection('Feedbacks').add({
        'UserId': user.uid,
        'E-mail': _email,
        'Name': name,
        'Phone': phone,
        'Content': content,
        'Rating': _rating,
        'Emoji': _emojiFor(_rating),
        'CreatedAt': FieldValue.serverTimestamp(),
        'Status': status,
        if (replyPayload != null) 'Reply': replyPayload,
      });

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _showSnack('Failed to submit feedback: $e', success: false);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _goBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (_loadingProfile)
            const Center(child: CircularProgressIndicator())
          else
            SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Back',
                        onPressed: _goBack,
                        icon: Icon(Icons.arrow_back_rounded,
                            color: Theme.of(context).primaryColor),
                      ),
                    ),
                    Text(
                      'Feedback',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share your experience to help us improve.',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Center(child: _emojiFace()),
                    const SizedBox(height: 8),
                    _stars(),
                    const SizedBox(height: 8),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _rating == 0 ? 0.7 : 1.0,
                      child: Text(
                        _rating == 0
                            ? 'Please choose your rating'
                            : (_rating <= 2
                                ? 'Sorry to hear that'
                                : _rating == 3
                                    ? 'Okay — we can still improve'
                                    : _rating == 4
                                        ? 'Great! Thank you'
                                        : 'Amazing! You made our day 🤩'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_email.isNotEmpty) ...[
                      TextFormField(
                        initialValue: _email,
                        readOnly: true,
                        decoration:
                            _deco('E-mail', Icons.email_outlined).copyWith(
                          suffixIcon: const Tooltip(
                            message: 'Read-only',
                            child: Icon(Icons.lock),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _deco('Full Name', Icons.person_outline),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _deco('Phone Number', Icons.phone_outlined),
                      textInputAction: TextInputAction.next,
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _submitting ? 'Submitting...' : 'Submit Feedback',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_submitting)
            ModalBarrier(
              dismissible: false,
              color: Colors.black.withOpacity(0.2),
            ),
        ],
      ),
    );
  }
}
