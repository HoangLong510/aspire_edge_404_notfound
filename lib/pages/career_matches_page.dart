import 'dart:math';
import 'package:aspire_edge_404_notfound/pages/career_path_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CareerMatchesPage extends StatefulWidget {
  const CareerMatchesPage({super.key});

  @override
  State<CareerMatchesPage> createState() => _CareerMatchesPageState();
}

class _CareerMatchesPageState extends State<CareerMatchesPage> {
  bool _loading = true;
  String? _error;
  List<_MatchItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _items = [];
    });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) throw Exception('No signed-in user.');

      final userSnap = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .get();
      if (!userSnap.exists) throw Exception('User not found.');
      final data = userSnap.data() as Map<String, dynamic>? ?? {};
      final matchesRaw = (data['CareerMatches'] as List?) ?? [];

      final matches = matchesRaw
          .map<_MatchItem>((m) {
            final mm = Map<String, dynamic>.from(m as Map);
            return _MatchItem(
              careerId: '${mm['careerId'] ?? ''}',
              fitPercent: _clampInt(mm['fitPercent']),
              assessment: '${mm['assessment'] ?? ''}',
            );
          })
          .where((e) => e.careerId.isNotEmpty)
          .toList();

      if (matches.isEmpty) {
        setState(() {
          _items = [];
          _loading = false;
        });
        return;
      }

      final meta = await _fetchCareerMeta(
        matches.map((e) => e.careerId).toList(),
      );

      for (final m in matches) {
        final info = meta[m.careerId];
        m.title = info?.title ?? m.careerId;
        m.description = info?.description ?? '';
        m.industry = info?.industry ?? '';
        m.skills = info?.skills ?? const [];
      }

      matches.sort((a, b) => b.fitPercent.compareTo(a.fitPercent));

      setState(() {
        _items = matches;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<Map<String, _CareerInfo>> _fetchCareerMeta(List<String> ids) async {
    final Map<String, _CareerInfo> result = {};
    const int chunkSize = 10;
    for (var i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(i, min(i + chunkSize, ids.length));
      final qs = await FirebaseFirestore.instance
          .collection('CareerBank')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final d in qs.docs) {
        final m = d.data();
        final title = (m['Name'] ?? m['Title'] ?? m['name'] ?? m['title'] ?? '')
            .toString()
            .trim();
        final description = (m['Description'] ?? m['description'] ?? '')
            .toString()
            .trim();
        final industry = (m['Industry'] ?? m['industry'] ?? '')
            .toString()
            .trim();
        final skillsAny = (m['Skills'] ?? m['skills']);
        final skills = (skillsAny is List)
            ? skillsAny
                  .map((e) => '$e'.trim())
                  .where((s) => s.isNotEmpty)
                  .toList()
            : <String>[];

        result[d.id] = _CareerInfo(
          title: title.isEmpty ? d.id : title,
          description: description,
          industry: industry,
          skills: skills,
        );
      }
    }
    return result;
  }

  static int _clampInt(dynamic v) {
    try {
      final n = (v is num) ? v : num.parse('$v');
      final r = n.round();
      if (r < 0) return 0;
      if (r > 100) return 100;
      return r;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final color = theme.colorScheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: color.surface,
          elevation: 0,
          foregroundColor: primary,
          title: Text(
            'Matched Careers',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: color.surface,
          elevation: 0,
          foregroundColor: primary,
          title: Text(
            'Matched Careers',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: color.surface,
          elevation: 0,
          foregroundColor: primary,
          title: Text(
            'Matched Careers',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No recommendations yet. Complete the quiz to see your matches.',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: color.surface,
        elevation: 0,
        foregroundColor: primary,
        title: Text(
          'Matched Careers',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final item = _items[index];
            final isFirst = index == 0;
            final isLast = index == _items.length - 1;
            return _TimelineRow(
              isFirst: isFirst,
              isLast: isLast,
              lineColor: primary.withOpacity(.35),
              dotColor: primary,
              child: _CareerCard(
                item: item,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CareerPathPage(
                        careerId: item.careerId,
                        isAdmin: false,
                      ),
                    ),
                  );
                },
                surface: color.surface,
                onSurface: color.onSurface,
                primary: primary,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.child,
    required this.isFirst,
    required this.isLast,
    required this.lineColor,
    required this.dotColor,
  });

  final Widget child;
  final bool isFirst;
  final bool isLast;
  final Color lineColor;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight( // <-- gives a finite height for the left rail
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Center(
                      child: Container(width: 2, color: lineColor),
                    ),
                  ),
                Container(
                  height: 12,
                  width: 12,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withOpacity(.35),
                        blurRadius: 8,
                      )
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(width: 2, color: lineColor),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 0),
          Expanded(child: child),
        ],
      ),
    );
  }
}


class _CareerCard extends StatelessWidget {
  const _CareerCard({
    required this.item,
    required this.onTap,
    required this.surface,
    required this.onSurface,
    required this.primary,
  });

  final _MatchItem item;
  final VoidCallback onTap;
  final Color surface;
  final Color onSurface;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Material(
      // NỀN LỢT HƠN: dùng surface thuần, không overlay đậm
      color: color.surface, 
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // Viền rất mảnh & nhạt cho cảm giác “air”
            border: Border.all(color: primary.withOpacity(.12), width: 1),
            // Gradient cực nhẹ để có chiều sâu nhưng không làm tối nền
            gradient: LinearGradient(
              colors: [
                Colors.white,
                primary.withOpacity(.015),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AnimatedDonutPercent(percent: item.fitPercent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title (ĐÃ BỎ BADGE % Ở GÓC PHẢI)
                    Text(
                      item.title ?? item.careerId,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Assessment có nhãn AI gợi ý
                    if (item.assessment.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          // Lớp nền rất nhẹ, không gắt
                          color: Colors.green.withOpacity(.12),
                          border: Border.all(
                            color: Colors.green.withOpacity(.12),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Chip nhỏ: AI gợi ý
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(.18),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.green.withOpacity(.18),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_awesome, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'A.I.',
                                    style: t.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Nội dung assessment
                            Expanded(
                              child: Text(
                                item.assessment,
                                style: t.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 10),

                    if ((item.industry ?? '').isNotEmpty)
                      _Lined(
                        icon: Icons.apartment,
                        label: 'Industry',
                        value: item.industry!,
                      ),

                    if ((item.description ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _Multiline(
                          icon: Icons.description_outlined,
                          label: 'Description',
                          value: item.description!,
                        ),
                      ),

                    if ((item.skills ?? []).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _SkillsChips(skills: item.skills!),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _AnimatedDonutPercent extends StatefulWidget {
  const _AnimatedDonutPercent({required this.percent});
  final int percent;

  @override
  State<_AnimatedDonutPercent> createState() => _AnimatedDonutPercentState();
}

class _AnimatedDonutPercentState extends State<_AnimatedDonutPercent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _tween;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _tween = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    // Start animation on build
    _c.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedDonutPercent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percent != widget.percent) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 68,
      child: AnimatedBuilder(
        animation: _tween,
        builder: (_, __) {
          final target = widget.percent.clamp(0, 100).toDouble();
          final animatedPercent =
              target * _tween.value; // green grows from 0 -> target
          return CustomPaint(
            painter: _DonutPainter(
              greenPercent: animatedPercent,
              // red background is implicitly 100 - animatedPercent
              green: Colors.green,
              red: Colors.red,
            ),
            child: Center(
              child: Text(
                '${widget.percent}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.greenPercent,
    required this.green,
    required this.red,
  });

  final double greenPercent; // 0..100 animated
  final Color green;
  final Color red;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = min(size.width, size.height) / 2 - stroke;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    // Start fully red (background ring)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi,
      false,
      basePaint..color = red.withOpacity(.45),
    );

    // Animate green arc up to greenPercent
    final sweep = 2 * pi * (greenPercent.clamp(0, 100) / 100);
    if (sweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweep,
        false,
        basePaint..color = green,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.greenPercent != greenPercent || old.green != green || old.red != red;
}

class _Lined extends StatelessWidget {
  const _Lined({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = t.bodyMedium?.color?.withOpacity(.7);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: t.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Multiline extends StatelessWidget {
  const _Multiline({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = t.bodyMedium?.color?.withOpacity(.7);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: t.bodyMedium,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkillsChips extends StatelessWidget {
  const _SkillsChips({required this.skills});
  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skills',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills.take(12).map((s) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: primary.withOpacity(.06),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: primary.withOpacity(.2)),
              ),
              child: Text(
                s,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _MatchItem {
  _MatchItem({
    required this.careerId,
    required this.fitPercent,
    required this.assessment,
    this.title,
    this.description,
    this.industry,
    this.skills,
  });

  final String careerId;
  final int fitPercent;
  final String assessment;

  String? title;
  String? description;
  String? industry;
  List<String>? skills;
}

class _CareerInfo {
  _CareerInfo({
    required this.title,
    required this.description,
    required this.industry,
    required this.skills,
  });

  final String title;
  final String description;
  final String industry;
  final List<String> skills;
}
