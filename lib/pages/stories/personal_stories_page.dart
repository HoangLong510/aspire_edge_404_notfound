import 'package:aspire_edge_404_notfound/widgets/story_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class PersonalStoriesPage extends StatelessWidget {
  const PersonalStoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("My Stories"),
          centerTitle: true,
        ),
        body: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.warning_2, color: Colors.red),
              SizedBox(width: 8),
              Text("You must be logged in to view your stories"),
            ],
          ),
        ),
      );
    }

    final query = FirebaseFirestore.instance
        .collection("Stories")
        .where("userId", isEqualTo: uid)
        .orderBy("createdAt", descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Stories"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_story');
        },
        child: const Icon(Iconsax.add),
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
                  Text("You haven’t shared any stories yet"),
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
              return StoryCard(
                storyId: doc.id,
                mainTitle: data["mainTitle"] ?? "[Untitled]",
                subTitle: data["subTitle"] ?? "",
                bannerUrl: data["bannerUrl"] ?? "",
                status: data["status"] ?? "pending",
                showStatus: true,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
