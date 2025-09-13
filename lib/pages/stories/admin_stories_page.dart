import 'package:aspire_edge_404_notfound/widgets/admin_action_buttons.dart';
import 'package:aspire_edge_404_notfound/widgets/story_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminStoriesPage extends StatefulWidget {
  const AdminStoriesPage({super.key});

  @override
  State<AdminStoriesPage> createState() => _AdminStoriesPageState();
}

class _AdminStoriesPageState extends State<AdminStoriesPage> {
  String? _statusFilter; // null = all

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection("Stories")
        .orderBy("createdAt", descending: true);

    if (_statusFilter != null) {
      query = query.where("status", isEqualTo: _statusFilter);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("📋 All Stories"),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _statusFilter = value);
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: null, child: Text("All")),
              PopupMenuItem(value: "pending", child: Text("Pending")),
              PopupMenuItem(value: "approved", child: Text("Approved")),
              PopupMenuItem(value: "rejected", child: Text("Rejected")),
            ],
          )
        ],
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
                showStatus: true, // 👈 admin cần xem trạng thái
                footer: AdminActionButtons(
                  docId: doc.id,
                  status: data["status"] ?? "pending",
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
