import 'package:aspire_edge_404_notfound/pages/career_doc_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'career_path_add_page.dart';

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.child,
    required this.isFirst,
    required this.isLast,
    required this.index,
    required this.isCurrent,
    required this.primary,
  });

  final Widget child;
  final bool isFirst;
  final bool isLast;
  final int index;
  final bool isCurrent;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(child: Container(width: 2, color: primary.withOpacity(.25))),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isCurrent ? Colors.green : primary,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: primary.withOpacity(.25))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.path,
    required this.isCurrent,
    required this.isAdmin,
    required this.onDelete,
  });

  final DocumentSnapshot path;
  final bool isCurrent;
  final bool isAdmin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final t = Theme.of(context).textTheme;

    final name = (path['Level_Name'] ?? '').toString();
    final salary = (path['Salary_Range'] ?? '').toString();
    final desc = (path['Description'] ?? '').toString();
    final skillsRaw = path.data() is Map ? (path.data() as Map)['Skills'] : [];
    final skills = skillsRaw is List ? skillsRaw.cast<String>() : [];

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isCurrent ? Colors.green : primary.withOpacity(.15),
            width: isCurrent ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name.isEmpty ? "Untitled Level" : name,
                    style: t.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isCurrent ? Colors.green : t.titleMedium?.color,
                    ),
                  ),
                ),
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                    tooltip: "Edit",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CareerPathAddPage(
                            careerId: path.reference.parent.parent!.id,
                            path: path,
                          ),
                        ),
                      );
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: "Delete",
                  onPressed: onDelete,
                ),
              ],
            ),

            if (isCurrent)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  "👉 You are here",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),

            const SizedBox(height: 10),

            if (salary.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.attach_money, size: 18, color: primary),
                  const SizedBox(width: 6),
                  Text(salary, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),

            if (desc.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.description_outlined, size: 18, color: primary.withOpacity(.7)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(desc, style: t.bodyMedium)),
                ],
              ),
            ],

            if (skills.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.tips_and_updates_outlined, size: 18, color: primary),
                  const SizedBox(width: 6),
                  Text(
                    "Key Skills",
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.take(12).map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(.06),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: primary.withOpacity(.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(s, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}



class CareerPathPage extends StatelessWidget {
  final String careerId;
  final bool isAdmin;
  final String? currentPathId;

  const CareerPathPage({
    super.key,
    required this.careerId,
    this.isAdmin = false,
    this.currentPathId,
  });

  Future<void> _deletePath(String careerId, String id) async {
    final ref = FirebaseFirestore.instance
        .collection("CareerBank")
        .doc(careerId)
        .collection("CareerPaths");

    await ref.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme
        .of(context)
        .primaryColor;

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
          color: Theme
              .of(context)
              .colorScheme
              .surface,
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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Career Roadmap",
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Milestones with key skills for each stage",
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      color:
                      Theme
                          .of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
          ],
        ),
      );
    }

    Widget _levelBadge(BuildContext context, String text,
        {bool isCurrent = false}) {
      final primary = Theme
          .of(context)
          .primaryColor;
      return AnimatedScale(
        duration: const Duration(milliseconds: 400),
        scale: 1,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isCurrent
                      ? [primary.withOpacity(0.6), primary.withOpacity(0.3)]
                      : [primary.withOpacity(0.28), primary.withOpacity(0.10)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: isCurrent ? primary : primary.withOpacity(0.35),
                  width: isCurrent ? 2.5 : 1.6,
                ),
              ),
            ),
            CircleAvatar(
              radius: 28,
              backgroundColor: isCurrent ? Colors.amber : primary,
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
        ),
      );
    }


    Widget _railConnector(BuildContext context) {
      final primary = Theme
          .of(context)
          .primaryColor;
      return Column(
        children: [
          Container(
            width: 2.6,
            height: 14,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.28),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Icon(Icons.arrow_downward_rounded,
              size: 22, color: primary.withOpacity(0.85)),
          Container(
            width: 2.6,
            height: 14,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.28),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      );
    }

    Widget _salaryChip(BuildContext context, String value) {
      final primary = Theme
          .of(context)
          .primaryColor;
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
              style: Theme
                  .of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    Widget _skillsChips(BuildContext context, List<String> skills) {
      final primary = Theme
          .of(context)
          .primaryColor;
      if (skills.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.tips_and_updates_outlined,
                  size: 18, color: primary),
              const SizedBox(width: 8),
              Text(
                "Key Skills",
                style: Theme
                    .of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills
                .map(
                  (s) =>
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: primary.withOpacity(0.22)),
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

    Widget _pathCard({
      required BuildContext context,
      required DocumentSnapshot path,
      required bool isLast,
    }) {
      final primary = Theme
          .of(context)
          .primaryColor;
      final level = path['Level_Order'].toString();
      final name = (path['Level_Name'] ?? '').toString();
      final salary = (path['Salary_Range'] ?? '').toString();
      final desc = (path['Description'] ?? '').toString();
      final skills = _parseSkills(
        path.data() is Map ? (path.data() as Map)['Skills'] : null,
      );

      final isCurrent = (currentPathId == path.id);

      final content = AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 500),
        child: Container(
          decoration: BoxDecoration(
            color: Theme
                .of(context)
                .colorScheme
                .surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCurrent ? primary : primary.withOpacity(0.20),
              width: isCurrent ? 2.2 : 1.2,
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
                        style: Theme
                            .of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight: isCurrent
                              ? FontWeight.w900
                              : FontWeight.w700,
                          color: isCurrent ? primary : null,
                        ),
                      ),
                    ),
                    if (isAdmin)
                      IconButton(
                        tooltip: "Delete",
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        onPressed: () => _deletePath(careerId, path.id),
                      ),
                  ],
                ),

                if (isCurrent) ...[
                  const SizedBox(height: 6),
                  Text(
                    "👉 Bạn đang ở đây",
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],

                const SizedBox(height: 8),
                _salaryChip(context, salary),

                const SizedBox(height: 10),
                Text(
                  desc.isEmpty ? "—" : desc,
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodyMedium,
                ),

                _skillsChips(context, skills),
              ],
            ),
          ),
        ),
      );
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const SizedBox(height: 6),
              _levelBadge(context, level, isCurrent: isCurrent),
              if (!isLast) ...[
                const SizedBox(height: 6),
                _railConnector(context),
              ],
            ],
          ),
          const SizedBox(width: 16),
          Expanded(child: content),
        ],
      );
    }

    Widget _docsButton(String careerId, Color primary) {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("CareerBank")
            .doc(careerId)
            .collection("Docs")
            .limit(1)
            .snapshots(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final hasDocs = snapshot.data!.docs.isNotEmpty;
          if (!hasDocs) return const SizedBox.shrink();

          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => CareerDocsPage(careerId: careerId),
                  ),
                );
              },
              icon: const Icon(Icons.file_download),
              label: const Text("Download Resources"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: primary,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
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

          return RefreshIndicator(
            onRefresh: () async {},
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionHeader(),
                  const SizedBox(height: 22),

                  if (paths.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.route, size: 64, color: primary.withOpacity(.6)),
                          const SizedBox(height: 16),
                          Text(
                            "No roadmap yet",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Add levels to build this career roadmap.",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...List.generate(paths.length, (index) {
                      final path = paths[index];
                      final isFirst = index == 0;
                      final isLast = index == paths.length - 1;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _TimelineRow(
                          isFirst: isFirst,
                          isLast: isLast,
                          index: index,
                          isCurrent: (currentPathId == path.id),
                          primary: primary,
                          child: _PathCard(
                            path: path,
                            isCurrent: (currentPathId == path.id),
                            isAdmin: isAdmin,
                            onDelete: () => _deletePath(careerId, path.id),
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 28),

                  _docsButton(careerId, primary),
                ],
              ),
            ),
          );
        },
      ),
    );


  }
}
