import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: "Resources"),
            Tab(text: "Industries"),
            Tab(text: "Skills"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _CandidateList(collection: 'ResourceCandidates'),
          _CandidateList(collection: 'IndustryCandidates'),
          _CandidateList(collection: 'SkillCandidates'),
        ],
      ),
    );
  }
}

class _CandidateList extends StatelessWidget {
  final String collection;
  const _CandidateList({required this.collection});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(child: Text("No pending items"));
        }

        final docs = snap.data!.docs;
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final title = (d['title'] ?? 'Untitled').toString();
            final byName = (d['requested_by_name'] ?? '').toString();
            final byEmail = (d['requested_by_email'] ?? '').toString();

            return ListTile(
              title: Text(title),
              subtitle: Text(
                byName.isNotEmpty ? "By $byName" : "By $byEmail",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Approve',
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () {
                      FirebaseFirestore.instance
                          .collection(collection)
                          .doc(docs[i].id)
                          .update({'status': 'approved'});
                    },
                  ),
                  IconButton(
                    tooltip: 'Reject',
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      FirebaseFirestore.instance
                          .collection(collection)
                          .doc(docs[i].id)
                          .update({'status': 'rejected'});
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
