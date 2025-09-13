import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// =======================
/// Personal Stories Page
/// =======================
class PersonalStoriesPage extends StatefulWidget {
  final bool isAdmin;
  final String? filterUserId;
  const PersonalStoriesPage({
    super.key,
    this.isAdmin = false,
    this.filterUserId,
  });

  @override
  State<PersonalStoriesPage> createState() => _PersonalStoriesPageState();
}

class _PersonalStoriesPageState extends State<PersonalStoriesPage> {
  String? _statusFilter; // null = all

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    print("DEBUG => Current Firebase UID: $uid");

    Query query = FirebaseFirestore.instance.collection("Stories");

    if (widget.isAdmin) {
      if (widget.filterUserId != null) {
        query = query.where("userId", isEqualTo: widget.filterUserId);
      }
    } else {
      query = query.where("userId", isEqualTo: uid);
    }

    if (_statusFilter != null) {
      query = query.where("status", isEqualTo: _statusFilter);
    }

    query = query.orderBy("createdAt", descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? "All Stories" : "My Stories"),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _statusFilter = value;
              });
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: null, child: Text("All")),
              PopupMenuItem(value: "pending", child: Text("Pending")),
              PopupMenuItem(value: "approved", child: Text("Approved")),
              PopupMenuItem(value: "rejected", child: Text("Rejected")),
            ],
          ),
        ],
      ),
      floatingActionButton: widget.isAdmin
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddStoryPage()),
                );
              },
              child: const Icon(Icons.add),
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
                      // Show all sections
                      ...sections.map(
                        (sec) => Padding(
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
                              if ((sec["mediaUrl"] ?? "").toString().isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(sec["mediaUrl"]),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const Divider(),

                      // Status or Admin buttons
                      widget.isAdmin
                          ? _AdminActionButtons(docId: docs[i].id)
                          : Text(
                              status == "approved"
                                  ? "✅ Approved"
                                  : status == "rejected"
                                  ? "❌ Rejected"
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

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "Not logged in";

      final payload = {
        "userId": user.uid,
        "sections": sections.map((s) => s.toJson()).toList(),
        "status": "pending",
        "createdAt": DateTime.now(),
      };

      await FirebaseFirestore.instance.collection("Stories").add(payload);

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Success"),
          content: const Text("✅ Story submitted, pending approval"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("OK"),
            ),
          ],
        ),
      );

      // Quay lại trang list
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Error"),
          content: Text("❌ Error: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
                    children: [
                      Row(
                        children: [
                          Text(
                            "Section ${idx + 1}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
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

  Map<String, dynamic> toJson() => {
    "title": titleCtrl.text.trim(),
    "text": textCtrl.text.trim(),
    "mediaUrl": null,
    "mediaType": "text",
  };
}

/// ========================
/// Admin Action Buttons
/// ========================
class _AdminActionButtons extends StatelessWidget {
  final String docId;
  const _AdminActionButtons({required this.docId});

  void _approve() {
    FirebaseFirestore.instance.collection("Stories").doc(docId).update({
      "status": "approved",
    });
  }

  void _reject(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Story"),
        content: const Text("Are you sure you want to reject this story?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Reject"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      FirebaseFirestore.instance.collection("Stories").doc(docId).update({
        "status": "rejected",
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: _approve,
          icon: const Icon(Icons.check_circle, color: Colors.green),
          label: const Text("Approve"),
        ),
        TextButton.icon(
          onPressed: () => _reject(context),
          icon: const Icon(Icons.cancel, color: Colors.red),
          label: const Text("Reject"),
        ),
      ],
    );
  }
}
