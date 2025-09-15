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

  String? _docId;
  String? _ownerUid;

  int _rating = 0;
  bool _loading = true;
  bool _saving = false;
  bool _anonymous = false;

  DateTime? _createdAt;
  DateTime? _expiryAt;
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
            _nameCtrl.text = (data['Name'] ?? '').toString();
            _phoneCtrl.text = (data['Phone'] ?? '').toString();
            _contentCtrl.text = (data['Content'] ?? '').toString();
            _rating = (data['Rating'] ?? 0) is int
                ? (data['Rating'] as int)
                : 0;
            _anonymous = (data['IsAnonymous'] ?? false) as bool? ?? false;

            final ts = data['CreatedAt'];
            _createdAt = (ts is Timestamp) ? ts.toDate() : null;
            _expiryAt = _createdAt?.add(const Duration(hours: 24));

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

    void tick() {
      if (!mounted) return;
      if (_expiryAt == null) {
        setState(() => _remaining = Duration.zero);
        return;
      }
      final diff = _expiryAt!.difference(DateTime.now());
      setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
      if (diff.isNegative) _countdownTimer?.cancel();
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  String _fmtHms(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return '${h.toString()}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString()}:${s.toString().padLeft(2, '0')}';
  }

  String _countdownMessage() {
    if (_expiryAt == null) {
      return 'Missing creation time. Editing is locked.';
    }
    if (_remaining <= Duration.zero) {
      return 'You have run out of time to edit your feedback.';
    }
    final hasHours = _remaining.inHours > 0;
    final timeText = _fmtHms(_remaining);
    final unit = hasHours ? 'hours' : 'minutes';
    return '$timeText $unit left to edit your feedback.';
  }

  Color _badgeColor() {
    if (_expiryAt == null) return Colors.grey;
    if (_remaining <= Duration.zero) return Colors.redAccent;
    return Colors.teal;
  }

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
        return Colors.amber;
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
      child: Icon(icon, size: 34, color: color),
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

  bool get _isOwner {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && _ownerUid != null && user.uid == _ownerUid;
  }

  bool get _withinWindow {
    if (_expiryAt == null) return false;
    return _remaining > Duration.zero;
  }

  bool get _editLocked => !_isOwner || !_withinWindow;

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
            'Emoji': _rating.toString(),
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

  Widget _countdownBadge() {
    final color = _badgeColor();
    final icon = _expiryAt == null
        ? Icons.lock_clock
        : (_remaining <= Duration.zero ? Icons.lock : Icons.timer);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              _countdownMessage(),
              softWrap: true,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
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
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Text(
                              'Edit Feedback',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                            ),
                          ),
                          _countdownBadge(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(child: _emojiFace()),
                    const SizedBox(height: 8),
                    _stars(!locked),
                    const SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      value: _anonymous,
                      onChanged: locked || _saving
                          ? null
                          : (v) async {
                              if (!mounted) return;
                              if (v == false) {
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
                              decoration: _deco('Full name', Icons.person),
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
                      decoration: _deco('Your feedback', Icons.feedback),
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
                      label: Text(_saving ? 'Saving...' : 'Save changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
