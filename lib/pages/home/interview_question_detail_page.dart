import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

class InterviewQuestionDetailPage extends StatelessWidget {
  const InterviewQuestionDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // dữ liệu mẫu
    const image =
        "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757492366/career-advice-abstract-concept-vector-illustration_107173-20083_qdqawl.avif";
    const question = "Hãy giới thiệu về bản thân?";
    const answer =
        "Bạn nên giới thiệu ngắn gọn: học vấn, kinh nghiệm nổi bật và lý do bạn phù hợp với vị trí. Tránh kể quá dài dòng, tập trung vào điểm mạnh và thành tựu liên quan trực tiếp tới công việc.";
    const exampleAnswers = [
      "Tôi vừa tốt nghiệp ngành CNTT, đã có kinh nghiệm thực tập ReactJS, yêu thích phát triển web và mong muốn gắn bó lâu dài trong lĩnh vực frontend.",
      "Tôi đã làm việc 2 năm trong mảng mobile Flutter, tham gia nhiều dự án team-work, và rất thích môi trường đổi mới sáng tạo.",
      "Tôi từng tham gia nhiều dự án freelance về UI/UX, qua đó tích lũy được kỹ năng giao tiếp với khách hàng và quản lý tiến độ, mong muốn áp dụng tại vị trí chính thức."
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("Chi tiết câu hỏi",
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
                  // Question highlight
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.blue.shade100],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueAccent),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.help_outline,
                            color: Colors.blue, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            question,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),

                  // Suggestion box
                  Text("Gợi ý trả lời",
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: Colors.indigo, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(answer,
                              style: const TextStyle(
                                  fontSize: 15, height: 1.4, color: Colors.black87)),
                        ),
                      ],
                    ),
                  ).animate().slideX(begin: -0.2, duration: 500.ms),
                  const Divider(height: 32),

                  // Example answers
                  Text("Ví dụ trả lời",
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: exampleAnswers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 3,
                        shadowColor: Colors.blue.shade100,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.blue.shade50,
                                child: const Icon(Icons.chat_bubble_outline,
                                    color: Colors.blue, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(exampleAnswers[index],
                                      style: const TextStyle(
                                          fontSize: 14, height: 1.4))),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(
                          duration: 500.ms, delay: (400 + index * 200).ms);
                    },
                  ),
                  const SizedBox(height: 32),

                  // CTA button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, "/career_quiz"),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Thử trả lời ngay 🚀"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ).animate().scale(duration: 400.ms, delay: 800.ms),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
