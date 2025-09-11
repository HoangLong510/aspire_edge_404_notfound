import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CareerPathAddPage extends StatefulWidget {
  final String careerId;

  const CareerPathAddPage({super.key, required this.careerId});

  @override
  State<CareerPathAddPage> createState() => _CareerPathAddPageState();
}

class _CareerPathAddPageState extends State<CareerPathAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _levelNameController = TextEditingController();
  final _salaryController = TextEditingController();
  final _descController = TextEditingController();

  int _nextOrder = 1;
  String? _careerTitle;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCareerInfo();
    _loadNextOrder();
  }

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

  Future<void> _loadNextOrder() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("CareerBank")
        .doc(widget.careerId)
        .collection("CareerPaths")
        .orderBy("Level_Order")
        .get();

    // Mặc định nếu chưa có thì level đầu tiên là 1
    int next = 1;

    for (var doc in snapshot.docs) {
      final current = doc["Level_Order"] as int;
      if (current == next) {
        next++; // nếu trùng thì tăng tiếp
      } else {
        break; // gặp khoảng trống thì dừng
      }
    }

    _nextOrder = next;
    setState(() {});
  }

  Future<void> _addPath() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final data = {
      "Level_Name": _levelNameController.text.trim(),
      "Level_Order": _nextOrder,
      "Salary_Range": _salaryController.text.trim(),
      "Description": _descController.text.trim(),
    };

    await FirebaseFirestore.instance
        .collection("CareerBank")
        .doc(widget.careerId)
        .collection("CareerPaths")
        .add(data);

    setState(() {
      _nextOrder++;
      _levelNameController.clear();
      _salaryController.clear();
      _descController.clear();
      _loading = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Đã thêm lộ trình")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _careerTitle != null
              ? "Thêm lộ trình - $_careerTitle"
              : "Thêm lộ trình",
        ),
      ),
      // ============ NEW BODY (UI only) for CareerPathAddPage ============
      body: LayoutBuilder(
        builder: (context, constraints) {
          final primary = Theme.of(context).primaryColor;
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
                      // Header card
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
                                Icons.add_chart,
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
                                    _careerTitle != null
                                        ? "Thêm lộ trình - $_careerTitle"
                                        : "Thêm lộ trình",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Đang thêm Level $_nextOrder • Nhập thông tin ngắn gọn, rõ ràng",
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

                      // Form card
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
                                      "Nghề: $_careerTitle",
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

                              // Grid inputs (responsive)
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
                                        validator: (v) => v == null || v.isEmpty
                                            ? "Nhập tên level"
                                            : null,
                                        textInputAction: TextInputAction.next,
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
                                        textInputAction: TextInputAction.next,
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
                                  validator: (v) => v == null || v.isEmpty
                                      ? "Nhập tên level"
                                      : null,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _salaryController,
                                  decoration: deco(
                                    "Salary Range",
                                    hint: "e.g., \$50,000 - \$70,000",
                                    icon: Icons.attach_money,
                                  ),
                                  textInputAction: TextInputAction.next,
                                ),
                              ],

                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _descController,
                                decoration: deco(
                                  "Description",
                                  hint: "Mô tả ngắn gọn giai đoạn này",
                                  icon: Icons.description_outlined,
                                ),
                                maxLines: 5,
                              ),

                              const SizedBox(height: 12),
                              // Skills (UI only; nếu muốn lưu hãy thêm 1 dòng ở _addPath)
                              TextFormField(
                                // Tạo thêm controller tạm (UI only) — không ảnh hưởng logic cũ
                                // Bạn có thể tạo controller riêng nếu muốn dùng nhiều nơi.
                                // Ở đây dùng TextEditingController tạm qua TextEditingController() cho gọn.
                                controller: TextEditingController(),
                                decoration: deco(
                                  "Skills (optional)",
                                  hint:
                                      "Comma-separated: Teamwork, Clinical Skills, Communication",
                                  icon: Icons.tips_and_updates_outlined,
                                ),
                              ),

                              const SizedBox(height: 18),
                              if (_loading) const CircularProgressIndicator(),
                              if (!_loading)
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _addPath,
                                        icon: const Icon(Icons.add),
                                        label: const Text("Thêm & tiếp tục"),
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
                                        child: const Text("Xong"),
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
                        "Tip: Tách nhiều kỹ năng bằng dấu phẩy. Viết mô tả ngắn, súc tích.",
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
      // ============ END NEW BODY ============
    );
  }
}
