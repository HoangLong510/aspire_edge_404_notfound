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
        children: [
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
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("No pending items"));
        }
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(d['title'] ?? 'Untitled'),
              subtitle: Text("By ${d['requested_by_name'] ?? d['requested_by_email']}"),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () {
                      FirebaseFirestore.instance
                          .collection(collection)
                          .doc(docs[i].id)
                          .update({'status': 'approved'});
                    },
                  ),
                  IconButton(
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