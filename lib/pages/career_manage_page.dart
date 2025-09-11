import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'career_add_page.dart';
import 'career_detail_page.dart';

class CareerManagePage extends StatefulWidget {
  const CareerManagePage({super.key});

  @override
  State<CareerManagePage> createState() => _CareerManagePageState();
}

class _CareerManagePageState extends State<CareerManagePage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String? _userTier;

  final TextEditingController _searchTitleCtrl = TextEditingController();

  // Thứ tự ưu tiên ngành để sort
  static const List<String> _industryOrder = [
    'Information Technology',
    'Healthcare',
    'Art',
    'Science',
  ];

  String? _selectedIndustry;

  @override
  void initState() {
    super.initState();
    _loadUserTier();
    _searchTitleCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchTitleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserTier() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection("Users").doc(user.uid).get();
      setState(() {
        _userTier = doc["Tier"];
      });
    }
  }

  void _deleteCareer(String id) async {
    await _firestore.collection("CareerBank").doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    if (_userTier == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      // =================== NEW BODY (UI only, keep logic) ===================
      body: LayoutBuilder(
        builder: (context, constraints) {
          final primary = Theme.of(context).primaryColor;
          final isWide = constraints.maxWidth >= 900;

          String _initials(String s) {
            final parts = s.trim().split(RegExp(r"\s+"));
            if (parts.isEmpty) return "";
            if (parts.length == 1)
              return parts.first.characters.take(2).toString().toUpperCase();
            return (parts.first.characters.take(1).toString() +
                    parts.last.characters.take(1).toString())
                .toUpperCase();
          }

          String _safe(DocumentSnapshot d, String key) {
            final m = d.data() as Map<String, dynamic>?;
            return (m?[key] ?? '').toString();
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primary.withOpacity(0.05), primary.withOpacity(0.02)],
              ),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection("CareerBank").snapshots(),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final careers = snapshot.data!.docs;
                // Lọc theo Title (không phân biệt hoa thường)
                // Lọc theo Title + Industry (4 ngành hoặc All)
                final q = _searchTitleCtrl.text.trim().toLowerCase();

                List<QueryDocumentSnapshot> visible = careers.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final title = (data['Title'] ?? '').toString().toLowerCase();
                  final industry = (data['Industry'] ?? '').toString();

                  final matchTitle = q.isEmpty || title.contains(q);
                  final matchIndustry = _selectedIndustry == null
                      ? true
                      : industry.toLowerCase().trim() ==
                            _selectedIndustry!.toLowerCase().trim();

                  return matchTitle && matchIndustry;
                }).toList();

                if (careers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 56,
                            color: primary.withOpacity(0.6),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Chưa có nghề nào",
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Hãy thêm nghề để bắt đầu quản lý Career Bank.",
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        children: [
                          // Header card
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: primary.withOpacity(0.18),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withOpacity(0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.work,
                                    color: primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Careers",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "List of Careers in sytem",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 10),
                                      LayoutBuilder(
                                        builder: (ctx, cst) {
                                          final narrow = cst.maxWidth < 620;

                                          // Widget dropdown lọc Industry (co giãn, giới hạn max width)
                                          Widget industryFilter() {
                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: ConstrainedBox(
                                                    constraints: const BoxConstraints(minWidth: 160, maxWidth: 260),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                                      decoration: BoxDecoration(
                                                        color: primary.withOpacity(0.06),
                                                        border: Border.all(color: primary.withOpacity(0.25)),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: DropdownButtonHideUnderline(
                                                        child: DropdownButton<String?>(
                                                          isExpanded: true, // ✨ giúp co giãn không tràn
                                                          value: _selectedIndustry,
                                                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                                          items: <DropdownMenuItem<String?>>[
                                                            const DropdownMenuItem(
                                                              value: null,
                                                              child: Text("All industries"),
                                                            ),
                                                            ..._industryOrder.map(
                                                                  (e) => DropdownMenuItem(
                                                                value: e,
                                                                child: Text(e, overflow: TextOverflow.ellipsis),
                                                              ),
                                                            ),
                                                          ],
                                                          onChanged: (v) => setState(() => _selectedIndustry = v),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (_selectedIndustry != null) ...[
                                                  const SizedBox(width: 6),
                                                  IconButton(
                                                    tooltip: "Xoá lọc industry",
                                                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                                    padding: EdgeInsets.zero,
                                                    onPressed: () => setState(() => _selectedIndustry = null),
                                                    icon: const Icon(Icons.clear),
                                                  ),
                                                ],
                                              ],
                                            );
                                          }

                                          final searchBox = TextField(
                                            controller: _searchTitleCtrl,
                                            decoration: InputDecoration(
                                              hintText: "Tìm theo Title…",
                                              prefixIcon: const Icon(Icons.search),
                                              isDense: true,
                                              filled: true,
                                              fillColor: primary.withOpacity(0.06),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(color: primary.withOpacity(0.25)),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(color: primary, width: 1.6),
                                              ),
                                              contentPadding:
                                              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            ),
                                          );

                                          // Hẹp -> xếp dọc; Rộng -> xếp hàng ngang
                                          return narrow
                                              ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              searchBox,
                                              const SizedBox(height: 10),
                                              industryFilter(),
                                            ],
                                          )
                                              : Row(
                                            children: [
                                              Expanded(child: searchBox),
                                              const SizedBox(width: 12),
                                              // lọc co giãn, không tràn
                                              SizedBox(width: 260, child: industryFilter()),
                                            ],
                                          );
                                        },
                                      )

                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: primary.withOpacity(0.25),
                                    ),
                                  ),
                                  child: Text(
                                    "${visible.length} items",
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // List / Grid responsive
                          LayoutBuilder(
                            builder: (context, cst) {
                              final useGrid = isWide; // grid khi màn rộng
                              if (!useGrid) {
                                // List dọc cho mobile
                                return ListView.separated(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: visible.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (ctx, i) {
                                    final career = visible[i];
                                    final title = (career['Title'] ?? '')
                                        .toString();
                                    final industry = (career['Industry'] ?? '')
                                        .toString();
                                    final desc = (career['Description'] ?? '')
                                        .toString();
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: primary.withOpacity(0.18),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primary.withOpacity(0.07),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        isThreeLine: true,
                                        contentPadding:
                                            const EdgeInsets.fromLTRB(
                                              14,
                                              12,
                                              14,
                                              12,
                                            ),
                                        leading: CircleAvatar(
                                          radius: 26,
                                          backgroundColor: primary,
                                          child: Text(
                                            _initials(title),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          // tránh tràn
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            if (industry.isNotEmpty)
                                              Wrap(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: primary
                                                          .withOpacity(0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            999,
                                                          ),
                                                      border: Border.all(
                                                        color: primary
                                                            .withOpacity(0.22),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .business_center_outlined,
                                                          size: 16,
                                                          color: primary,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Flexible(
                                                          child: Text(
                                                            industry,
                                                            overflow: TextOverflow
                                                                .ellipsis, // nếu industry dài
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            if (desc.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                desc,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),

                                        // ✨ THÊM onTap ở đây
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CareerDetailPage(
                                                career: career,
                                              ),
                                            ),
                                          );
                                        },

                                        trailing:
                                            _userTier?.toLowerCase() == "admin"
                                            ? ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                      maxWidth: 104,
                                                    ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        color: Colors.blue,
                                                      ),
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                CareerAddPage(
                                                                  career:
                                                                      career,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed: () =>
                                                          _deleteCareer(
                                                            career.id,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : null,
                                      ),
                                    );
                                  },
                                );
                              }

                              // Grid cho màn rộng
                              final crossCount = constraints.maxWidth >= 1200
                                  ? 3
                                  : 2;
                              return GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossCount,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                      childAspectRatio: 3.2,
                                    ),
                                itemCount: visible.length,
                                itemBuilder: (ctx, i) {
                                  final career = visible[i];
                                  final title = _safe(career, 'Title');
                                  final industry = _safe(career, 'Industry');
                                  final desc = _safe(career, 'Description');

                                  return Material(
                                    // thêm Material để ripple hoạt động đúng
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CareerDetailPage(
                                              career: career,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(
                                          14,
                                          14,
                                          14,
                                          12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surface,
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border: Border.all(
                                            color: primary.withOpacity(0.18),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primary.withOpacity(0.07),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 26,
                                              backgroundColor: primary,
                                              child: Text(
                                                _initials(title),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      // Tiêu đề co giãn + ellipsis để không tràn
                                                      Expanded(
                                                        child: Text(
                                                          title,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .titleMedium
                                                              ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                              ),
                                                        ),
                                                      ),
                                                      // Cụm nút admin (nếu có) — giới hạn bề ngang để không đè vùng tap
                                                      if (_userTier
                                                              ?.toLowerCase() ==
                                                          "admin")
                                                        ConstrainedBox(
                                                          constraints:
                                                              const BoxConstraints(
                                                                maxWidth: 104,
                                                              ),
                                                          // ~2 icon
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              IconButton(
                                                                tooltip: "Edit",
                                                                icon: Icon(
                                                                  Icons.edit,
                                                                  size: 20,
                                                                  color:
                                                                      primary,
                                                                ),
                                                                onPressed: () {
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder: (_) => CareerAddPage(
                                                                        career:
                                                                            career,
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                              IconButton(
                                                                tooltip:
                                                                    "Delete",
                                                                icon: const Icon(
                                                                  Icons
                                                                      .delete_outline,
                                                                  size: 20,
                                                                  color: Colors
                                                                      .redAccent,
                                                                ),
                                                                onPressed: () =>
                                                                    _deleteCareer(
                                                                      career.id,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),

                                                  // Industry chip — bọc Wrap + Flexible để không overflow
                                                  if (industry.isNotEmpty)
                                                    Wrap(
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 6,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: primary
                                                                .withOpacity(
                                                                  0.12,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  999,
                                                                ),
                                                            border: Border.all(
                                                              color: primary
                                                                  .withOpacity(
                                                                    0.22,
                                                                  ),
                                                            ),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .business_center_outlined,
                                                                size: 16,
                                                                color: primary,
                                                              ),
                                                              const SizedBox(
                                                                width: 6,
                                                              ),
                                                              Flexible(
                                                                child: Text(
                                                                  industry,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                  if (desc.isNotEmpty) ...[
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      desc,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: Theme.of(context)
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                          ),
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
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      // =================== END NEW BODY ===================
      floatingActionButton: _userTier?.toLowerCase() == "admin"
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CareerAddPage()),
                );
              },
              label: const Text("Thêm nghề"),
              icon: const Icon(Icons.add),
              backgroundColor: Theme.of(context).primaryColor,
            )
          : null,
    );
  }
}
