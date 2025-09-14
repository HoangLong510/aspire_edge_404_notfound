import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class LocalNoti {
  static final _fln = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _fln.initialize(init);
  }

  static Future<void> show(String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'notify_channel',
        'Notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _fln.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}

class NotificationsListener extends StatefulWidget {
  final String uid;
  final Widget child;

  const NotificationsListener({
    super.key,
    required this.uid,
    required this.child,
  });

  @override
  State<NotificationsListener> createState() => _NotificationsListenerState();
}

class _NotificationsListenerState extends State<NotificationsListener> {
  StreamSubscription<QuerySnapshot>? _sub;
  final Set<String> _shownIds = {};

  @override
  void initState() {
    super.initState();
    _sub = FirebaseFirestore.instance
        .collection('Notifications')
        .doc(widget.uid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
          for (final c in snap.docChanges) {
            if (c.type == DocumentChangeType.added) {
              final id = c.doc.id;
              final m = c.doc.data() as Map<String, dynamic>? ?? {};
              final title = (m['title'] ?? 'Thông báo').toString();
              final body = (m['body'] ?? '').toString();
              final read = m['read'] == true;

              if (!read && !_shownIds.contains(id)) {
                _shownIds.add(id);
                LocalNoti.show(title, body);
              }
              print("Listen change id=$id, read=$read");
            }
          }
        });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class NotificationBell extends StatelessWidget {
  final String uid;

  const NotificationBell({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('Notifications')
        .doc(uid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: q,
      builder: (ctx, snap) {
        int unread = 0;
        if (snap.hasData) {
          for (final d in snap.data!.docs) {
            final read = d['read'] == true;
            if (!read) unread++;
          }
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notifications',
              icon: Icon(
                unread > 0 ? Icons.notifications : Icons.notifications_none,
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NotificationsInboxPage(uid: uid),
                  ),
                );
              },
            ),
            if (unread > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class NotificationsInboxPage extends StatefulWidget {
  final String uid;

  const NotificationsInboxPage({super.key, required this.uid});

  @override
  State<NotificationsInboxPage> createState() => _NotificationsInboxPageState();
}

class _NotificationsInboxPageState extends State<NotificationsInboxPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);

    _tabCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('Notifications')
        .doc(widget.uid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();

    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: primary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Unread"),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: q,
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_rounded,
                    color: Colors.grey[400],
                    size: 72,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          if (_tabCtrl.index == 1) {
            docs = docs.where((d) => d['read'] != true).toList();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (ctx, i) {
              final d = docs[i];
              final m = d.data() as Map<String, dynamic>? ?? {};

              final notifId = d.id;
              final title = (m['title'] ?? 'Notification').toString();
              final body = (m['body'] ?? '').toString();
              final type = (m['type'] ?? '').toString();
              final careerId = (m['careerId'] ?? '').toString();
              final blogId = (m['blogId'] ?? '').toString();
              final t = (m['createdAt'] as Timestamp?)?.toDate();
              final read = m['read'] == true;

              IconData icon;
              Color iconColor;
              switch (type) {
                case 'blog':
                  icon = Icons.article_rounded;
                  iconColor = Colors.blueAccent;
                  break;
                case 'career_update':
                  icon = Icons.work_history_rounded;
                  iconColor = Colors.deepPurple;
                  break;
                case 'edit_career':
                  icon = Icons.edit_note_rounded;
                  iconColor = Colors.orange;
                  break;
                case 'feedback':
                  icon = Icons.feedback_rounded;
                  iconColor = Colors.teal;
                  break;
                case 'reply':
                  icon = Icons.mark_chat_read_rounded;
                  iconColor = Colors.green;
                  break;
                default:
                  icon = Icons.notifications_active_rounded;
                  iconColor = primary;
              }

              String formatDdMmHhMm(DateTime d) {
                String two(int n) => n.toString().padLeft(2, '0');
                return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
              }

              final timeStr = t != null ? formatDdMmHhMm(t.toLocal()) : '';

              return Slidable(
                key: ValueKey(notifId),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.25,
                  children: [
                    SlidableAction(
                      onPressed: (_) async {
                        await FirebaseFirestore.instance
                            .collection('Notifications')
                            .doc(widget.uid)
                            .collection('items')
                            .doc(notifId)
                            .delete();
                      },
                      icon: Icons.delete,
                      label: 'Delete',
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () async {
                    await FirebaseFirestore.instance
                        .collection('Notifications')
                        .doc(widget.uid)
                        .collection('items')
                        .doc(notifId)
                        .update({'read': true});

                    _handleTap(context, type, careerId, blogId);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: read ? Colors.white : primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: iconColor.withOpacity(0.12),
                          child: Icon(icon, color: iconColor, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.5,
                                  color: read ? Colors.black87 : primary,
                                ),
                              ),
                              if (body.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: Colors.grey[800],
                                    height: 1.35,
                                  ),
                                ),
                              ],
                              if (timeStr.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!read)
                          Container(
                            margin: const EdgeInsets.only(left: 8, top: 6),
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleTap(
    BuildContext context,
    String type,
    String careerId,
    String blogId,
  ) {
    if (type == 'edit_career' && careerId.isNotEmpty) {
      Navigator.pushNamed(context, '/edit_career', arguments: careerId);
    } else if (type == 'career_update' && careerId.isNotEmpty) {
      Navigator.pushNamed(context, '/career_detail', arguments: careerId);
    } else if (type == 'blog' && blogId.isNotEmpty) {
      Navigator.pushNamed(context, '/blog_detail', arguments: blogId);
    } else if (type == 'feedback' || type == 'reply') {
      Navigator.pushNamed(context, '/feedback');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No action available for this notification"),
        ),
      );
    }
  }
}

class NotiAdminApi {
  static Future<void> sendCareerUpdateToFavoriters({
    required String adminUid,
    required String careerId,
    required String careerTitle,
    String fromName = 'Admin',
  }) async {
    await _addCareerActivity(
      careerId: careerId,
      type: 'Career_Update',
      title: 'Update Career',
      body: '$careerTitle has been Added/Updated',
    );

    await _fanout(
      careerId: careerId,
      notiTitle: 'Update Career',
      notiBody: '$careerTitle just Updated',
      type: 'career_update',
      adminUid: adminUid,
      fromName: fromName,
    );
  }

  static Future<void> sendFeedbackToAdmins({
    required String userId,
    required String content,
  }) async {
    final fs = FirebaseFirestore.instance;

    final q = await fs
        .collection('Users')
        .where('Tier', isEqualTo: 'admin')
        .get();

    if (q.docs.isEmpty) return;

    final batch = fs.batch();
    for (final u in q.docs) {
      final adminUid = u.id;
      final ref = fs
          .collection('Notifications')
          .doc(adminUid)
          .collection('items')
          .doc();

      batch.set(ref, {
        'title': 'New Feedback',
        'body': content.length > 50
            ? '${content.substring(0, 50)}...'
            : content,
        'type': 'feedback',
        'fromUserId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    }

    await batch.commit();
  }

  static Future<void> sendReplyToUser({
    required String toUserId,
    required String replyMsg,
    String fromName = 'Admin',
  }) async {
    final fs = FirebaseFirestore.instance;
    final ref = fs
        .collection('Notifications')
        .doc(toUserId)
        .collection('items')
        .doc();

    await ref.set({
      'title': 'Respond to feedback',
      'body': replyMsg,
      'type': 'reply',
      'fromName': fromName,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  static Future<void> sendBlogToFavoriters({
    required String adminUid,
    required String careerId,
    required String blogTitle,
    String fromName = 'Admin',
    String? blogId,
  }) async {
    await _addCareerActivity(
      careerId: careerId,
      type: 'blog',
      title: 'New Blog',
      body: blogTitle,
    );

    await _fanout(
      careerId: careerId,
      notiTitle: 'New Blog',
      notiBody: blogTitle,
      type: 'blog',
      adminUid: adminUid,
      fromName: fromName,
      extraData: blogId == null ? null : {'blogId': blogId},
    );
  }

  static Future<void> _addCareerActivity({
    required String careerId,
    required String type,
    required String title,
    required String body,
  }) async {
    await FirebaseFirestore.instance.collection('CareerActivity').add({
      'careerId': careerId,
      'type': type,
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> _fanout({
    required String careerId,
    required String notiTitle,
    required String notiBody,
    required String type,
    required String adminUid,
    required String fromName,
    Map<String, String>? extraData,
  }) async {
    final fs = FirebaseFirestore.instance;
    final q = await fs
        .collection('Users')
        .where('favorites', arrayContains: careerId)
        .get();

    if (q.docs.isEmpty) return;

    final batch = fs.batch();
    for (final u in q.docs) {
      final toUid = u.id;
      final ref = fs
          .collection('Notifications')
          .doc(toUid)
          .collection('items')
          .doc();
      batch.set(ref, {
        'title': notiTitle,
        'body': notiBody,
        'type': type,
        'careerId': careerId,
        'fromUserId': adminUid,

        'fromName': fromName,
        'toUserId': toUid,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        if (extraData != null) ...extraData,
      });
      print("Creating noti for $toUid: read=false");
    }
    await batch.commit();
  }
}
