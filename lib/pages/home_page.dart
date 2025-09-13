import 'package:aspire_edge_404_notfound/pages/home/top_story_section.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildBanner().animate().fadeIn(duration: 600.ms),
          ),
          SliverToBoxAdapter(
            child: _buildStats().animate().slideY(begin: 0.2, duration: 600.ms),
          ),
          SliverToBoxAdapter(
            child: _buildCVTips(
              context,
            ).animate().slideX(begin: -0.2, duration: 600.ms),
          ),
          SliverToBoxAdapter(
            child: _buildInterviewQuestions(
              context,
            ).animate().slideX(begin: 0.2, duration: 600.ms),
          ),
          SliverToBoxAdapter(
            child: _buildBlog(context).animate().fadeIn(duration: 600.ms),
          ),
          SliverToBoxAdapter(
            child: const TopStoriesSection().animate().slideY(
              begin: 0.2,
              duration: 600.ms,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildQuickInterests(
                context,
              ).animate().fadeIn(duration: 600.ms),
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

  Widget _buildBanner() => Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      image: const DecorationImage(
        image: NetworkImage(
          "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757492366/vector-elegant-thin-line-flat-modern-career-and-growing-concept-website-header-banner-elements-layout-presentation-flyer-and-poster-2C6KMWE_yby82r.jpg",
        ),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
      ),
    ),
    child: const Text(
      "Hello !!! \nExplore your career opportunities",
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _buildStats() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Text(
          "Community Achievements",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Iconsax.people,
              label: "Users",
              value: "12K+",
            ),
          ),
          Expanded(
            child: _StatCard(
              icon: Iconsax.briefcase,
              label: "Employed",
              value: "86%",
            ),
          ),
          Expanded(
            child: _StatCard(
              icon: Iconsax.cup,
              label: "Success Stories",
              value: "2.7K+",
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildCVTips(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Text(
          "CV Tips",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      _BlogCard(
        image:
            "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757492366/career-advice-illustration_335657-4661_i6aylr.avif",
        title: "How to Write an Impressive CV in 2025",
        subtitle: "5 steps to make HR notice your application",
        onTap: () => Navigator.pushNamed(context, "/cv_detail"),
      ),
    ],
  );

  Widget _buildInterviewQuestions(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Text(
          "Common Interview Questions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      _QnACard(
        question: "Tell me about yourself?",
        answer:
            "Introduce briefly: education, key experience, and why you fit the role.",
        onTap: () => Navigator.pushNamed(context, "/interview_detail"),
      ),
    ],
  );

  Widget _buildBlog(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Text(
          "Recommended for You",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      _BlogCard(
        image:
            "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757492366/career-advice-abstract-concept-vector-illustration_107173-20083_qdqawl.avif",
        title: "5 Secrets to a Successful Interview",
        subtitle: "Insights from HR experts",
        onTap: () => Navigator.pushNamed(context, "/blog_detail"),
      ),
    ],
  );

  Widget _buildQuickInterests(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Explore by Interests",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _InterestChip(
            label: "Công nghệ 💻",
            onTap: () {
              Navigator.pushNamed(
                context,
                "/industry_intro",
                arguments: {"industry": "Information Technology"},
              );
            },
          ),
          _InterestChip(
            label: "Kinh doanh 📈",
            onTap: () {
              Navigator.pushNamed(
                context,
                "/industry_intro",
                arguments: {"industry": "Business"},
              );
            },
          ),
          _InterestChip(
            label: "Nghệ thuật 🎨",
            onTap: () {
              Navigator.pushNamed(
                context,
                "/industry_intro",
                arguments: {"industry": "Art"},
              );
            },
          ),
          _InterestChip(
            label: "Khoa học 🔬",
            onTap: () {
              Navigator.pushNamed(
                context,
                "/industry_intro",
                arguments: {"industry": "Science"},
              );
            },
          ),
        ],
      ),
    ],
  );

  Widget _buildCTA(BuildContext context) => ElevatedButton(
    onPressed: () => Navigator.pushNamed(context, "/career_quiz"),
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: const Text(
      "Discover Your Path 🚀",
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: Column(
      children: [
        Icon(icon, size: 28, color: Colors.blue),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    ),
  );
}

class _BlogCard extends StatelessWidget {
  final String image, title, subtitle;
  final VoidCallback onTap;
  const _BlogCard({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedNetworkImage(
            imageUrl: image,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _QnACard extends StatelessWidget {
  final String question, answer;
  final VoidCallback onTap;
  const _QnACard({
    required this.question,
    required this.answer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(answer),
      trailing: const Icon(Iconsax.arrow_right_3, size: 18), // ✅ icon thay thế
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
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
