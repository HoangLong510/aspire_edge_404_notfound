import 'package:aspire_edge_404_notfound/widgets/admin_action_buttons.dart';
import 'package:aspire_edge_404_notfound/widgets/story_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AdminStoriesPage extends StatefulWidget {
  const AdminStoriesPage({super.key});

  @override
  State<AdminStoriesPage> createState() => _AdminStoriesPageState();
}

class _AdminStoriesPageState extends State<AdminStoriesPage> {
  String? _statusFilter;

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
        title: const Text("All Stories"),
        centerTitle: true,
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Iconsax.filter),
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
                  Text("No stories found"),
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
