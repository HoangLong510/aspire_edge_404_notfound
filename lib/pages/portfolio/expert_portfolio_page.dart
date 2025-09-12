import 'package:flutter/material.dart';

class ExpertPortfolioPage extends StatelessWidget {
  const ExpertPortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    const expertName = "Hoàng Gia Huy";
    const avatarUrl =
        "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757492191/z6992939545936_81efd111ee172b5b750549f93fcefdc4_pckfbv.jpg";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Portfolio Chuyên Gia"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(avatarUrl),
            ),
            const SizedBox(height: 16),

            // Tên chuyên gia
            Text(
              expertName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Tiêu đề / Vai trò
            const Text(
              "Chuyên gia Nhân sự & Phát triển sự nghiệp",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const Divider(height: 32),

            // Giới thiệu
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Giới thiệu",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Hoàng Gia Huy có hơn 10 năm kinh nghiệm trong lĩnh vực nhân sự, "
              "đặc biệt là tư vấn định hướng nghề nghiệp, đào tạo kỹ năng phỏng vấn "
              "và hỗ trợ xây dựng lộ trình phát triển sự nghiệp cho hàng ngàn ứng viên.",
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Thành tựu
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Thành tựu nổi bật",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            _AchievementItem(
              icon: Icons.workspace_premium,
              text: "Hơn 5000+ ứng viên được hỗ trợ thành công",
            ),
            _AchievementItem(
              icon: Icons.school,
              text: "Diễn giả tại nhiều hội thảo hướng nghiệp trong và ngoài nước",
            ),
            _AchievementItem(
              icon: Icons.book,
              text: "Tác giả cuốn sách 'Nghệ thuật chinh phục phỏng vấn'",
            ),
            const SizedBox(height: 24),

            // CTA
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Liên hệ chuyên gia: huy.hr@example.com"),
                ));
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.mail),
              label: const Text("Liên hệ chuyên gia"),
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
 