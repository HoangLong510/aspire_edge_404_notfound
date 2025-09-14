import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:iconsax/iconsax.dart';

class CurriculumVitaeTipDetailPage extends StatefulWidget {
  const CurriculumVitaeTipDetailPage({super.key});

  @override
  State<CurriculumVitaeTipDetailPage> createState() =>
      _CurriculumVitaeTipDetailPageState();
}

class _CurriculumVitaeTipDetailPageState
    extends State<CurriculumVitaeTipDetailPage> {
  late final WebViewController _controller;
  bool _isVideoLoading = true;

  final List<Map<String, String>> _tips = const [
    {
      "title": "Use a clean layout and professional fonts",
      "desc":
          "Avoid clutter. Choose fonts like Arial, Calibri, or Times New Roman for readability."
    },
    {
      "title": "Highlight important skills at the top",
      "desc":
          "Place your most relevant technical and soft skills where recruiters see them first."
    },
    {
      "title": "Focus on achievements, not just job duties",
      "desc":
          "Instead of writing 'Responsible for managing team', write 'Led a team of 5 to deliver project 2 weeks ahead of schedule'."
    },
    {
      "title": "Use numbers to prove your accomplishments",
      "desc":
          "Recruiters love data: 'Increased sales by 25%' is stronger than 'Improved sales'."
    },
    {
      "title": "Tailor your Curriculum Vitae to each job you apply for",
      "desc":
          "Analyze the job description and adapt your Curriculum Vitae to highlight the most relevant skills."
    },
    {
      "title": "Keep it short, ideally 1–2 pages",
      "desc":
          "HR typically spends less than 10 seconds scanning a Curriculum Vitae. Conciseness is key."
    },
  ];

  final List<String> _mistakes = const [
    "Using unprofessional email addresses",
    "Adding irrelevant work experiences",
    "Too much text without white space",
    "Using generic phrases like 'hard-working'",
    "Typos or grammar mistakes",
  ];

  final List<Map<String, String>> _resources = const [
    {
      "title": "Canva Curriculum Vitae Templates",
      "link": "https://www.canva.com/resumes/templates/"
    },
    {
      "title": "Zety Resume Builder",
      "link": "https://zety.com/resume-builder"
    },
    {
      "title": "Book: What Color is Your Parachute?",
      "link": "https://www.parachutebook.com/"
    },
  ];

  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isVideoLoading = true),
          onPageFinished: (_) => setState(() => _isVideoLoading = false),
        ),
      )
      ..loadRequest(
        Uri.parse("https://www.youtube.com/embed/rM4lDSxwW_g"),
      );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTips = _tips
        .where((tip) =>
            tip["title"]!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            tip["desc"]!.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Curriculum Vitae Writing Guide"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome to the Curriculum Vitae Masterclass",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your Curriculum Vitae is the first impression you give to employers. "
              "This guide will help you structure it professionally, "
              "avoid mistakes, and land more interviews.",
              style: TextStyle(color: Colors.black87, fontSize: 15),
            ),
            const SizedBox(height: 20),
            Stack(
              children: [
                SizedBox(
                  height: 220,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: WebViewWidget(controller: _controller),
                  ),
                ),
                if (_isVideoLoading)
                  const Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.blue),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: "Search Curriculum Vitae tips...",
                prefixIcon: const Icon(Iconsax.search_normal),
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
            const Text(
              "List of Curriculum Vitae Tips",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...filteredTips.map(
              (tip) => Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  title: Text(
                    tip["title"]!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        tip["desc"]!,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Common Mistakes to Avoid",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ..._mistakes.map(
              (m) => Card(
                color: Colors.red.shade50,
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(m),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Extra Resources",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ..._resources.map(
              (r) => Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(r["title"]!),
                  subtitle: Text(r["link"]!),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Open: ${r["link"]}"),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
