import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BlogDetailPage extends StatelessWidget {
  const BlogDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    const title = "5 bí quyết phỏng vấn thành công";
    const subtitle = "Chia sẻ từ chuyên gia nhân sự";
    const image =
        "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757492366/career-advice-abstract-concept-vector-illustration_107173-20083_qdqawl.avif";
    const content =
        "Trong bài viết này, chúng ta sẽ tìm hiểu 5 bí quyết để vượt qua vòng phỏng vấn:\n\n"
        "1️⃣ Chuẩn bị kỹ thông tin công ty và vị trí.\n\n"
        "2️⃣ Luyện tập trả lời các câu hỏi phổ biến.\n\n"
        "3️⃣ Ăn mặc chuyên nghiệp, phù hợp.\n\n"
        "4️⃣ Giữ sự tự tin, giao tiếp rõ ràng.\n\n"
        "5️⃣ Đặt câu hỏi ngược lại để thể hiện sự quan tâm.\n\n"
        "Thực hiện tốt 5 bí quyết này sẽ giúp bạn tăng đáng kể cơ hội thành công trong buổi phỏng vấn.";

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("Chi tiết Blog",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              background: CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                color: Colors.black45,
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold))
                      .animate()
                      .fadeIn(duration: 500.ms),
                  const SizedBox(height: 8),
                  Text(subtitle,
                          style: TextStyle(
                              fontSize: 15, color: Colors.grey[700]))
                      .animate()
                      .slideX(begin: -0.2, duration: 500.ms),
                  const Divider(height: 32),
                  Text(content,
                          style: const TextStyle(fontSize: 16, height: 1.5))
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 200.ms),
                  const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, "/career_quiz"),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Tham gia Quiz ngay 🚀"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ).animate().scale(duration: 400.ms, delay: 400.ms),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
