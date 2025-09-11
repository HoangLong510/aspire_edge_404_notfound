import 'package:flutter/material.dart';

class CVTipDetailPage extends StatelessWidget {
  const CVTipDetailPage({super.key});

  // dữ liệu tĩnh (mock data)
  final List<String> _tips = const [
    "Sử dụng layout gọn gàng, font chữ chuyên nghiệp.",
    "Đưa kỹ năng quan trọng lên đầu trang.",
    "Tập trung vào thành tựu, không chỉ mô tả công việc.",
    "Sử dụng số liệu để minh chứng thành tích.",
    "Tùy chỉnh CV theo từng công việc bạn ứng tuyển.",
    "Không quá dài, chỉ nên từ 1–2 trang.",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mẹo CV chi tiết")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Danh sách mẹo CV",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ..._tips.map((tip) => ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(tip),
                )),
          ],
        ),
      ),
    );
  }
}
