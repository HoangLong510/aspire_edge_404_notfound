import 'package:aspire_edge_404_notfound/pages/stories/add_story_page.dart';
import 'package:aspire_edge_404_notfound/widgets/story_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class PublicStoriesPage extends StatelessWidget {
  const PublicStoriesPage({super.key});

  Future<Map<String, String>> _getAuthorInfo(String userId) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection("Users").doc(userId).get();
      final data = doc.data();
      if (data == null) return {};
      return {
        "name": data["Name"] ?? data["name"] ?? "Anonymous",
        "email": data["E-mail"] ?? data["email"] ?? "",
        "avatar": data["AvatarUrl"] ?? data["avatarUrl"] ?? "",
      };
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection("Stories")
        .where("status", isEqualTo: "approved")
        .orderBy("createdAt", descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Success Stories"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddStoryPage()),
          );
        },
        icon: const Icon(Iconsax.add),
        label: const Text("Share Your Story"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.warning_2, color: Colors.red),
                  SizedBox(width: 8),
                  Text("Failed to load stories"),
                ],
              ),
            );
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.document, color: Colors.grey),
                  SizedBox(width: 8),
                  Text("No approved stories yet"),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: snap.data!.docs.map((doc) {
              final rawData = doc.data();
              if (rawData == null) return const SizedBox.shrink();

              final data = rawData as Map<String, dynamic>;
              final userId = data["userId"] ?? "";

              return FutureBuilder<Map<String, String>>(
                future: _getAuthorInfo(userId),
                builder: (ctx, userSnap) {
                  if (userSnap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  final userData = userSnap.data ?? {};
                  return StoryCard(
                    storyId: doc.id,
                    mainTitle: data["mainTitle"] ?? "[Untitled]",
                    subTitle: data["subTitle"] ?? "",
                    bannerUrl: data["bannerUrl"] ?? "",
                    authorName: userData["name"] ?? "Anonymous",
                    authorEmail: userData["email"] ?? "",
                    authorAvatar: userData["avatar"] ?? "",
                    showStatus: false,
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
