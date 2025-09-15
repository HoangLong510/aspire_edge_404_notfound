import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../career/career_path_page.dart';

class CareerQuizPage extends StatefulWidget {
  const CareerQuizPage({super.key});

  @override
  State<CareerQuizPage> createState() => _CareerQuizPageState();
}

class _CareerQuizPageState extends State<CareerQuizPage> {
  bool _loading = true;
  String? _error;
  List<_MatchItem> _matches = [];
  int? _questionCount;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _matches = [];
    });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("No signed-in user.");

      final userSnap = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .get();
      if (!userSnap.exists) throw Exception("User not found.");
      final data = userSnap.data() ?? {};
      final matchesRaw = (data['CareerMatches'] as List?) ?? [];

      if (matchesRaw.isEmpty) {
        await _fetchQuestionCountForTier(data['Tier'] ?? 'user');
        setState(() {
          _matches = [];
          _loading = false;
        });
        return;
      }

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

      final filtered = matches.where((e) => e.fitPercent > 50).take(5).toList();

      setState(() {
        _matches = filtered;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _fetchQuestionCountForTier(String tier) async {
    try {
      final query = FirebaseFirestore.instance
          .collection('Questions')
          .where('Tier', isEqualTo: tier);
      try {
        final agg = await query.count().get();
        _questionCount = agg.count;
      } catch (_) {
        final snapshot = await query.get();
        _questionCount = snapshot.size;
      }
    } catch (_) {
      _questionCount = null;
    }
  }

  static int _clampInt(dynamic v) {
    try {
      final n = (v is num) ? v : num.parse('$v');
      return n.round().clamp(0, 100);
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, _CareerInfo>> _fetchCareerMeta(List<String> ids) async {
    final Map<String, _CareerInfo> result = {};
    const chunkSize = 10;
    for (var i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(i, min(i + chunkSize, ids.length));
      final qs = await FirebaseFirestore.instance
          .collection('CareerBank')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in qs.docs) {
        final m = d.data();
        final title = (m['Name'] ?? m['Title'] ?? '').toString().trim();
        final description = (m['Description'] ?? '').toString().trim();
        final industry = (m['Industry'] ?? '').toString().trim();
        final skillsAny = (m['Skills']);
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

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withOpacity(.12), primary.withOpacity(.04)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withOpacity(.12)),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _matches.isEmpty ? "Career Orientation Quiz" : "Matched Careers",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: .2,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(context),
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: _load,
                                child: const Text("Retry"),
                              ),
                            ],
                          ),
                        )
                      : _matches.isEmpty
                      ? _buildQuizIntro(context)
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: _matches.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final item = _matches[index];
                              final isFirst = index == 0;
                              final isLast = index == _matches.length - 1;
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
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).pushNamed('/answer_quiz');
          _load();
        },
        label: Text(_matches.isEmpty ? "Start Quiz" : "Retake Quiz"),
        icon: const Icon(Icons.quiz_outlined),
      ),
    );
  }

  Widget _buildQuizIntro(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final qCount = _questionCount == null ? "..." : "$_questionCount";
    final primary = Theme.of(context).primaryColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: primary.withOpacity(0.1),
              child: Icon(Icons.quiz_outlined, color: primary, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              "Career Orientation Quiz",
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              "Discover strengths and suitable career clusters in ~10 minutes.",
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _ChipInfo(
                  icon: Icons.timer_outlined,
                  label: "$qCount questions",
                ),
                const _ChipInfo(
                  icon: Icons.check_circle_outline,
                  label: "Instant result",
                ),
                const _ChipInfo(
                  icon: Icons.security_outlined,
                  label: "Private & secure",
                ),
              ],
            ),
          ],
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
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Center(child: Container(width: 2, color: lineColor)),
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
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Center(child: Container(width: 2, color: lineColor)),
                  ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _CareerCard extends StatefulWidget {
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
  State<_CareerCard> createState() => _CareerCardState();
}

class _CareerCardState extends State<_CareerCard> {
  String _summary(String text) {
    final t = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.length <= 160) return t;
    final cut = t.indexOf('.', 120);
    if (cut != -1 && cut < 180) return t.substring(0, cut + 1);
    return t.substring(0, 160) + '…';
  }

  void _showAssessmentSheet(BuildContext context) {
    final item = widget.item;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: ListView(
                controller: controller,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: widget.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.title ?? item.careerId,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.assessment,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  if ((item.skills ?? []).isNotEmpty) ...[
                    Text(
                      'Suggested skills',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.skills!.take(12).map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: widget.primary.withOpacity(.06),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: widget.primary.withOpacity(.2),
                            ),
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: widget.onTap,
                          icon: const Icon(Icons.route_outlined),
                          label: const Text('View career path'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final item = widget.item;

    return Material(
      color: widget.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.primary.withOpacity(.12),
              width: 1,
            ),
            gradient: LinearGradient(
              colors: [Colors.white, widget.primary.withOpacity(.015)],
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
                    if (item.assessment.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(.10),
                          border: Border.all(
                            color: Colors.green.withOpacity(.12),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _summary(item.assessment),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _showAssessmentSheet(context),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Read more',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.expand_more,
                                    size: 18,
                                    color: Colors.grey[700],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if ((item.industry ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _Lined(
                          icon: Icons.apartment,
                          label: 'Industry',
                          value: item.industry!,
                        ),
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
    _c.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedDonutPercent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percent != widget.percent) _c.forward(from: 0);
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
          final animatedPercent = target * _tween.value;
          return CustomPaint(
            painter: _DonutPainter(
              greenPercent: animatedPercent,
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
  final double greenPercent;
  final Color green;
  final Color red;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final center = size.center(Offset.zero);
    final radius = min(size.width, size.height) / 2 - stroke;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi,
      false,
      basePaint..color = red.withOpacity(.45),
    );

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

class _ChipInfo extends StatelessWidget {
  const _ChipInfo({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchItem {
  _MatchItem({
    required this.careerId,
    required this.fitPercent,
    required this.assessment,
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
