import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class StoryDetailPage extends StatefulWidget {
  final String storyId;
  const StoryDetailPage({super.key, required this.storyId});

  @override
  State<StoryDetailPage> createState() => _StoryDetailPageState();
}

class _StoryDetailPageState extends State<StoryDetailPage> {
  bool showComments = false;

  @override
  Widget build(BuildContext context) {
    final storyRef =
        FirebaseFirestore.instance.collection("Stories").doc(widget.storyId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Story Detail"),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: storyRef.snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text("Story not found"));
          }

          final data = snap.data!.data() as Map<String, dynamic>? ?? {};
          final bannerUrl = data["bannerUrl"] ?? "";
          final mainTitle = data["mainTitle"] ?? "[Untitled]";
          final subTitle = data["subTitle"] ?? "";
          final content = data["content"] ?? "";
          final userId = data["userId"];
          final createdAt = data["createdAt"] as Timestamp?;
          final status = data["status"] ?? "pending";

          final createdTime = createdAt != null
              ? DateFormat("dd/MM/yyyy HH:mm").format(createdAt.toDate())
              : "";

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bannerUrl.isNotEmpty)
                  Image.network(
                    bannerUrl,
                    width: double.infinity,
                    height: 230,
                    fit: BoxFit.cover,
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mainTitle,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (subTitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subTitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection("Users")
                            .doc(userId)
                            .get(),
                        builder: (ctx, userSnap) {
                          if (userSnap.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator(
                                strokeWidth: 2);
                          }
                          if (!userSnap.hasData || !userSnap.data!.exists) {
                            return const Text("Author not found");
                          }

                          final u =
                              userSnap.data!.data() as Map<String, dynamic>?;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundImage: (u?["AvatarUrl"] != null &&
                                        (u?["AvatarUrl"] as String).isNotEmpty)
                                    ? NetworkImage(u!["AvatarUrl"])
                                    : null,
                                child: (u?["AvatarUrl"] == null ||
                                        (u?["AvatarUrl"] as String).isEmpty)
                                    ? const Icon(Iconsax.user)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    u?["Name"] ?? "Unknown",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15),
                                  ),
                                  Text(
                                    u?["E-mail"] ?? "No email",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (createdTime.isNotEmpty)
                                    Text(
                                      createdTime,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      if (content.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            content,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (status == "approved") ...[
                  const Divider(),
                  _ActionBar(
                    storyRef: storyRef,
                    showComments: showComments,
                    onToggleComments: () {
                      setState(() {
                        showComments = !showComments;
                      });
                    },
                  ),
                  const Divider(),
                  if (showComments) _CommentsSection(storyRef: storyRef),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final DocumentReference storyRef;
  final bool showComments;
  final VoidCallback onToggleComments;

  const _ActionBar({
    required this.storyRef,
    required this.showComments,
    required this.onToggleComments,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: storyRef.collection("likes").doc(uid).snapshots(),
            builder: (ctx, snap) {
              final isLiked = snap.hasData && snap.data!.exists;
              return IconButton(
                icon: Icon(
                  isLiked ? Iconsax.heart5 : Iconsax.heart,
                  color: isLiked ? Colors.red : Colors.grey,
                  size: 26,
                ),
                onPressed: () async {
                  if (uid == null) return;
                  final likeDoc = storyRef.collection("likes").doc(uid);

                  if (isLiked) {
                    await likeDoc.delete();
                    await storyRef.update({
                      "likeCount": FieldValue.increment(-1),
                    });
                  } else {
                    await likeDoc.set({
                      "userId": uid,
                      "ts": FieldValue.serverTimestamp(),
                    });
                    await storyRef.update({
                      "likeCount": FieldValue.increment(1),
                    });
                  }
                },
              );
            },
          ),
          StreamBuilder<DocumentSnapshot>(
            stream: storyRef.snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData || !snap.data!.exists) {
                return const Text("0 likes");
              }
              final data = snap.data!.data() as Map<String, dynamic>? ?? {};
              final likeCount = (data["likeCount"] ?? 0) as int;
              return Text(
                "$likeCount likes",
                style: const TextStyle(fontWeight: FontWeight.w500),
              );
            },
          ),
          const SizedBox(width: 20),
          StreamBuilder<DocumentSnapshot>(
            stream: storyRef.snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData || !snap.data!.exists) {
                return const Text("View Comments (0)");
              }
              final data = snap.data!.data() as Map<String, dynamic>? ?? {};
              final commentCount = (data["commentCount"] ?? 0) as int;
              return TextButton.icon(
                onPressed: onToggleComments,
                icon: const Icon(Iconsax.message,
                    size: 22, color: Colors.grey),
                label: Text(
                  showComments
                      ? "Hide Comments ($commentCount)"
                      : "View Comments ($commentCount)",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CommentsSection extends StatefulWidget {
  final DocumentReference storyRef;
  const _CommentsSection({required this.storyRef});

  @override
  State<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  final controller = TextEditingController();
  String sortOrder = "newest";

  Future<void> _addComment() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || controller.text.trim().isEmpty) return;

    await widget.storyRef.collection("comments").add({
      "userId": uid,
      "text": controller.text.trim(),
      "createdAt": FieldValue.serverTimestamp(),
    });

    // tăng số comment
    await widget.storyRef.update({
      "commentCount": FieldValue.increment(1),
    });

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final orderByDesc = sortOrder == "newest";

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Comments",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              DropdownButton<String>(
                value: sortOrder,
                items: const [
                  DropdownMenuItem(value: "newest", child: Text("Newest first")),
                  DropdownMenuItem(value: "oldest", child: Text("Oldest first")),
                ],
                onChanged: (v) {
                  setState(() {
                    sortOrder = v ?? "newest";
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: widget.storyRef
                .collection("comments")
                .orderBy("createdAt", descending: orderByDesc)
                .snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Text("No comments yet");
              }
              return Column(
                children: snap.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final userId = data["userId"];
                  final text = data["text"] ?? "";
                  final ts = data["createdAt"] as Timestamp?;
                  final time = ts != null
                      ? DateFormat("dd/MM HH:mm").format(ts.toDate())
                      : "";

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection("Users")
                        .doc(userId)
                        .get(),
                    builder: (ctx, userSnap) {
                      if (userSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const ListTile(
                          leading: CircleAvatar(child: Icon(Iconsax.user)),
                          title: Text("Loading..."),
                        );
                      }
                      final u =
                          userSnap.data!.data() as Map<String, dynamic>?;

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundImage: (u?["AvatarUrl"] != null &&
                                  (u?["AvatarUrl"] as String).isNotEmpty)
                              ? NetworkImage(u!["AvatarUrl"])
                              : null,
                          child: (u?["AvatarUrl"] == null ||
                                  (u?["AvatarUrl"] as String).isEmpty)
                              ? const Icon(Iconsax.user)
                              : null,
                        ),
                        title: Text(
                          u?["Name"] ?? "Unknown",
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(text),
                            Text(
                              time,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Write a comment...",
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: IconButton(
                  icon: const Icon(Iconsax.send_2,
                      color: Colors.white, size: 18),
                  onPressed: _addComment,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
