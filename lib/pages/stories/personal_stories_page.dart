import 'package:aspire_edge_404_notfound/widgets/story_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PersonalStoriesPage extends StatelessWidget {
  const PersonalStoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final query = FirebaseFirestore.instance
        .collection("Stories")
        .where("userId", isEqualTo: uid)
        .orderBy("createdAt", descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text("📝 My Stories")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_story');
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
            return const Center(child: Text("You haven’t shared any stories yet"));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: snap.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return StoryCard(
                storyId: doc.id,
                mainTitle: data["mainTitle"] ?? "",
                subTitle: data["subTitle"] ?? "",
                bannerUrl: data["bannerUrl"],
                status: data["status"] ?? "pending",
                showStatus: true, // 👈 cá nhân cũng cần biết trạng thái
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
