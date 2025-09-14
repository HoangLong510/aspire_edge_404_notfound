import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'smtp_email_service.dart';

class AdminContactPage extends StatelessWidget {
  const AdminContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Inbox"),
        leading: const Icon(Iconsax.sms),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("contacts")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.danger, color: Colors.red, size: 20),
                  SizedBox(width: 6),
                  Text("Failed to load messages"),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.message_remove, color: Colors.grey, size: 20),
                  SizedBox(width: 6),
                  Text("No messages yet"),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final name = data["name"] ?? "Unknown";
              final email = data["email"] ?? "";
              final message = data["message"] ?? "";
              final createdAt = data["createdAt"]?.toDate();

              return ListTile(
                leading: const Icon(Iconsax.user, color: Colors.blueAccent),
                title: Text(name),
                subtitle: Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Iconsax.arrow_right_3, size: 18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ContactDetailPage(
                        docId: docs[i].id,
                        name: name,
                        email: email,
                        message: message,
                        createdAt: createdAt?.toString(),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ContactDetailPage extends StatefulWidget {
  final String docId;
  final String name;
  final String email;
  final String message;
  final String? createdAt;

  const ContactDetailPage({
    super.key,
    required this.docId,
    required this.name,
    required this.email,
    required this.message,
    this.createdAt,
  });

  @override
  State<ContactDetailPage> createState() => _ContactDetailPageState();
}

class _ContactDetailPageState extends State<ContactDetailPage> {
  final _replyCtrl = TextEditingController();
  bool _isSending = false;

  Future<void> _sendReply() async {
    if (_replyCtrl.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    final replyText = _replyCtrl.text.trim();

    try {
      await FirebaseFirestore.instance
          .collection("contacts")
          .doc(widget.docId)
          .collection("replies")
          .add({
        "reply": replyText,
        "createdAt": FieldValue.serverTimestamp(),
      });

      final sent = await SmtpEmailService.sendReplyEmail(
        toEmail: widget.email,
        userName: widget.name,
        replyMessage: replyText,
      );

      if (sent) {
        _showDialog(success: true, message: "Reply sent successfully!");
        _replyCtrl.clear();
      } else {
        _showDialog(success: false, message: "Failed to send reply.");
      }
    } catch (e) {
      _showDialog(success: false, message: "Error: $e");
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _showDialog({required bool success, required String message}) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              success ? Iconsax.tick_circle : Iconsax.close_circle,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(success ? "Success" : "Error"),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Message from ${widget.name}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.sms, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Text(widget.email,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Iconsax.clock, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Text(widget.createdAt ?? 'Unknown time'),
              ],
            ),
            const Divider(),
            Text(widget.message),
            const SizedBox(height: 20),
            const Text("Reply:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _replyCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: "Type your reply...",
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendReply,
                icon: const Icon(Iconsax.send_2),
                label: _isSending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Send Reply"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
