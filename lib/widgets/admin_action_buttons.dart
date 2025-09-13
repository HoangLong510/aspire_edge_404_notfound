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

  void _approve() {
    FirebaseFirestore.instance.collection("Stories").doc(docId).update({
      "status": "approved",
    });
  }

  void _reject(BuildContext context) async {
    final noteCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Story"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Lý do từ chối:"),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Nhập ghi chú...",
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
            child: const Text("Reject"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      FirebaseFirestore.instance.collection("Stories").doc(docId).update({
        "status": "rejected",
        "rejectNote": noteCtrl.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> buttons = [];

    if (status == "pending") {
      buttons = [
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
      ];
    } else if (status == "approved") {
      buttons = [
        TextButton.icon(
          onPressed: () => _reject(context),
          icon: const Icon(Icons.cancel, color: Colors.red),
          label: const Text("Reject"),
        ),
      ];
    } else {
      buttons = [
        TextButton.icon(
          onPressed: _approve,
          icon: const Icon(Icons.check_circle, color: Colors.green),
          label: const Text("Approve"),
        ),
      ];
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Action:",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        Row(children: buttons),
      ],
    );
  }
}
