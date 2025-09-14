import 'package:aspire_edge_404_notfound/config/industries.dart';
import 'package:aspire_edge_404_notfound/pages/notifications_center_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CareerAddPage extends StatefulWidget {
  final DocumentSnapshot? career;

  const CareerAddPage({super.key, this.career});

  @override
  State<CareerAddPage> createState() => _CareerAddPageState();
}

class _CareerAddPageState extends State<CareerAddPage> {

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _skillsController;
  late TextEditingController _salaryController;
  late TextEditingController _eduController;
  String? _selectedIndustryId;
  String? _selectedIndustryName;

  @override
  void initState() {
    super.initState();
    final Map<String, dynamic> data =
        (widget.career?.data() as Map<String, dynamic>?) ?? {};

    final title        = (data['Title'] ?? '').toString();
    final desc         = (data['Description'] ?? '').toString();
    final skills       = (data['Skills'] ?? '').toString();
    final salary       = (data['Salary_Range'] ?? '').toString();
    final edu          = (data['Education_Path'] ?? '').toString();

    final industryId = (data['IndustryId'] ?? '').toString();
    final legacy     = (data['Industry'] ?? '').toString();

    String? resolvedId;
    String? resolvedName;

    if (industryId.isNotEmpty && industryById(industryId) != null) {
      resolvedId = industryId;
      resolvedName = industryById(industryId)!.name;
    } else if (legacy.isNotEmpty && industryByName(legacy) != null) {
      resolvedId = industryByName(legacy)!.id;
      resolvedName = industryByName(legacy)!.name;
    }

    _selectedIndustryId   = resolvedId;
    _selectedIndustryName = resolvedName;

    _titleController  = TextEditingController(text: title);
    _descController   = TextEditingController(text: desc);
    _skillsController = TextEditingController(text: skills);
    _salaryController = TextEditingController(text: salary);
    _eduController    = TextEditingController(text: edu);

    _selectedIndustryId   = resolvedId;
    _selectedIndustryName = resolvedName;
  }



  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _skillsController.dispose();
    _salaryController.dispose();
    _eduController.dispose();
    super.dispose();
  }

  Future<void> _saveCareer() async {
    if (!_formKey.currentState!.validate()) return;

    final fs = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    final title = _titleController.text.trim();
    final data = {
      "Title": title,
      "IndustryId": _selectedIndustryId,
      "Industry": _selectedIndustryName,
      "Description": _descController.text.trim(),
      "Skills": _skillsController.text.trim(),
      "Salary_Range": _salaryController.text.trim(),
      "Education_Path": _eduController.text.trim(),
      "updatedAt": FieldValue.serverTimestamp(),
    };

    String careerId;
    final isEditing = widget.career != null;

    if (isEditing) {
      careerId = widget.career!.id;
      await fs.collection("CareerBank").doc(careerId).update(data);

      final adminUid = auth.currentUser?.uid ?? 'admin';
      await NotiAdminApi.sendCareerUpdateToFavoriters(
        adminUid: adminUid,
        careerId: careerId,
        careerTitle: title,
      );
    } else {
      careerId = title.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
      await fs
          .collection("CareerBank")
          .doc(careerId)
          .set(data, SetOptions(merge: true));
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? "Career updated successfully"
                : "Career added successfully",
          ),
        ),
      );
    }
  }



  InputDecoration _decoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.6,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _sectionTitle(IconData icon, String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final primary = Theme.of(context).primaryColor;
          final isWide = constraints.maxWidth >= 900;

          InputDecoration deco({
            required String label,
            String? hint,
            IconData? icon,
            int lines = 1,
          }) {
            return InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon: icon != null ? Icon(icon, color: primary) : null,
              filled: true,
              fillColor: primary.withOpacity(0.04),
              labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primary.withOpacity(0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primary, width: 1.8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            );
          }

          Widget sectionTitle(String title, {IconData icon = Icons.bookmark_outline, String? sub}) {
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
                          title,
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

          Widget gap([double h = 14]) => SizedBox(height: h);

          final leftColumn = <Widget>[
            sectionTitle("Basic Information", icon: Icons.badge_outlined),
            gap(10),
            TextFormField(
              controller: _titleController,
              decoration: deco(
                label: "Title",
                hint: "e.g., Software Engineer",
                icon: Icons.title,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? "Please enter the career title"
                  : null,
              textInputAction: TextInputAction.next,
            ),
            gap(),
            DropdownButtonFormField<String>(
              value: _selectedIndustryId,
              isExpanded: true,
              decoration: deco(
                label: "Industry",
                hint: "Select an industry",
                icon: Icons.business_center_outlined,
              ),
              items: ([...INDUSTRIES]..sort((a, b) => a.order.compareTo(b.order)))
                  .map((def) {
                return DropdownMenuItem<String>(
                  value: def.id,
                  child: Row(
                    children: [
                      Icon(def.icon,
                          size: 18, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(def.name, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedIndustryId = v;
                  _selectedIndustryName = industryById(v)?.name;
                });
              },
              validator: (v) =>
              (v == null || v.isEmpty) ? "Please select an industry" : null,
            ),
            gap(18),
            sectionTitle("Skills & Salary", icon: Icons.tips_and_updates_outlined),
            gap(10),
            TextFormField(
              controller: _skillsController,
              decoration: deco(
                label: "Skills (optional)",
                hint: "Comma-separated skills (e.g., Java, SQL, Problem Solving)",
                icon: Icons.lightbulb_outline,
              ),
              textInputAction: TextInputAction.next,
            ),
            gap(),
            TextFormField(
              controller: _salaryController,
              decoration: deco(
                label: "Salary Range",
                hint: "e.g., \$800 - \$1,200 / month",
                icon: Icons.attach_money,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? "Please enter the salary range"
                  : null,
              textInputAction: TextInputAction.next,
            ),
          ];

          final rightColumn = <Widget>[
            sectionTitle("Description",
                icon: Icons.description_outlined,
                sub: "Short overview about this career"),
            gap(10),
            TextFormField(
              controller: _descController,
              decoration: deco(
                label: "Description",
                hint: "Write a concise summary...",
                icon: Icons.notes,
              ),
              maxLines: 7,
              validator: (v) => v == null || v.trim().isEmpty
                  ? "Please provide a description"
                  : null,
            ),
            gap(18),
            sectionTitle("Education Path", icon: Icons.school_outlined),
            gap(10),
            TextFormField(
              controller: _eduController,
              decoration: deco(
                label: "Education Path",
                hint: "e.g., B.Sc. in CS, online courses, bootcamps...",
                icon: Icons.menu_book_outlined,
              ),
              maxLines: 5,
              validator: (v) => v == null || v.trim().isEmpty
                  ? "Please specify the education path"
                  : null,
            ),
          ];



          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withOpacity(0.05),
                  primary.withOpacity(0.02),
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    children: [
                      Container(
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
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      widget.career == null ? Icons.add_circle_outline : Icons.edit_outlined,
                                      color: primary,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.career == null ? "Create a New Career" : "Update Career",
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "Use concise, clear information to help learners discover careers",
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),
                              Divider(height: 24, color: primary.withOpacity(0.18)),
                              const SizedBox(height: 6),

                              if (isWide)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(children: [
                                        ...leftColumn,
                                      ]),
                                    ),
                                    const SizedBox(width: 18),
                                    Expanded(
                                      child: Column(children: [
                                        ...rightColumn,
                                      ]),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    ...leftColumn,
                                    gap(18),
                                    ...rightColumn,
                                  ],
                                ),

                              const SizedBox(height: 22),

                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(Icons.arrow_back),
                                      label: const Text("Back"),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: primary.withOpacity(0.5)),
                                        foregroundColor: primary,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _saveCareer,
                                      icon: const Icon(Icons.save_rounded),
                                      label: const Text("Save"),
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

                      const SizedBox(height: 14),
                      Text(
                        "Tip: Separate multiple skills with commas. Keep descriptions short and scannable.",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
