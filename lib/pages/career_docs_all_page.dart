import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CareerDocsAllPage extends StatefulWidget {
  const CareerDocsAllPage({super.key});

  @override
  State<CareerDocsAllPage> createState() => _CareerDocsAllPageState();
}

class _CareerDocsAllPageState extends State<CareerDocsAllPage> {
  final _searchCtrl = TextEditingController();
  String? _selectedType; // pdf / video / null

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text("Resource Hub – Tài liệu tất cả nghề")),
      body: Column(
        children: [
          // 🔍 Search + Filter bar
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: "Tìm theo tên tài liệu hoặc nghề...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: _selectedType,
                  hint: const Text("Loại"),
                  items: const [
                    DropdownMenuItem(value: null, child: Text("Tất cả")),
                    DropdownMenuItem(value: "pdf", child: Text("PDF")),
                    DropdownMenuItem(value: "video", child: Text("Video")),
                  ],
                  onChanged: (v) => setState(() => _selectedType = v),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup("Docs")
              // .orderBy("updatedAt", descending: true) // cần index mới dùng được
                  .snapshots(),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Chưa có tài liệu nào"));
                }

                final q = _searchCtrl.text.trim().toLowerCase();
                final docs = snapshot.data!.docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final career = (data['careerTitle'] ?? '').toString().toLowerCase();
                  final type = (data['type'] ?? '').toString().toLowerCase();

                  final matchSearch = q.isEmpty ||
                      title.contains(q) ||
                      career.contains(q);
                  final matchType =
                      _selectedType == null || type == _selectedType;

                  return matchSearch && matchType;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("Không tìm thấy tài liệu nào"));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;

                    return ListTile(
                      leading: Icon(
                        data['type'] == 'video'
                            ? Icons.video_library
                            : Icons.picture_as_pdf,
                        color: primary,
                      ),
                      title: Text(data['title'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((data['careerTitle'] ?? '').toString().isNotEmpty)
                            Text("Nghề: ${data['careerTitle']}"),
                          if ((data['description'] ?? '').toString().isNotEmpty)
                            Text(data['description']),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => _openUrl(data['url'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
