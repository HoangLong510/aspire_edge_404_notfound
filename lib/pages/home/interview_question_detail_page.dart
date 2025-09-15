import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

class InterviewQuestionDetailPage extends StatelessWidget {
  const InterviewQuestionDetailPage({super.key});

  final List<Map<String, dynamic>> topics = const [
    {
      "topic": "Self-Introduction",
      "question": "Can you tell me about yourself?",
      "suggestion":
          "Give a brief overview: education, relevant experience, and why you fit the role. Keep it short and focused on highlights.",
      "examples": [
        "I recently graduated in Computer Science, completed an internship in ReactJS, and I am passionate about web development.",
        "I have two years of experience in mobile app development using Flutter and enjoy working in innovative teams.",
        "I worked as a freelance UI/UX designer, gaining experience in client communication and project management.",
      ],
    },
    {
      "topic": "Strengths",
      "question": "What are your key strengths?",
      "suggestion":
          "Focus on 2–3 strengths that are directly relevant to the job. Provide short examples.",
      "examples": [
        "I am detail-oriented and have strong problem-solving skills. For example, I optimized a database query reducing load time by 40%.",
        "I am an effective communicator, which helps me work smoothly with cross-functional teams.",
      ],
    },
    {
      "topic": "Weaknesses",
      "question": "What is your biggest weakness?",
      "suggestion":
          "Choose a real weakness, but explain how you are actively improving it. Avoid clichés like 'perfectionist'.",
      "examples": [
        "I used to struggle with public speaking, but I joined a Toastmasters club to build my confidence.",
        "I sometimes take too many responsibilities, but I now prioritize tasks and delegate when needed.",
      ],
    },
    {
      "topic": "Future Goals",
      "question": "Where do you see yourself in 5 years?",
      "suggestion":
          "Show ambition but align with the company’s vision. Highlight learning and growth rather than a specific job title.",
      "examples": [
        "I hope to become a senior software engineer leading a small team while continuing to expand my technical expertise.",
        "I see myself growing into a leadership role where I can mentor junior developers.",
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    const bannerImage =
        "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757492366/career-advice-abstract-concept-vector-illustration_107173-20083_qdqawl.avif";

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                "Interview Q&A Guide",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: CachedNetworkImage(
                imageUrl: bannerImage,
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
                children: [
                  ...topics.map(
                    (topic) => Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: _buildTopicCard(context, topic),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, "/career_quiz"),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Practice Your Answers"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ).animate().scale(duration: 400.ms, delay: 800.ms),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(BuildContext context, Map<String, dynamic> topic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          topic['topic'],
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
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
              const Icon(Icons.help_outline, color: Colors.blue, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  topic['question'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_outline, color: Colors.indigo, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                topic['suggestion'],
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ],
        ),
        const Divider(height: 24),
        Text("Example Answers", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...List.generate(topic['examples'].length, (index) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shadowColor: Colors.blue.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.blue,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      topic['examples'][index],
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: (300 + index * 150).ms);
        }),
      ],
    );
  }
}
