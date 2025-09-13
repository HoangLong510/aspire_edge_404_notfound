import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/industries.dart'; // chứa INDUSTRIES + IndustryDef

class CareerDocsAllPage extends StatefulWidget {
  const CareerDocsAllPage({super.key});

  @override
  State<CareerDocsAllPage> createState() => _CareerDocsAllPageState();
}

class _CareerDocsAllPageState extends State<CareerDocsAllPage> {
  final _searchCtrl = TextEditingController();
  String? _selectedIndustryId; // 'it' | 'health' | ...
  String? _selectedCareerId;
  String? _selectedType; // pdf/mp4/null

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
      appBar: AppBar(
        title: const Text("Resource Hub – Tài liệu tất cả nghề"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _selectedIndustryId = null;
                _selectedCareerId = null;
                _selectedType = null;
                _searchCtrl.clear();
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          // 🔍 Filter Section
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search
                  TextField(
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
                  const SizedBox(height: 16),

                  // Industry Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedIndustryId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Industry",
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null, // 👈 null để hiểu là "All"
                        child: Text("All Industries"),
                      ),
                      ...INDUSTRIES.map((ind) => DropdownMenuItem(
                        value: ind.id,
                        child: Row(
                          children: [
                            Icon(ind.icon, size: 18),
                            const SizedBox(width: 6),
                            Text(ind.name),
                          ],
                        ),
                      )),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _selectedIndustryId = v;
                        _selectedCareerId = null; // reset career khi đổi industry
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Career Dropdown
                  if (_selectedIndustryId != null)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("CareerBank")
                          .where("IndustryId", isEqualTo: _selectedIndustryId)
                          .snapshots(),
                      builder: (ctx, snap) {
                        if (!snap.hasData) return const SizedBox();

                        print("=== CAREERS SNAPSHOT ===");
                        for (var d in snap.data!.docs) {
                          print("Career: ${d.id} => ${d.data()}");
                        }
                        print("========================");

                        final careers = snap.data!.docs
                            .where((d) => (d.data() as Map<String, dynamic>)["IndustryId"] == _selectedIndustryId)
                            .toList();

                        if (careers.isEmpty) {
                          return const Text("Không có career nào cho industry này");
                        }

                        return DropdownButtonFormField<String>(
                          value: _selectedCareerId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: "Career",
                            border: OutlineInputBorder(),
                          ),
                          items: careers.map((d) {
                            final name = d['Title'] ?? '';
                            return DropdownMenuItem(
                              value: d.id,
                              child: Text(name),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setState(() => _selectedCareerId = v);
                          },
                        );
                      },
                    ),

                  if (_selectedIndustryId != null) const SizedBox(height: 16),

                  // Type Dropdown
                  DropdownButtonFormField<String?>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: "Loại",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text("Tất cả")),
                      DropdownMenuItem(value: "pdf", child: Text("PDF")),
                      DropdownMenuItem(value: "mp4", child: Text("Video")),
                    ],
                    onChanged: (v) => setState(() => _selectedType = v),
                  ),
                ],
              ),
            ),
          ),

          // 📄 Docs List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup("Docs") // ✅ load all docs
                  .snapshots(),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Chưa có tài liệu nào"));
                }

                final q = _searchCtrl.text.trim().toLowerCase();

                // lọc dữ liệu trong Dart
                final docs = snapshot.data!.docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final careerTitle =
                  (data['careerTitle'] ?? '').toString().toLowerCase();
                  final type = (data['type'] ?? '').toString().toLowerCase();
                  final industryId = data['industry'];
                  final careerId = data['careerId'];

                  final matchSearch =
                      q.isEmpty || title.contains(q) || careerTitle.contains(q);
                  final matchType =
                      _selectedType == null || type == _selectedType;
                  final matchIndustry = _selectedIndustryId == null ||
                      industryId == _selectedIndustryId;
                  final matchCareer =
                      _selectedCareerId == null || careerId == _selectedCareerId;

                  return matchSearch &&
                      matchType &&
                      matchIndustry &&
                      matchCareer;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("Không tìm thấy tài liệu nào"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final industry = industryById(data['industry']);
                    final updatedAt =
                    (data['updatedAt'] as Timestamp?)?.toDate();

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar icon
                            CircleAvatar(
                              backgroundColor: primary.withOpacity(0.1),
                              child: Icon(
                                data['type'] == 'mp4'
                                    ? Icons.play_circle_fill
                                    : Icons.picture_as_pdf,
                                color: primary,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Nội dung chính
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    data['title'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if ((data['careerTitle'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    Text("Nghề: ${data['careerTitle']}"),
                                  if (industry != null &&
                                      industry.id.isNotEmpty)
                                    Text("Ngành: ${industry.name}"),
                                  if ((data['description'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    Text(
                                      data['description'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (updatedAt != null)
                                    Text(
                                      "Cập nhật: ${updatedAt.day}/${updatedAt.month}/${updatedAt.year}",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                            ),

                            // Nút actions
                            Wrap(
                              direction: Axis.vertical,
                              spacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Chip(
                                  label: Text(
                                    (data['type'] ?? '').toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.white),
                                  ),
                                  backgroundColor: data['type'] == 'mp4'
                                      ? Colors.orange
                                      : Colors.red,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed: () =>
                                      _openUrl(data['url'] ?? ''),
                                ),
                              ],
                            ),
                          ],
                        ),
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
