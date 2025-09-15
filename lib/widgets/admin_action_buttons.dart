import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminActionButtons extends StatelessWidget {
  final String docId;
  final String status;

  const AdminActionButtons({
    super.key,
    required this.docId,
    required this.status,
  });

  Future<void> _approve(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection("Stories").doc(docId).update({
        "status": "approved",
      });
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Story approved")));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to approve: $e")));
      }
    }
  }

  Future<void> _reject(BuildContext context) async {
    final noteCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Story"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Reason for rejection:"),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter rejection note...",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Reject"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final note = noteCtrl.text.trim();
      if (note.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please provide a rejection note.")),
          );
        }
        return;
      }

      try {
        await FirebaseFirestore.instance
            .collection("Stories")
            .doc(docId)
            .update({"status": "rejected", "rejectNote": note});
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Story rejected")));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Failed to reject: $e")));
        }
      }
    }
  }

  List<Widget> _buildButtons(BuildContext context) {
    switch (status) {
      case "pending":
        return [
          TextButton.icon(
            onPressed: () => _approve(context),
            icon: const Icon(Icons.check_circle, color: Colors.green),
            label: const Text("Approve"),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
          ),
          TextButton.icon(
            onPressed: () => _reject(context),
            icon: const Icon(Icons.cancel, color: Colors.red),
            label: const Text("Reject"),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ];
      case "approved":
        return [
          TextButton.icon(
            onPressed: () => _reject(context),
            icon: const Icon(Icons.cancel, color: Colors.red),
            label: const Text("Reject"),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ];
      default: // rejected or anything else
        return [
          TextButton.icon(
            onPressed: () => _approve(context),
            icon: const Icon(Icons.check_circle, color: Colors.green),
            label: const Text("Approve"),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Action:",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
        ),
        Row(children: _buildButtons(context)),
      ],
    );
  }
}
