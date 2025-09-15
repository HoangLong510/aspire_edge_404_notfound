import 'package:flutter/material.dart';

class ExpertPortfolioPage extends StatelessWidget {
  const ExpertPortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    const expertName = "Hoang Gia Huy";
    const avatarUrl =
        "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757492191/z6992939545936_81efd111ee172b5b750549f93fcefdc4_pckfbv.jpg";

    return Scaffold(
      appBar: AppBar(title: const Text("Expert Portfolio"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(radius: 60, backgroundImage: NetworkImage(avatarUrl)),
            const SizedBox(height: 16),
            Text(
              expertName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "HR & Career Development Expert",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const Divider(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Introduction",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Hoang Gia Huy has over 10 years of experience in human resources, "
              "specializing in career counseling, interview training, and "
              "helping thousands of candidates build professional career paths.",
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Key Achievements",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            const _AchievementItem(
              icon: Icons.workspace_premium,
              text: "Supported over 5000+ candidates successfully",
            ),
            const _AchievementItem(
              icon: Icons.school,
              text: "Speaker at various career workshops worldwide",
            ),
            const _AchievementItem(
              icon: Icons.book,
              text: "Author of the book 'The Art of Mastering Interviews'",
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Contact expert: huy.hr@example.com"),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.mail),
              label: const Text("Contact Expert"),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _AchievementItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}
