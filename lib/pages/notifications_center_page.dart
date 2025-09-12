import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ===============================================================
///  LocalNoti: init & show local notifications (foreground only)
/// ===============================================================
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
        'notify_channel', 'Notifications',
        importance: Importance.max, priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _fln.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title, body, details,
    );
  }
}

/// ===================================================================================
///  NotificationsListener: wrap widget tree & listen Notifications/{uid}/items
///  → hiện local noti khi có doc mới, đồng thời không đụng tới UI của bạn.
/// ===================================================================================
class NotificationsListener extends StatefulWidget {
  final String uid;
  final Widget child;
  const NotificationsListener({super.key, required this.uid, required this.child});

  @override
  State<NotificationsListener> createState() => _NotificationsListenerState();
}

class _NotificationsListenerState extends State<NotificationsListener> {
  StreamSubscription<QuerySnapshot>? _sub;

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
          final m = c.doc.data() as Map<String, dynamic>? ?? {};
          final title = (m['title'] ?? 'Thông báo').toString();
          final body  = (m['body']  ?? '').toString();
          LocalNoti.show(title, body);
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

/// =======================================================================
///  NotificationBell: icon chuông + badge số lượng chưa đọc (unread)
///  - Bấm vào mở NotificationsInboxPage và mark all read.
/// =======================================================================
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
              tooltip: 'Thông báo',
              icon: Icon(unread > 0 ? Icons.notifications : Icons.notifications_none),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NotificationsInboxPage(uid: uid)),
                );
                // mark all read sau khi đóng inbox
                await _markAllRead(uid);
              },
            ),
            if (unread > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static Future<void> _markAllRead(String uid) async {
    final fs = FirebaseFirestore.instance;
    final q = await fs
        .collection('Notifications')
        .doc(uid)
        .collection('items')
        .where('read', isEqualTo: false)
        .limit(500)
        .get();

    final batch = fs.batch();
    for (final d in q.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }
}

/// =======================================================================
///  NotificationsInboxPage: danh sách thông báo của user (realtime)
/// =======================================================================
class NotificationsInboxPage extends StatelessWidget {
  final String uid;
  const NotificationsInboxPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('Notifications')
        .doc(uid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: StreamBuilder<QuerySnapshot>(
        stream: q,
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Chưa có thông báo'));

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final d = docs[i];
              final m = d.data() as Map<String, dynamic>? ?? {};
              final title = (m['title'] ?? 'Thông báo').toString();
              final body  = (m['body'] ?? '').toString();
              final type  = (m['type'] ?? '').toString();
              final from  = (m['fromName'] ?? m['fromUserId'] ?? '').toString();
              final careerId = (m['careerId'] ?? '').toString();
              final t = (m['createdAt'] as Timestamp?)?.toDate();
              final read = m['read'] == true;

              return ListTile(
                leading: Icon(type == 'blog' ? Icons.article : Icons.update),
                title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  [
                    if (body.isNotEmpty) body,
                    if (careerId.isNotEmpty) 'career: $careerId',
                    if (from.isNotEmpty) 'from: $from',
                    if (t != null) t.toLocal().toString(),
                  ].where((e) => e.isNotEmpty).join(' · '),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
                trailing: read
                    ? const SizedBox.shrink()
                    : const Icon(Icons.brightness_1, size: 10, color: Colors.red),
                onTap: () {
                  // TODO: điều hướng theo type/careerId/blogId nếu muốn
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// =====================================================================
///  NotiAdminApi: HÀM GỬI THÔNG BÁO THEO NGHỀ YÊU THÍCH (FAN-OUT, NO SERVER)
///  - Lưu lịch sử noti vào Notifications/{uid}/items/{notifId}
///  - Tùy biến field sender/receiver/type/careerId…
/// =====================================================================
class NotiAdminApi {
  /// Gọi sau khi ADMIN lưu/cập nhật nghề (CareerBank/{careerId})
  static Future<void> sendCareerUpdateToFavoriters({
    required String adminUid,
    required String careerId,
    required String careerTitle,
    String fromName = 'Admin',
  }) async {
    // 1) (tuỳ chọn) ghi activity chung (nếu bạn muốn một bảng lịch sử hệ thống)
    await _addCareerActivity(
      careerId: careerId,
      type: 'career_update',
      title: 'Cập nhật nghề',
      body: '$careerTitle đã được thêm/cập nhật',
    );

    // 2) Fan-out vào Notifications của từng user có favorites chứa careerId
    await _fanout(
      careerId: careerId,
      notiTitle: 'Cập nhật nghề',
      notiBody: '$careerTitle vừa được cập nhật',
      type: 'career_update',
      adminUid: adminUid,
      fromName: fromName,
    );
  }

  /// Gọi sau khi ADMIN tạo blog liên quan
  static Future<void> sendBlogToFavoriters({
    required String adminUid,
    required String careerId,
    required String blogTitle,
    String fromName = 'Admin',
    String? blogId,
  }) async {
    // 1) (tuỳ chọn) activity
    await _addCareerActivity(
      careerId: careerId,
      type: 'blog',
      title: 'Blog mới',
      body: blogTitle,
    );

    // 2) Fan-out
    await _fanout(
      careerId: careerId,
      notiTitle: 'Blog mới',
      notiBody: blogTitle,
      type: 'blog',
      adminUid: adminUid,
      fromName: fromName,
      extraData: blogId == null ? null : {'blogId': blogId},
    );
  }

  /// ================== Helpers ==================
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
    // Tìm tất cả user đã yêu thích careerId
    final q = await fs.collection('Users')
        .where('favorites', arrayContains: careerId)
        .get();

    if (q.docs.isEmpty) return;

    final batch = fs.batch();
    for (final u in q.docs) {
      final toUid = u.id;
      final ref = fs.collection('Notifications').doc(toUid).collection('items').doc();
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
    }
    await batch.commit();
  }
}
