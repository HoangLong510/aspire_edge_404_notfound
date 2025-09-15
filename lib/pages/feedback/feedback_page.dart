import 'dart:async';

import 'package:aspire_edge_404_notfound/pages/home/notifications_center_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

enum _Filter { all, unanswered }

class _FeedbackPageState extends State<FeedbackPage> {
  bool _loadingUser = true;
  bool _isAdmin = false;
  String? _myUid;

  _Filter _filter = _Filter.all;
  int? _ratingFilter;

  bool _hasMyFeedback = false;
  String? _myFeedbackId;

  final Map<String, TextEditingController> _replyCtrls = {};
  final Map<String, bool> _replySubmitting = {};

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _myFbSub;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserTier();
  }

  void _listenMyFeedback() {
    if (_myUid == null) {
      _myFbSub?.cancel();
      setState(() {
        _hasMyFeedback = false;
        _myFeedbackId = null;
      });
      return;
    }
    _myFbSub?.cancel();
    _myFbSub = FirebaseFirestore.instance
        .collection('Feedbacks')
        .where('UserId', isEqualTo: _myUid)
        .limit(1)
        .snapshots()
        .listen(
          (qs) {
            final has = qs.docs.isNotEmpty;
            setState(() {
              _hasMyFeedback = has;
              _myFeedbackId = has ? qs.docs.first.id : null;
            });
          },
          onError: (_) {
            setState(() {
              _hasMyFeedback = false;
              _myFeedbackId = null;
            });
          },
        );
  }

  void _loadCurrentUserTier() {
    final u = FirebaseAuth.instance.currentUser;
    _myUid = u?.uid;
    _listenMyFeedback();

    if (u == null) {
      setState(() {
        _loadingUser = false;
        _isAdmin = false;
      });
      return;
    }
    _userSub = FirebaseFirestore.instance
        .collection('Users')
        .doc(u.uid)
        .snapshots()
        .listen(
          (snap) {
            final tier = (snap.data()?['Tier'] ?? '').toString().toLowerCase();
            setState(() {
              _isAdmin = tier == 'admin';
              _loadingUser = false;
            });
          },
          onError: (_) {
            setState(() {
              _isAdmin = false;
              _loadingUser = false;
            });
          },
        );
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _myFbSub?.cancel();
    for (final c in _replyCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Query _buildQuery() {
    final col = FirebaseFirestore.instance.collection('Feedbacks');
    if (_isAdmin && _filter == _Filter.unanswered) {
      return col.where('Status', isEqualTo: 'pending');
    }
    return col.orderBy('CreatedAt', descending: true);
  }

  Future<void> _confirmDelete(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete feedback?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('Feedbacks')
          .doc(docId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Feedback deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Future<void> _sendReply(String docId) async {
    final ctrl = _replyCtrls[docId];
    if (ctrl == null) return;
    final msg = ctrl.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reply message.')),
      );
      return;
    }

    setState(() => _replySubmitting[docId] = true);
    try {
      final fbDoc = await FirebaseFirestore.instance
          .collection('Feedbacks')
          .doc(docId)
          .get();
      final toUserId = (fbDoc.data()?['UserId'] ?? '').toString();

      await FirebaseFirestore.instance
          .collection('Feedbacks')
          .doc(docId)
          .update({
            'Reply': {
              'message': msg,
              'repliedAt': FieldValue.serverTimestamp(),
            },
            'Status': 'replied',
          });
      await NotiAdminApi.sendReplyToUser(
        toUserId: toUserId,
        replyMsg: msg,
        fromName: 'Admin',
      );
      ctrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reply sent.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send reply: $e')));
      }
    } finally {
      if (mounted) setState(() => _replySubmitting[docId] = false);
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _formatDateTime(dt);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    if (_loadingUser) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary.withOpacity(.12), primary.withOpacity(.04)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(color: primary.withOpacity(.12)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.reviews_rounded, color: primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Feedback',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: primary,
                          ),
                    ),
                  ),
                  if (!_isAdmin) ...[
                    if (!_hasMyFeedback)
                      ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/feedback_form'),
                        icon: const Icon(Icons.add_comment_outlined),
                        label: const Text('Add Feedback'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _myFeedbackId == null
                            ? null
                            : () => Navigator.of(context).pushNamed(
                                '/feedback_edit',
                                arguments: {'id': _myFeedbackId},
                              ),
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('My Feedback'),
                      ),
                  ],
                ],
              ),
            ),
            if (_isAdmin)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                child: Row(
                  children: [
                    ChoiceChip(
                      selected: _filter == _Filter.all,
                      onSelected: (_) => setState(() => _filter = _Filter.all),
                      avatar: const Icon(Icons.inbox_rounded, size: 16),
                      label: const Text('All'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      selected: _filter == _Filter.unanswered,
                      onSelected: (_) =>
                          setState(() => _filter = _Filter.unanswered),
                      avatar: const Icon(
                        Icons.mark_unread_chat_alt_rounded,
                        size: 16,
                      ),
                      label: const Text('Unanswered'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildQuery().snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }

                  final allDocs = (snap.data?.docs ?? []).toList();
                  final starCounts = List<int>.filled(6, 0);
                  for (final d in allDocs) {
                    final data = d.data() as Map<String, dynamic>? ?? {};
                    final r = (data['Rating'] ?? 0) as int? ?? 0;
                    if (r >= 0 && r <= 5) starCounts[r]++;
                  }

                  List<QueryDocumentSnapshot> shownDocs = allDocs;
                  if (_ratingFilter != null) {
                    final target = _ratingFilter!;
                    shownDocs = shownDocs.where((d) {
                      final data = d.data() as Map<String, dynamic>? ?? {};
                      final r = (data['Rating'] ?? 0) as int? ?? 0;
                      return r == target;
                    }).toList();
                  }

                  shownDocs.sort((a, b) {
                    final ad = a.data() as Map<String, dynamic>? ?? {};
                    final bd = b.data() as Map<String, dynamic>? ?? {};
                    final at =
                        (ad['CreatedAt'] as Timestamp?)?.toDate() ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    final bt =
                        (bd['CreatedAt'] as Timestamp?)?.toDate() ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    return bt.compareTo(at);
                  });

                  if (allDocs.isEmpty) {
                    return const Center(child: Text('No feedback yet.'));
                  }

                  Widget ratingFilterBar = Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list_rounded, size: 18),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          selected: _ratingFilter == null,
                          label: const Text('All ratings'),
                          onSelected: (_) =>
                              setState(() => _ratingFilter = null),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(5, (idx) {
                                final star = 5 - idx;
                                final count = starCounts[star];
                                final selected = _ratingFilter == star;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    left: idx == 0 ? 0 : 6,
                                  ),
                                  child: ChoiceChip(
                                    selected: selected,
                                    onSelected: (_) => setState(() {
                                      _ratingFilter = selected ? null : star;
                                    }),
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star, size: 14),
                                        const SizedBox(width: 2),
                                        Text('$star'),
                                        const SizedBox(width: 6),
                                        Text(
                                          '($count)',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  return Column(
                    children: [
                      ratingFilterBar,
                      if (_ratingFilter != null && shownDocs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16),
                              const SizedBox(width: 6),
                              Text('No feedback with ${_ratingFilter}★ yet.'),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: shownDocs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final d = shownDocs[i];
                            final id = d.id;
                            final data =
                                d.data() as Map<String, dynamic>? ?? {};

                            final userId = (data['UserId'] ?? '').toString();
                            final name = (data['Name'] ?? 'Anonymous')
                                .toString();
                            final email = (data['E-mail'] ?? '').toString();
                            final phone = (data['Phone'] ?? '').toString();
                            final rating = (data['Rating'] ?? 0) as int? ?? 0;
                            final content = (data['Content'] ?? '').toString();

                            final createdAtTs = data['CreatedAt'] as Timestamp?;
                            final createdAt = createdAtTs != null
                                ? createdAtTs.toDate()
                                : null;

                            final reply =
                                data['Reply'] as Map<String, dynamic>?;
                            final replyMsg = (reply?['message'] ?? '')
                                .toString();
                            final repliedAtTs =
                                reply?['repliedAt'] as Timestamp?;
                            final repliedAt = repliedAtTs != null
                                ? repliedAtTs.toDate()
                                : null;

                            _replyCtrls.putIfAbsent(
                              id,
                              () => TextEditingController(),
                            );
                            final sending = _replySubmitting[id] ?? false;

                            final isMine =
                                userId.isNotEmpty && userId == _myUid;

                            return Card(
                              elevation: isMine ? 2.5 : 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: isMine
                                    ? BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(.45),
                                        width: 1.4,
                                      )
                                    : BorderSide(
                                        color: Colors.grey.withOpacity(.20),
                                      ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  14,
                                  14,
                                  12,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _UserAvatar(
                                          userId: userId,
                                          fallbackName: name,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Wrap(
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                spacing: 8,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  if (isMine)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .primaryColor
                                                            .withOpacity(.12),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              999,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'Yours',
                                                        style: TextStyle(
                                                          color: Theme.of(
                                                            context,
                                                          ).primaryColor,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 11.5,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Text(
                                                    _timeAgo(createdAt),
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12.5,
                                                    ),
                                                  ),
                                                  if (createdAt != null) ...[
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      '• ${_formatDateTime(createdAt)}',
                                                      style: TextStyle(
                                                        color: Colors.grey[500],
                                                        fontSize: 11.5,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              if (_isAdmin) ...[
                                                const SizedBox(height: 8),
                                                if (email.isNotEmpty)
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.email_outlined,
                                                        size: 14,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          email,
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[800],
                                                            fontSize: 12.5,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                if (phone.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.phone_outlined,
                                                        size: 14,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          phone,
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[800],
                                                            fontSize: 12.5,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            if (_isAdmin)
                                              IconButton(
                                                tooltip: 'Delete',
                                                onPressed: () =>
                                                    _confirmDelete(id),
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        ...List.generate(5, (idx) {
                                          final filled = idx < rating;
                                          return Icon(
                                            filled
                                                ? Icons.star
                                                : Icons.star_border_rounded,
                                            size: 18,
                                            color: filled
                                                ? Colors.amber[700]
                                                : Colors.grey[500],
                                          );
                                        }),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blueGrey.withOpacity(
                                              .08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '$rating / 5',
                                            style: TextStyle(
                                              color: Colors.blueGrey.shade700,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(.06),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.withOpacity(.18),
                                        ),
                                      ),
                                      child: Text(
                                        content,
                                        style: const TextStyle(height: 1.35),
                                      ),
                                    ),
                                    if (replyMsg.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Colors.green
                                                .withOpacity(.15),
                                            child: const Icon(
                                              Icons
                                                  .admin_panel_settings_rounded,
                                              color: Colors.green,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(
                                                  .06,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.green
                                                      .withOpacity(.2),
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Reply',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color:
                                                          Colors.green.shade800,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    replyMsg,
                                                    style: const TextStyle(
                                                      height: 1.35,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    _formatDateTime(repliedAt),
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (_isAdmin && replyMsg.isEmpty) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _replyCtrls[id],
                                              enabled: !sending,
                                              decoration: InputDecoration(
                                                hintText: 'Write a reply...',
                                                isDense: true,
                                                filled: true,
                                                fillColor: Colors.grey
                                                    .withOpacity(.08),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide.none,
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 12,
                                                    ),
                                              ),
                                              minLines: 1,
                                              maxLines: 5,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          sending
                                              ? const Padding(
                                                  padding: EdgeInsets.only(
                                                    top: 8,
                                                  ),
                                                  child: SizedBox(
                                                    width: 26,
                                                    height: 26,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                )
                                              : IconButton.filled(
                                                  onPressed: () =>
                                                      _sendReply(id),
                                                  icon: const Icon(
                                                    Icons.send_rounded,
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.userId, required this.fallbackName});

  final String userId;
  final String fallbackName;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty && parts.first.isNotEmpty
        ? parts.first[0]
        : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    final s = (first + last).toUpperCase();
    return s.isEmpty ? 'U' : s;
  }

  @override
  Widget build(BuildContext context) {
    if (fallbackName.trim().toLowerCase() == 'anonymous user') {
      return CircleAvatar(
        radius: 22,
        backgroundColor: Colors.grey.shade300,
        child: const Icon(Icons.person_off_rounded, color: Colors.black54),
      );
    }
    if (userId.isEmpty) {
      return CircleAvatar(radius: 22, child: Text(_initials(fallbackName)));
    }
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('Users').doc(userId).get(),
      builder: (context, snap) {
        String? avatarUrl;
        if (snap.hasData && snap.data!.exists) {
          avatarUrl = (snap.data!.data()?['AvatarUrl'] as String?);
        }
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          return CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage(avatarUrl),
          );
        }
        return CircleAvatar(
          radius: 22,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(.1),
          child: Text(
            _initials(fallbackName),
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      },
    );
  }
}
