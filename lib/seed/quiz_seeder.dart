import 'package:cloud_firestore/cloud_firestore.dart';

const Map<String, dynamic> kDefaultOptions = {
  'A': {'Text': 'Strongly agree'},
  'B': {'Text': 'Agree'},
  'C': {'Text': 'Not sure'},
  'D': {'Text': 'Disagree'},
};

Map<String, List<String>> loadSeedQuestions() {
  return {
    'student': [
      'I enjoy solving logical puzzles.',
      'I like working on group projects at school.',
      'I feel excited about building or creating things.',
      'I’m curious about how technology works.',
      'I enjoy presenting ideas to others.',
      'I care about helping people solve real-life problems.',
      'I prefer subjects with clear right/wrong answers.',
      'I like drawing, design, or visual creativity.',
      'I’m patient when doing research or experiments.',
      'I enjoy planning school events or activities.',
    ],
    'postgraduate': [
      'I enjoy analyzing complex problems with multiple constraints.',
      'I feel confident presenting research findings.',
      'I like mentoring juniors or peers.',
      'I’m interested in the product development lifecycle.',
      'I enjoy designing experiments and testing hypotheses.',
      'I follow industry trends in my field.',
      'I like turning user needs into specifications.',
      'I’m comfortable with data analysis and visualization.',
      'I enjoy collaborating with cross-functional teams.',
      'I’m interested in startups or entrepreneurship.',
    ],
    'professionals': [
      'I enjoy leading teams to deliver outcomes.',
      'I’m driven by measurable business impact.',
      'I like negotiating with stakeholders.',
      'I’m comfortable with strategic planning.',
      'I enjoy building long-term client relationships.',
      'I value compliance, risk, and governance.',
      'I like creating standards and best practices.',
      'I enjoy allocating resources across projects.',
      'I’m comfortable analyzing P&L or budgets.',
      'I like designing KPIs and dashboards.',
    ],
  };
}

Map<String, dynamic> _buildDoc(String text, String tier) {
  return {
    'Text': text,
    'Tier': tier,
    'CreatedAt': Timestamp.now(),
    'Options': kDefaultOptions,
  };
}

class SeedResult {
  final int totalInserted;
  final Map<String, int> insertedPerTier;
  const SeedResult({
    required this.totalInserted,
    required this.insertedPerTier,
  });

  @override
  String toString() =>
      'Inserted: $totalInserted (student: ${insertedPerTier['student'] ?? 0}, postgraduate: ${insertedPerTier['postgraduate'] ?? 0}, professionals: ${insertedPerTier['professionals'] ?? 0})';
}

Future<SeedResult> seedQuestions({bool force = false}) async {
  final col = FirebaseFirestore.instance.collection('Questions');
  final summary = <String, int>{};
  final questionsByTier = loadSeedQuestions();

  for (final entry in questionsByTier.entries) {
    final tier = entry.key;
    final texts = entry.value;

    final existingSnap = await col.where('Tier', isEqualTo: tier).get();
    final existingTexts = existingSnap.docs
        .map((d) => (d.data()['Text'] ?? '').toString().trim())
        .toSet();

    int adds = 0;
    var batch = FirebaseFirestore.instance.batch();
    int inBatch = 0;

    for (final q in texts) {
      final already = existingTexts.contains(q.trim());
      if (!force && already) continue;

      batch.set(col.doc(), _buildDoc(q, tier));
      adds++;
      inBatch++;

      if (inBatch >= 450) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        inBatch = 0;
      }
    }

    if (inBatch > 0) {
      await batch.commit();
    }

    summary[tier] = adds;
  }

  final total = summary.values.fold<int>(0, (a, b) => a + b);
  return SeedResult(totalInserted: total, insertedPerTier: summary);
}