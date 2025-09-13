import 'package:aspire_edge_404_notfound/pages/stories/add_story_page.dart';
import 'package:aspire_edge_404_notfound/widgets/story_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PublicStoriesPage extends StatelessWidget {
  const PublicStoriesPage({super.key});

  Future<Map<String, String>> _getAuthorInfo(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(userId)
          .get();
      final data = doc.data();
      if (data == null) return {};

      return {
        "name": data["Name"] ?? "Anonymous",              // 👈 chú ý chữ N
        "email": data["E-mail"] ?? "",                    // 👈 chú ý chữ E
        "avatar": data["AvatarUrl"] ?? "",                // 👈 chú ý chữ A
      };
    } catch (e) {
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
        title: const Text("🌟 Success Stories"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddStoryPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Share Your Story"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text("❌ Error: ${snap.error}"));
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text("No approved stories yet"));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: snap.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final userId = data["userId"] ?? "";

              return FutureBuilder<Map<String, String>>(
                future: _getAuthorInfo(userId),
                builder: (ctx, userSnap) {
                  final userData = userSnap.data ?? {};
                  return StoryCard(
                    storyId: doc.id,
                    mainTitle: data["mainTitle"] ?? "",
                    subTitle: data["subTitle"] ?? "",
                    bannerUrl: data["bannerUrl"],
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
