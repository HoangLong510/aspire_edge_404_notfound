import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  bool _isAdmin = false;
  bool _loadingRole = true;

  String _searchQuery = "";
  String _selectedCareerId = "all";
  bool _sortNewest = true;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _loadingRole = false;
        });
      }
      return;
    }

    final snap =
        await FirebaseFirestore.instance.collection("Users").doc(uid).get();
    if (mounted) {
      final tier = (snap.data() ?? {})["Tier"];
      setState(() {
        _isAdmin = tier == "admin";
        _loadingRole = false;
      });
    }
  }

  Future<void> _deleteBlog(String blogId) async {
    await FirebaseFirestore.instance.collection("Blogs").doc(blogId).delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Blog deleted"),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ====== UI helpers ======
  InputDecoration _searchDec(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return InputDecoration(
      hintText: "Search blogs...",
      prefixIcon: const Icon(Icons.search),
      filled: true,
      fillColor: Colors.black.withOpacity(0.03),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: primary.withOpacity(.18)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: primary.withOpacity(.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: primary, width: 2),
      ),
    );
  }

  // ✅ Filter + Sort (không bọc card)
  Widget _filtersRow(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("CareerBank")
                  .orderBy("Title")
                  .snapshots(),
              builder: (context, snapshot) {
                final items = [
                  const DropdownMenuItem(
                    value: "all",
                    child: Text("All Industries"),
                  ),
                  ...?snapshot.data?.docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: d.id,
                      child: Text(data["Title"] ?? d.id),
                    );
                  }),
                ];
                return DropdownButtonFormField<String>(
                  value: _selectedCareerId,
                  items: items,
                  decoration: InputDecoration(
                    labelText: "Industry",
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: false,
                  ),
                  onChanged: (v) {
                    setState(() => _selectedCareerId = v ?? "all");
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primary.withOpacity(.18)),
            ),
            child: DropdownButton<bool>(
              value: _sortNewest,
              borderRadius: BorderRadius.circular(12),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(
                  value: true,
                  child: Text("Newest first"),
                ),
                DropdownMenuItem(
                  value: false,
                  child: Text("Oldest first"),
                ),
              ],
              onChanged: (v) {
                setState(() => _sortNewest = v ?? true);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Card blog KHÔNG có màu nền; title màu đen; thêm shadow nhẹ để nổi khối
  Widget _blogCard({
    required String id,
    required String title,
    required DateTime? createdAt,
    required int views,
    required String? firstImage,
  }) {
    final primary = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withOpacity(.12), width: 1),
        boxShadow: [
          // 👇 thêm nổi khối nhẹ
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(
              context,
              "/blog_detail",
              arguments: {"blogId": id},
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh full ngang
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: firstImage != null
                    ? AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          firstImage,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                      ),
              ),

              // Nội dung
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title màu đen
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        if (createdAt != null)
                          _ChipInfo(
                            icon: Icons.calendar_today_outlined,
                            label: DateFormat("dd/MM/yyyy HH:mm")
                                .format(createdAt),
                          ),
                        _ChipInfo(
                          icon: Icons.visibility_outlined,
                          label: "$views views",
                        ),
                      ],
                    ),

                    // Hành động admin
                    if (_isAdmin) ...[
                      const Divider(height: 22),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                "/blog_edit",
                                arguments: {"blogId": id},
                              );
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text("Edit"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary.withOpacity(0.08),
                              foregroundColor: primary,
                              elevation: 0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _deleteBlog(id),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text("Delete"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.08),
                              foregroundColor: Colors.red,
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    if (_loadingRole) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 12),
            // 🔎 Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                decoration: _searchDec(context),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
              ),
            ),

            // 🔽 Filter + Sort (không bọc card)
            _filtersRow(context),

            const SizedBox(height: 8),

            // 📃 Blog list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("Blogs")
                    .orderBy("CreatedAt", descending: _sortNewest)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading blogs"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text("No blogs available"));
                  }

                  // Filter theo search & career
                  final filtered = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final title =
                        (data["Title"] ?? "").toString().toLowerCase();
                    final careerId = (data["CareerId"] ?? "").toString();
                    final matchTitle = title.contains(_searchQuery);
                    final matchCareer = _selectedCareerId == "all" ||
                        careerId == _selectedCareerId;
                    return matchTitle && matchCareer;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text("No matching blogs"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final d = filtered[index];
                      final data = d.data() as Map<String, dynamic>;

                      final id = d.id;
                      final title = data["Title"] ?? "Untitled";
                      final createdAt =
                          (data["CreatedAt"] as Timestamp?)?.toDate();
                      final views = (data["Views"] ?? 0) as int;
                      final imageUrls =
                          (data["ImageUrls"] as List?)?.cast<String>() ?? [];
                      final firstImage =
                          imageUrls.isNotEmpty ? imageUrls.first : null;

                      return _blogCard(
                        id: id,
                        title: title,
                        createdAt: createdAt,
                        views: views,
                        firstImage: firstImage,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),

        // ✅ Nút thêm blog cho admin (góc dưới bên phải)
        if (_isAdmin)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, "/blog_create"),
              icon: const Icon(Icons.add),
              label: const Text("New Blog"),
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}

// ====== Chip nho nhỏ hiển thị meta ======
class _ChipInfo extends StatelessWidget {
  const _ChipInfo({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
