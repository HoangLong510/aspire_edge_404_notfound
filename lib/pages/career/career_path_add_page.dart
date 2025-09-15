import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CareerPathAddPage extends StatefulWidget {
  final String careerId;
  final DocumentSnapshot? path;

  const CareerPathAddPage({super.key, required this.careerId, this.path});

  @override
  State<CareerPathAddPage> createState() => _CareerPathAddPageState();
}

class _CareerPathAddPageState extends State<CareerPathAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _levelNameController = TextEditingController();
  final _salaryController = TextEditingController();
  final _descController = TextEditingController();
  final _skillsController = TextEditingController();

  int _nextOrder = 1;
  String? _careerTitle;
  bool _loading = false;
  bool get _isEditing => widget.path != null;

  @override
  void initState() {
    super.initState();
    _loadCareerInfo();
    if (_isEditing) {
      _prefillData();
    } else {
      _loadNextOrder();
    }
  }

  @override
  void dispose() {
    _levelNameController.dispose();
    _salaryController.dispose();
    _descController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  List<String> _toSkillsArray(String raw) => raw
      .split(RegExp(r'[,\n]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<void> _loadCareerInfo() async {
    final doc = await FirebaseFirestore.instance
        .collection("CareerBank")
        .doc(widget.careerId)
        .get();

    if (doc.exists) {
      setState(() {
        _careerTitle = doc["Title"];
      });
    }
  }

  void _prefillData() {
    final data = widget.path!.data() as Map<String, dynamic>;
    _levelNameController.text = (data['Level_Name'] ?? '').toString();
    _salaryController.text = (data['Salary_Range'] ?? '').toString();
    _descController.text = (data['Description'] ?? '').toString();
    final skills = data['Skills'];
    if (skills is List) {
      _skillsController.text = skills.join(', ');
    } else if (skills is String) {
      _skillsController.text = skills;
    }
    _nextOrder = data['Level_Order'] ?? 1;
  }

  Future<void> _loadNextOrder() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("CareerBank")
        .doc(widget.careerId)
        .collection("CareerPaths")
        .orderBy("Level_Order")
        .get();

    int next = 1;
    for (var doc in snapshot.docs) {
      final current = doc["Level_Order"] as int;
      if (current == next) {
        next++;
      } else {
        break;
      }
    }

    setState(() {
      _nextOrder = next;
    });
  }

  Future<void> _savePath() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final data = {
      "Level_Name": _levelNameController.text.trim(),
      "Level_Order": _nextOrder,
      "Salary_Range": _salaryController.text.trim(),
      "Description": _descController.text.trim(),
      "Skills": _toSkillsArray(_skillsController.text),
      "updatedAt": FieldValue.serverTimestamp(),
    };

    final colRef = FirebaseFirestore.instance
        .collection("CareerBank")
        .doc(widget.careerId)
        .collection("CareerPaths");

    if (_isEditing) {
      await colRef.doc(widget.path!.id).update(data);
    } else {
      await colRef.add(data);
      _nextOrder++;
    }

    setState(() => _loading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? "Route updated" : "Route added")),
      );
      if (_isEditing) {
        Navigator.pop(context);
      } else {
        _levelNameController.clear();
        _salaryController.clear();
        _descController.clear();
        _skillsController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isEditing = _isEditing;

    return Scaffold(
      appBar: AppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          InputDecoration deco(String label, {String? hint, IconData? icon}) {
            return InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon: icon != null ? Icon(icon, color: primary) : null,
              filled: true,
              fillColor: primary.withOpacity(0.04),
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
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
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primary.withOpacity(0.18)),
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
                                isEditing ? Icons.edit : Icons.add_chart,
                                color: primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEditing
                                        ? "Edit Level $_nextOrder"
                                        : "Add Level $_nextOrder",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Enter information briefly and clearly",
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primary.withOpacity(0.18)),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.07),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              if (_careerTitle != null) ...[
                                Row(
                                  children: [
                                    Icon(
                                      Icons.work_outline,
                                      size: 18,
                                      color: primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Career: $_careerTitle",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Divider(
                                  height: 24,
                                  color: primary.withOpacity(0.16),
                                ),
                                const SizedBox(height: 6),
                              ],
                              if (isWide)
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _levelNameController,
                                        decoration: deco(
                                          "Level Name",
                                          hint: "e.g., Resident Doctor",
                                          icon: Icons.flag,
                                        ),
                                        validator: (v) =>
                                            v == null || v.trim().isEmpty
                                            ? "Enter the level name"
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _salaryController,
                                        decoration: deco(
                                          "Salary Range",
                                          hint: "e.g., \$50,000 - \$70,000",
                                          icon: Icons.attach_money,
                                        ),
                                        validator: (v) =>
                                            v == null || v.trim().isEmpty
                                            ? "Enter salary"
                                            : null,
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                TextFormField(
                                  controller: _levelNameController,
                                  decoration: deco(
                                    "Level Name",
                                    hint: "e.g., Resident Doctor",
                                    icon: Icons.flag,
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? "Enter the level name"
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _salaryController,
                                  decoration: deco(
                                    "Salary Range",
                                    hint: "e.g., \$50,000 - \$70,000",
                                    icon: Icons.attach_money,
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? "Enter salary"
                                      : null,
                                ),
                              ],
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _descController,
                                decoration: deco(
                                  "Description",
                                  hint: "Briefly describe this stage",
                                  icon: Icons.description_outlined,
                                ),
                                maxLines: 5,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? "Enter a description"
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _skillsController,
                                decoration: deco(
                                  "Skills (optional)",
                                  hint:
                                      "Comma-separated: Teamwork, Clinical Skills, Communication",
                                  icon: Icons.tips_and_updates_outlined,
                                ),
                              ),
                              const SizedBox(height: 18),
                              if (_loading)
                                const CircularProgressIndicator()
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _savePath,
                                        icon: Icon(
                                          isEditing ? Icons.save : Icons.add,
                                        ),
                                        label: Text(
                                          isEditing
                                              ? "Save changes"
                                              : "Add & continue",
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: primary.withOpacity(0.4),
                                          ),
                                          foregroundColor: primary,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Text("cancel"),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Tip: Separate multiple skills with commas. Write short, concise descriptions.",
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
