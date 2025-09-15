import 'package:aspire_edge_404_notfound/pages/home/top_story_section.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lottie/lottie.dart';

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
            child: _buildCurriculumVitaeTips(
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
          SliverFillRemaining(hasScrollBody: false, child: _buildCTA(context)),
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

  Widget _buildStats() {
    final Map<String, String> _tierOptions = {
      'student': 'Student',
      'postgraduate': 'Undergraduates/Postgraduates',
      'professionals': 'Professionals',
    };
    final PageController _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      int currentPage = 0;
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 2));
        if (!_pageController.hasClients) return false;
        currentPage = (currentPage + 1) % _tierOptions.length;
        _pageController.animateToPage(
          currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        return true;
      });
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text(
            "Community Achievements",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection("Users").snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;
            final counts = <String, int>{};
            for (final key in _tierOptions.keys) {
              counts[key] = docs.where((d) => d["Tier"] == key).length;
            }
            return SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Iconsax.people,
                      label: "Users",
                      value: "${docs.length}",
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _tierOptions.length,
                      itemBuilder: (context, index) {
                        final key = _tierOptions.keys.elementAt(index);
                        final label = _tierOptions[key]!;
                        return _StatCard(
                          icon: Iconsax.briefcase,
                          label: label,
                          value: "${counts[key] ?? 0}",
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("Stories")
                          .where("status", isEqualTo: "approved")
                          .snapshots(),
                      builder: (context, storySnap) {
                        if (!storySnap.hasData) {
                          return const _StatCard(
                            icon: Iconsax.cup,
                            label: "Success Stories",
                            value: "...",
                          );
                        }
                        return _StatCard(
                          icon: Iconsax.cup,
                          label: "Success Stories",
                          value: "${storySnap.data!.size}",
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCurriculumVitaeTips(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Text(
          "Curriculum Vitae Tips",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      Card(
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, "/cv_detail"),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Center(
                    child: Lottie.asset(
                      "assets/lottie/job_hunting.json",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "How to Write an Impressive Curriculum Vitae in 2025",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "5 steps to make HR notice your application",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.pushNamed(context, "/interview_detail"),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                SizedBox(
                  height: 60,
                  width: 60,
                  child: Lottie.asset(
                    "assets/lottie/question.json",
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tell me about yourself?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Introduce briefly: education, key experience, and why you fit the role.",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Iconsax.arrow_right_3, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildBlog(BuildContext context) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final todayQuery = FirebaseFirestore.instance
        .collection("Blogs")
        .where("CreatedAt", isGreaterThanOrEqualTo: startOfDay)
        .orderBy("CreatedAt", descending: true)
        .limit(1);
    final fallbackQuery = FirebaseFirestore.instance
        .collection("Blogs")
        .orderBy("CreatedAt", descending: true)
        .limit(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text(
            "Recommended for You",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: todayQuery.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              return StreamBuilder<QuerySnapshot>(
                stream: fallbackQuery.snapshots(),
                builder: (context, fbSnap) {
                  if (!fbSnap.hasData || fbSnap.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text("No blogs available."),
                    );
                  }
                  return _buildBlogCard(context, fbSnap.data!.docs.first);
                },
              );
            }
            return _buildBlogCard(context, snapshot.data!.docs.first);
          },
        ),
      ],
    );
  }

  Widget _buildBlogCard(BuildContext context, DocumentSnapshot doc) {
    final blogId = doc.id;
    final data = doc.data() as Map<String, dynamic>;
    final title = data["Title"] ?? "Untitled";
    final desc = data["Description"] ?? "";
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          "/blog_detail",
          arguments: {"blogId": blogId},
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: Center(
                  child: Lottie.asset(
                    "assets/lottie/interview.json",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
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
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            label: "Technology",
            icon: Iconsax.cpu,
            onTap: () => Navigator.pushNamed(
              context,
              "/industry_intro",
              arguments: {"industry": "Information Technology"},
            ),
          ),
          _InterestChip(
            label: "Healthcare",
            icon: Iconsax.heart,
            onTap: () => Navigator.pushNamed(
              context,
              "/industry_intro",
              arguments: {"industry": "Healthcare"},
            ),
          ),
          _InterestChip(
            label: "Art",
            icon: Iconsax.paintbucket,
            onTap: () => Navigator.pushNamed(
              context,
              "/industry_intro",
              arguments: {"industry": "Art"},
            ),
          ),
          _InterestChip(
            label: "Science",
            icon: Iconsax.coffee,
            onTap: () => Navigator.pushNamed(
              context,
              "/industry_intro",
              arguments: {"industry": "Science"},
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildCTA(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(32, 12, 32, 24),
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, "/login"),
          icon: const Icon(Iconsax.login, size: 22),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          label: const Text(
            "Login to Discover Your Path",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("Users")
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final hasCareerMatches =
            data?["CareerMatches"] != null &&
            (data?["CareerMatches"] as List).isNotEmpty;
        final buttonText = hasCareerMatches
            ? "View Your Career Path"
            : "Discover Your Path";
        final route = hasCareerMatches ? "/career_path" : "/career_quiz";
        return Padding(
          padding: const EdgeInsets.fromLTRB(32, 12, 32, 24),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, route),
            icon: const Icon(Iconsax.send_2, size: 22),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            label: Text(
              buttonText,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: Colors.blue),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _InterestChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        avatar: Icon(icon, size: 18, color: Colors.blue),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        backgroundColor: Colors.blue.shade50,
      ),
    );
  }
}
