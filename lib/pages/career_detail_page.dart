import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'career_add_page.dart';
import 'career_path_page.dart';

class CareerDetailPage extends StatefulWidget {
  final String careerId;
  const CareerDetailPage({super.key, required this.careerId});

  @override
  State<CareerDetailPage> createState() => _CareerDetailPageState();
}

class _CareerDetailPageState extends State<CareerDetailPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String? _userTier;
  DocumentSnapshot? _careerData;

  @override
  void initState() {
    super.initState();
    _loadUserTier();
    _loadCareer();
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

  Future<void> _loadCareer() async {
    final doc =
    await _firestore.collection("CareerBank").doc(widget.careerId).get();
    setState(() {
      _careerData = doc;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_careerData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = _careerData!;

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_userTier == "admin")
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CareerAddPage(career: data),
                  ),
                );
              },
            )
        ],
      ),
      // Thay thế toàn bộ: body: Padding(...)
// =============== NEW BODY (UI only, no logic change) ===============
      body: LayoutBuilder(
        builder: (context, constraints) {
          final primary = Theme.of(context).primaryColor;
          final isWide = constraints.maxWidth >= 900;

          final title = (data['Title'] ?? '').toString();
          final industry = (data['Industry'] ?? '').toString();
          final description = (data['Description'] ?? '').toString();
          final skillsText = (data['Skills'] ?? '').toString();
          final salary = (data['Salary_Range'] ?? '').toString();
          final education = (data['Education_Path'] ?? '').toString();
          final skills = skillsText
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();

          Widget sectionHeader(IconData icon, String text, {String? sub}) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 28,
                  margin: const EdgeInsets.only(right: 12, top: 3),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(icon, size: 18, color: primary),
                        const SizedBox(width: 8),
                        Text(
                          text,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ]),
                      if (sub != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          sub,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }

          Widget infoCard({
            required IconData icon,
            required String title,
            required Widget child,
          }) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: primary.withOpacity(0.14)),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  child,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    children: [
                      // HEADER BANNER
                      Container(
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
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title + industry chip
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (industry.isNotEmpty)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: primary.withOpacity(0.22)),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.business_center_outlined, size: 16, color: primary),
                                        const SizedBox(width: 6),
                                        Text(industry, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 14),
                            Divider(height: 24, color: primary.withOpacity(0.18)),

                            // Skills chips
                            if (skills.isNotEmpty) ...[
                              sectionHeader(Icons.tips_and_updates_outlined, "Skills",
                                  sub: "Key skills for this career"),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: skills
                                    .map(
                                      (s) => Chip(
                                    label: Text(s),
                                    backgroundColor: primary.withOpacity(0.10),
                                    side: BorderSide(color: primary.withOpacity(0.25)),
                                    labelStyle: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                    avatar: Icon(Icons.check_circle_outline, size: 16, color: primary),
                                  ),
                                )
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // MAIN CONTENT GRID
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: Description
                            Expanded(
                              flex: 6,
                              child: infoCard(
                                icon: Icons.description_outlined,
                                title: "Description",
                                child: Text(
                                  description.isEmpty ? "—" : description,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            // Right: Salary + Education (stacked)
                            Expanded(
                              flex: 4,
                              child: Column(
                                children: [
                                  infoCard(
                                    icon: Icons.attach_money,
                                    title: "Salary Range",
                                    child: Text(
                                      salary.isEmpty ? "—" : salary,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  infoCard(
                                    icon: Icons.school_outlined,
                                    title: "Education Path",
                                    child: Text(
                                      education.isEmpty ? "—" : education,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            infoCard(
                              icon: Icons.description_outlined,
                              title: "Description",
                              child: Text(
                                description.isEmpty ? "—" : description,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(height: 18),
                            infoCard(
                              icon: Icons.attach_money,
                              title: "Salary Range",
                              child: Text(
                                salary.isEmpty ? "—" : salary,
                                style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 18),
                            infoCard(
                              icon: Icons.school_outlined,
                              title: "Education Path",
                              child: Text(
                                education.isEmpty ? "—" : education,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 22),

                      // CTA: View Career Path
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CareerPathPage(
                                      careerId: data.id,
                                      isAdmin: _userTier == "admin",
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.route),
                              label: const Text("View Career Path"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
// =============== END NEW BODY ===============
    );
  }
}
