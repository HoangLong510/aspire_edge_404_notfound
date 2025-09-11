import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'career_path_add_page.dart';

class CareerPathPage extends StatelessWidget {
  final String careerId;
  final bool isAdmin;

  const CareerPathPage({
    super.key,
    required this.careerId,
    this.isAdmin = false,
  });

  /// Xóa và reorder lại Level_Order
  Future<void> _deletePath(String careerId, String id) async {
    final ref = FirebaseFirestore.instance
        .collection("CareerBank")
        .doc(careerId)
        .collection("CareerPaths");

    // Xóa document
    await ref.doc(id).delete();

    // Reorder lại level sau khi xóa
    final snapshot = await ref.orderBy("Level_Order").get();
    int i = 1;
    for (var doc in snapshot.docs) {
      await doc.reference.update({"Level_Order": i});
      i++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pathsRef = FirebaseFirestore.instance
        .collection("CareerBank")
        .doc(careerId)
        .collection("CareerPaths")
        .orderBy("Level_Order");

    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text("Lộ trình nghề")),
      // =================== NEW BODY (UI only, keep logic) ===================
      body: LayoutBuilder(
        builder: (context, constraints) {
          final primary = Theme.of(context).primaryColor;
          final isWide = constraints.maxWidth >= 1000;

          List<String> _parseSkills(dynamic raw) {
            if (raw == null) return [];
            if (raw is List) {
              return raw
                  .map((e) => e?.toString().trim() ?? "")
                  .where((e) => e.isNotEmpty)
                  .toList();
            }
            return raw
                .toString()
                .split(RegExp(r'[,\n]'))
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }

          Widget _sectionHeader() {
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: primary.withOpacity(0.18)),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.timeline, color: primary, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Career Roadmap",
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Các mốc phát triển theo Level_Order · Kèm kỹ năng trọng tâm cho từng giai đoạn",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),

                  // 👇👇 THÊM NÚT Ở ĐÂY
                  const SizedBox(width: 12),
                  if (isAdmin)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CareerPathAddPage(careerId: careerId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Add Level"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                ],
              ),
            );
          }


          Widget _levelBadge(String text) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        primary.withOpacity(0.28),
                        primary.withOpacity(0.10),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: primary.withOpacity(0.35),
                      width: 1.6,
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 28,
                  backgroundColor: primary,
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            );
          }

          Widget _salaryChip(String value) {
            final txt = value.isEmpty ? "—" : value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: primary.withOpacity(0.24)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.attach_money, size: 18, color: primary),
                  const SizedBox(width: 6),
                  Text(
                    txt,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }

          Widget _skillsChips(List<String> skills) {
            if (skills.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_outlined,
                      size: 18,
                      color: primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Key Skills",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills
                      .map(
                        (s) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: primary.withOpacity(0.22),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 16),
                              const SizedBox(width: 6),
                              Text(s),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            );
          }

          Widget _pathCard(DocumentSnapshot path) {
            final level = path['Level_Order'].toString();
            final name = (path['Level_Name'] ?? '').toString();
            final salary = (path['Salary_Range'] ?? '').toString();
            final desc = (path['Description'] ?? '').toString();
            final skills = _parseSkills(
              path.data() is Map ? (path.data() as Map)['Skills'] : null,
            );

            final content = Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: primary.withOpacity(0.20),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.07),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name.isEmpty ? "Untitled Level" : name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _salaryChip(salary),
                        if (isAdmin) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: "Delete",
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _deletePath(careerId, path.id),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      desc.isEmpty ? "—" : desc,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    _skillsChips(skills),
                  ],
                ),
              ),
            );

            // layout: badge trái + card phải
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [const SizedBox(height: 6), _levelBadge(level)],
                ),
                const SizedBox(width: 16),
                Expanded(child: content),
              ],
            );
          }

          // Separator mũi tên lớn + line
          Widget _arrowSeparator() {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Container(
                    width: 3,
                    height: isWide ? 22 : 18,
                    color: primary.withOpacity(0.28),
                  ),
                  Icon(
                    Icons.arrow_downward_rounded,
                    size: 30,
                    color: primary.withOpacity(0.8),
                  ),
                  Container(
                    width: 3,
                    height: isWide ? 12 : 10,
                    color: primary.withOpacity(0.28),
                  ),
                ],
              ),
            );
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
              stream: FirebaseFirestore.instance
                  .collection("CareerBank")
                  .doc(careerId)
                  .collection("CareerPaths")
                  .orderBy("Level_Order")
                  .snapshots(),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final paths = snapshot.data!.docs;
                if (paths.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.route,
                            size: 56,
                            color: primary.withOpacity(0.6),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Chưa có lộ trình nào",
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Hãy thêm các level để hoàn thiện roadmap nghề nghiệp.",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
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
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: Column(
                        children: [
                          _sectionHeader(),
                          const SizedBox(height: 16),
                          // timeline list
                          ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: paths.length,
                            separatorBuilder: (ctx, i) => _arrowSeparator(),
                            itemBuilder: (ctx, i) => _pathCard(paths[i]),
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
    );
  }
}
