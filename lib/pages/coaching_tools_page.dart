import 'package:flutter/material.dart';

class CoachingToolsPage extends StatefulWidget {
  const CoachingToolsPage({super.key});

  @override
  State<CoachingToolsPage> createState() => _CoachingToolsPageState();
}

class _CoachingToolsPageState extends State<CoachingToolsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Coaching Tools"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // CV Builder Section
          const Text(
            "CV Builder Tips",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _TipCard(
            icon: Icons.description_outlined,
            title: "Use a clear format",
            description: "Keep your CV structured with clear headings and bullet points.",
          ),
          _TipCard(
            icon: Icons.check_circle_outline,
            title: "Highlight achievements",
            description: "Focus on measurable results instead of just listing tasks.",
          ),
          _TipCard(
            icon: Icons.language_outlined,
            title: "Tailor your CV",
            description: "Adjust your CV to fit each job application and industry.",
          ),

          const SizedBox(height: 24),

          // Interview Preparation Section
          const Text(
            "Interview Preparation",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _QnACard(
            question: "Tell me about yourself.",
            answer: "Introduce briefly: education, key experience, and why you fit the role.",
          ),
          _QnACard(
            question: "What are your strengths and weaknesses?",
            answer: "Highlight 2-3 strengths with examples. For weaknesses, mention what you are improving.",
          ),
          _QnACard(
            question: "Why do you want to work here?",
            answer: "Show that you researched the company and explain how your goals align with theirs.",
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
      ),
    );
  }
}

class _QnACard extends StatelessWidget {
  final String question;
  final String answer;

  const _QnACard({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.question_answer_outlined),
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(answer, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }
}
