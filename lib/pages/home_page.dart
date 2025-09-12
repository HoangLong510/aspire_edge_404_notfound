import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildBanner().animate().fadeIn(duration: 600.ms)),
          SliverToBoxAdapter(child: _buildStats().animate().slideY(begin: 0.2, duration: 600.ms)),
          SliverToBoxAdapter(child: _buildCVTips(context).animate().slideX(begin: -0.2, duration: 600.ms)),
          SliverToBoxAdapter(child: _buildInterviewQuestions(context).animate().slideX(begin: 0.2, duration: 600.ms)),
          SliverToBoxAdapter(child: _buildBlog(context).animate().fadeIn(duration: 600.ms)),
          SliverToBoxAdapter(child: _buildFeedback().animate().slideY(begin: 0.2, duration: 600.ms)),

          // Quick Interests Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildQuickInterests(context).animate().fadeIn(duration: 600.ms),
            ),
          ),

          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: _buildCTA(context)),
          ),
        ],
      ),
    );
  }

  // Banner
  Widget _buildBanner() => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: NetworkImage("https://res.cloudinary.com/daxpkqhmd/image/upload/v1757492366/vector-elegant-thin-line-flat-modern-career-and-growing-concept-website-header-banner-elements-layout-presentation-flyer-and-poster-2C6KMWE_yby82r.jpg"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
          ),
        ),
        child: const Text(
          "Xin chào 👋\nKhám phá cơ hội nghề nghiệp của bạn",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );

  // Stats
  Widget _buildStats() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("Thành tựu cộng đồng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatCard(icon: Icons.people, label: "Người dùng", value: "12K+"),
              _StatCard(icon: Icons.work, label: "Có việc làm", value: "86%"),
              _StatCard(icon: Icons.emoji_events, label: "Thành công", value: "2.7K+"),
            ],
          ),
        ],
      );

  // CV Tips
  Widget _buildCVTips(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Mẹo CV nổi bật", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _BlogCard(
            image: "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757492366/career-advice-illustration_335657-4661_i6aylr.avif",
            title: "Cách viết CV ấn tượng trong 2025",
            subtitle: "5 bước để HR không bỏ qua hồ sơ của bạn",
            onTap: () => Navigator.pushNamed(context, "/cv_detail"),
          ),
        ],
      );

  // Interview Questions
  Widget _buildInterviewQuestions(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Câu hỏi phỏng vấn thường gặp", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _QnACard(
            question: "Hãy giới thiệu về bản thân?",
            answer: "Giới thiệu ngắn gọn: học vấn, kinh nghiệm, lý do phù hợp.",
            onTap: () => Navigator.pushNamed(context, "/interview_detail"),
          ),
        ],
      );

  // Blog
  Widget _buildBlog(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Gợi ý cho bạn", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _BlogCard(
            image: "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757492366/career-advice-abstract-concept-vector-illustration_107173-20083_qdqawl.avif",
            title: "5 bí quyết phỏng vấn thành công",
            subtitle: "Chia sẻ từ chuyên gia nhân sự",
            onTap: () => Navigator.pushNamed(context, "/blog_detail"),
          ),
        ],
      );

  // Feedback
  Widget _buildFeedback() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Câu chuyện thành công", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: PageView(
              children: const [
                _FeedbackCard(
                  avatar: "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757490262/samples/woman-on-a-football-field.jpg",
                  name: "Minh Anh",
                  story: "Từ sinh viên IT đến lập trình viên Google 🌍",
                ),
                _FeedbackCard(
                  avatar: "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757490263/samples/upscale-face-1.jpg",
                  name: "Thu Hà",
                  story: "Ứng dụng đã giúp mình có định hướng nghề nghiệp rõ ràng hơn 💼",
                ),
              ],
            ),
          ),
        ],
      );

  // Quick Interests
  Widget _buildQuickInterests(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Khám phá theo sở thích", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InterestChip(label: "Công nghệ 💻", onTap: () {
                Navigator.pushNamed(context, "/industry_intro",
                    arguments: {"industry": "Information Technology"});
              }),
              _InterestChip(label: "Y tế 📈", onTap: () {
                Navigator.pushNamed(context, "/industry_intro",
                    arguments: {"industry":"Healthcare"});
              }),
              _InterestChip(label: "Nghệ thuật 🎨", onTap: () {
                Navigator.pushNamed(context, "/industry_intro",
                    arguments: {"industry": "Art"});
              }),
              _InterestChip(label: "Khoa học 🔬", onTap: () {
                Navigator.pushNamed(context, "/industry_intro",
                    arguments: {"industry": "Science"});
              }),
            ],
          )
        ],
      );

  // CTA
  Widget _buildCTA(BuildContext context) => ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, "/career_quiz"),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text("Khám phá con đường của bạn 🚀", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );
}

// ============= Sub Widgets =============

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, size: 32, color: Colors.blue),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: TextStyle(color: Colors.grey)),
        ],
      );
}

class _BlogCard extends StatelessWidget {
  final String image, title, subtitle;
  final VoidCallback onTap;
  const _BlogCard({required this.image, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CachedNetworkImage(imageUrl: image, height: 150, width: double.infinity, fit: BoxFit.cover),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600])),
                ]),
              )
            ],
          ),
        ),
      );
}

class _QnACard extends StatelessWidget {
  final String question, answer;
  final VoidCallback onTap;
  const _QnACard({required this.question, required this.answer, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(answer),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      );
}

class _FeedbackCard extends StatelessWidget {
  final String avatar, name, story;
  const _FeedbackCard({
    required this.avatar,
    required this.name,
    required this.story,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundImage: NetworkImage(avatar), radius: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            story,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _InterestChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        backgroundColor: Colors.blue.shade50,
      ),
    );
  }
}
