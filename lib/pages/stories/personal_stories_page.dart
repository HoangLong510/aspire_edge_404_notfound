import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

/// =======================
/// Personal Stories Page
/// =======================
class PersonalStoriesPage extends StatelessWidget {
  final bool isAdmin;
  const PersonalStoriesPage({super.key, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final query = isAdmin
        ? FirebaseFirestore.instance
            .collection("PersonalStories")
            .orderBy("createdAt", descending: true)
        : FirebaseFirestore.instance
            .collection("PersonalStories")
            .where("userId", isEqualTo: uid)
            .orderBy("createdAt", descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? "📜 List Stories" : "🌟 My Stories"),
      ),
      floatingActionButton: isAdmin
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddStoryPage()),
                );
              },
              child: const Icon(Iconsax.add),
            ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text("No stories yet"));
          }

          final docs = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final sections = (data["sections"] as List<dynamic>? ?? [])
                  .cast<Map<String, dynamic>>();

              final status = data["status"] ?? "pending";

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: (data["avatarUrl"] != null &&
                                    data["avatarUrl"].toString().isNotEmpty)
                                ? NetworkImage(data["avatarUrl"])
                                : null,
                            child: (data["avatarUrl"] == null ||
                                    data["avatarUrl"].toString().isEmpty)
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              data["name"] ?? "Unknown",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Show all sections
                      ...sections.map((sec) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((sec["title"] ?? "").toString().isNotEmpty)
                                  Text(
                                    sec["title"],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                if ((sec["text"] ?? "").toString().isNotEmpty)
                                  Text(sec["text"]),
                                if ((sec["mediaUrl"] ?? "")
                                    .toString()
                                    .isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(sec["mediaUrl"]),
                                  ),
                              ],
                            ),
                          )),

                      const Divider(),

                      // Status or Admin buttons
                      if (isAdmin)
                        _AdminActionButtons(docId: docs[i].id)
                      else
                        Text(
                          status == "approved"
                              ? "✅ Approved"
                              : status == "rejected"
                                  ? "❌ Rejected: ${data["rejectedReason"] ?? ''}"
                                  : "⏳ Pending review",
                          style: TextStyle(
                            fontSize: 13,
                            color: status == "approved"
                                ? Colors.green
                                : status == "rejected"
                                    ? Colors.red
                                    : Colors.orange,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// ======================
/// Add Story Page (User)
/// ======================
class AddStoryPage extends StatefulWidget {
  const AddStoryPage({super.key});

  @override
  State<AddStoryPage> createState() => _AddStoryPageState();
}

class _AddStoryPageState extends State<AddStoryPage> {
  List<_StorySection> sections = [_StorySection()];
  bool _isSubmitting = false;

  void _addSection() {
    setState(() {
      sections.add(_StorySection());
    });
  }

  void _removeSection(int index) {
    if (sections.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("At least 1 section is required")),
      );
      return;
    }
    setState(() {
      sections.removeAt(index);
    });
  }

  Future<void> _pickMedia(_StorySection section) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        section.localFile = File(picked.path);
        section.mediaType = "image";
      });
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "Not logged in";

      final payload = {
        "userId": user.uid,
        "name": user.displayName ?? "Anonymous",
        "avatarUrl": user.photoURL ?? "",
        "sections": sections.map((s) => s.toJson()).toList(),
        "status": "pending",
        "approved": false,
        "rejectedReason": null,
        "createdAt": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection("PersonalStories")
          .add(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Story submitted, pending approval")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("✍️ Share Your Story")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...sections.asMap().entries.map((entry) {
              final idx = entry.key;
              final section = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text("Section ${idx + 1}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeSection(idx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: section.titleCtrl,
                        decoration: const InputDecoration(
                          hintText: "Title (optional)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: section.textCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: "Write your content...",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (section.localFile != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                section.localFile!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      section.localFile = null;
                                      section.mediaType = null;
                                    });
                                  },
                                ),
                              ),
                            )
                          ],
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: () => _pickMedia(section),
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text("Add image / video"),
                        ),
                    ],
                  ),
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: _addSection,
              icon: const Icon(Icons.add),
              label: const Text("Add Section"),
            ),
            const SizedBox(height: 16),
            _isSubmitting
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.send),
                    label: const Text("Submit Story"),
                  ),
          ],
        ),
      ),
    );
  }
}

class _StorySection {
  final titleCtrl = TextEditingController();
  final textCtrl = TextEditingController();
  File? localFile;
  String? mediaType;

  Map<String, dynamic> toJson() => {
        "title": titleCtrl.text.trim(),
        "text": textCtrl.text.trim(),
        "mediaUrl": null,
        "mediaType": mediaType,
      };
}

/// ========================
/// Admin Action Buttons
/// ========================
class _AdminActionButtons extends StatelessWidget {
  final String docId;
  const _AdminActionButtons({required this.docId});

  void _approve() {
    FirebaseFirestore.instance
        .collection("PersonalStories")
        .doc(docId)
        .update({
      "approved": true,
      "status": "approved",
      "rejectedReason": null,
    });
  }

  void _reject(BuildContext context) async {
    String? reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String temp = "";
        return AlertDialog(
          title: const Text("Reject Story"),
          content: TextField(
            onChanged: (v) => temp = v,
            decoration:
                const InputDecoration(hintText: "Enter reason (optional)"),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, temp),
                child: const Text("Reject")),
          ],
        );
      },
    );
    if (reason != null) {
      FirebaseFirestore.instance
          .collection("PersonalStories")
          .doc(docId)
          .update({
        "approved": false,
        "status": "rejected",
        "rejectedReason": reason,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: _approve,
          icon: const Icon(Iconsax.tick_circle, color: Colors.green),
          label: const Text("Approve"),
        ),
        TextButton.icon(
          onPressed: () => _reject(context),
          icon: const Icon(Iconsax.close_circle, color: Colors.red),
          label: const Text("Reject"),
        ),
      ],
    );
  }
}
