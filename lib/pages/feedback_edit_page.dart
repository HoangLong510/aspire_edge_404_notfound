// ===================== FeedbackEditPage.dart =====================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FeedbackEditPage extends StatefulWidget {
  const FeedbackEditPage({super.key});

  @override
  State<FeedbackEditPage> createState() => _FeedbackEditPageState();
}

class _FeedbackEditPageState extends State<FeedbackEditPage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  String _email = '';
  String? _docId;
  String? _ownerUid;

  int _rating = 0;
  bool _loading = true;
  bool _saving = false;
  bool _anonymous = false; // NEW

  DateTime? _createdAt;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _fbSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['id'] is String) {
        _docId = args['id'] as String;
        _listenFeedback();
      } else {
        setState(() => _loading = false);
        _showSnack('Missing feedback ID.', success: false);
      }
    });
  }

  @override
  void dispose() {
    _fbSub?.cancel();
    _countdownTimer?.cancel();
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

  void _listenFeedback() {
    if (_docId == null) return;
    _fbSub?.cancel();
    _fbSub = FirebaseFirestore.instance
        .collection('Feedbacks')
        .doc(_docId)
        .snapshots()
        .listen(
          (snap) {
            if (!mounted) return;
            if (!snap.exists) {
              setState(() => _loading = false);
              _showSnack(
                'Feedback does not exist or was deleted.',
                success: false,
              );
              return;
            }
            final data = snap.data()!;
            _ownerUid = (data['UserId'] ?? '').toString();
            _email = (data['E-mail'] ?? '').toString();
            _nameCtrl.text = (data['Name'] ?? '').toString();
            _phoneCtrl.text = (data['Phone'] ?? '').toString();
            _contentCtrl.text = (data['Content'] ?? '').toString();
            _rating = (data['Rating'] ?? 0) as int? ?? 0;

            _anonymous = (data['IsAnonymous'] ?? false) as bool; // NEW

            final ts = data['CreatedAt'] as Timestamp?;
            _createdAt = ts?.toDate();

            _setupCountdown();
            setState(() => _loading = false);
          },
          onError: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
            _showSnack('Failed to load feedback.', success: false);
          },
        );
  }

  void _setupCountdown() {
    _countdownTimer?.cancel();
    DateTime? deadline;
    if (_createdAt != null) {
      deadline = _createdAt!.add(const Duration(hours: 24));
    }

    void tick() {
      if (!mounted) return;
      if (deadline == null) {
        setState(() => _remaining = Duration.zero);
        return;
      }
      final diff = deadline.difference(DateTime.now());
      setState(() {
        _remaining = diff.isNegative ? Duration.zero : diff;
      });
      if (diff.isNegative) _countdownTimer?.cancel();
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  String _formatRemain(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '${h.toString()}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

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

    return CircleAvatar(
      radius: 34,
      backgroundColor: color.withOpacity(.12),
      child: Text(
        _rating == 0 ? '🙂' : emoji,
        style: TextStyle(fontSize: 34, color: color),
      ),
    );
  }

  Widget _stars(bool enabled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final starIndex = i + 1;
        final selected = starIndex <= _rating;
        return IconButton(
          onPressed: (!enabled || _saving)
              ? null
              : () => setState(() => _rating = starIndex),
          icon: Icon(
            selected ? Icons.star : Icons.star_border_rounded,
            color: selected ? Colors.amber[700] : Colors.grey.shade500,
          ),
        );
      }),
    );
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
    filled: true,
    fillColor: Colors.grey.withOpacity(0.1),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  bool get _editLocked {
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = user != null && _ownerUid != null && user.uid == _ownerUid;
    final withinWindow = _remaining > Duration.zero;
    return !isOwner || !withinWindow;
  }

  Future<void> _save() async {
    if (_docId == null) return;
    if (_editLocked) {
      _showSnack('You cannot edit this feedback anymore.', success: false);
      return;
    }

    String name = _nameCtrl.text.trim();
    String phone = _phoneCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (_anonymous) {
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

    if (content.isEmpty || _rating == 0) {
      _showSnack(
        'Please write feedback and choose a star rating.',
        success: false,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('Feedbacks')
          .doc(_docId)
          .update({
            'IsAnonymous': _anonymous,
            'Name': name,
            'Phone': phone,
            'Content': content,
            'Rating': _rating,
            'Emoji': _emojiFor(_rating),
            'UpdatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      _showSnack('Feedback updated.', success: true);
      Navigator.of(context).pop();
    } catch (e) {
      _showSnack('Update failed: $e', success: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _goBack() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final locked = _editLocked;
    final identityLocked = _anonymous || locked || _saving;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
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
                        onPressed: _goBack,
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    Text(
                      'Edit Feedback',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Center(child: _emojiFace()),
                    const SizedBox(height: 8),
                    _stars(!locked),
                    const SizedBox(height: 16),

                    // Anonymous toggle
                    SwitchListTile.adaptive(
                      value: _anonymous,
                      onChanged: locked || _saving
                          ? null
                          : (v) async {
                              if (!mounted) return;
                              if (v == false) {
                                // reload profile from Users collection
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  final snap = await FirebaseFirestore.instance
                                      .collection('Users')
                                      .doc(user.uid)
                                      .get();
                                  if (snap.exists) {
                                    final data = snap.data()!;
                                    setState(() {
                                      _nameCtrl.text = (data['Name'] ?? '')
                                          .toString();
                                      _phoneCtrl.text = (data['Phone'] ?? '')
                                          .toString();
                                      _anonymous = false;
                                    });
                                    return;
                                  }
                                }
                              }
                              setState(() => _anonymous = v);
                            },
                      title: const Text('Submit anonymously'),
                      subtitle: const Text(
                        'Your name and phone will not be shown.',
                      ),
                    ),

                    const SizedBox(height: 8),
                    AbsorbPointer(
                      absorbing: identityLocked,
                      child: Opacity(
                        opacity: _anonymous ? 0.5 : 1,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameCtrl,
                              readOnly: identityLocked,
                              decoration: _deco('Full Name', Icons.person),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneCtrl,
                              readOnly: identityLocked,
                              decoration: _deco('Phone', Icons.phone),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contentCtrl,
                      readOnly: locked || _saving,
                      maxLines: 5,
                      decoration: _deco('Your Feedback', Icons.feedback),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: locked || _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_saving ? 'Saving...' : 'Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
