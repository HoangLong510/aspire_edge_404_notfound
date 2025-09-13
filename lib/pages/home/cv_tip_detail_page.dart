import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CVTipDetailPage extends StatefulWidget {
  const CVTipDetailPage({super.key});

  @override
  State<CVTipDetailPage> createState() => _CVTipDetailPageState();
}

class _CVTipDetailPageState extends State<CVTipDetailPage> {
  late final WebViewController _controller;

  final List<String> _tips = const [
    "Use a clean layout and professional fonts.",
    "Highlight important skills at the top.",
    "Focus on achievements, not just job duties.",
    "Use numbers to prove your accomplishments.",
    "Tailor your CV to each job you apply for.",
    "Keep it short, ideally 1–2 pages.",
  ];

  String _searchQuery = "";

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse("https://www.youtube.com/embed/rM4lDSxwW_g"), // ✅ video embed link
      );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTips = _tips
        .where((tip) =>
            tip.toLowerCase().contains(_searchQuery.toLowerCase().trim()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("📄 CV Writing Tips"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎥 Video embedded via WebView
            SizedBox(
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: WebViewWidget(controller: _controller),
              ),
            ),
            const SizedBox(height: 20),

            // 🔍 Search bar
            TextField(
              decoration: InputDecoration(
                hintText: "Search CV tips...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
            const SizedBox(height: 20),

            Text(
              "📌 List of CV Tips",
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // List tips
            ...filteredTips.map((tip) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading:
                        const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(tip),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
