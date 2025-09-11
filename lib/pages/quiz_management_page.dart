import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- QUIZ MANAGEMENT ---
class QuizManagementPage extends StatefulWidget {
  const QuizManagementPage({super.key});

  @override
  State<QuizManagementPage> createState() => _QuizManagementPageState();
}

class _QuizManagementPageState extends State<QuizManagementPage> {
  final _col = FirebaseFirestore.instance.collection('Questions');

  // Bộ điều khiển Search / Filter / Sort
  final TextEditingController _searchCtl = TextEditingController();
  String _search = '';
  String _tier = 'all'; // all | student | postgraduate | professionals
  bool _desc = true;    // true = newest first

  void _goBack() {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _deleteQuestion(
    BuildContext context,
    String id,
    String preview,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final primary = Theme.of(ctx).primaryColor;
        return AlertDialog(
          title: const Text('Delete question?'),
          content: Text('This action cannot be undone.\n\nQuestion:\n"$preview"'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: primary)),
            ),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
    if (ok != true) return;

    try {
      await _col.doc(id).delete();
      if (!mounted) return;
      final primary = Theme.of(context).primaryColor;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Question deleted.'),
          backgroundColor: primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final primary = Theme.of(context).primaryColor;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: primary,
        ),
      );
    }
  }

  // Header
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withOpacity(.12), primary.withOpacity(.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withOpacity(.12)),
      ),
      child: Row(
        children: [
          IconButton.outlined(
            onPressed: _goBack,
            tooltip: 'Back',
            style: IconButton.styleFrom(
              foregroundColor: primary,
              side: BorderSide(color: primary.withOpacity(.6)),
            ),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Quiz Management',
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
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/create_quiz'),
            label: const Icon(Icons.add),
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // Controls: Search + Filter + Sort
  Widget _buildControls(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: primary.withOpacity(.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withOpacity(.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchCtl,
            onChanged: (v) => setState(() => _search = v.trim()),
            decoration: InputDecoration(
              hintText: 'Tìm theo câu hỏi…',
              prefixIcon: Icon(Icons.search, color: primary),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primary.withOpacity(.35)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primary),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _tier,
                  onChanged: (v) => setState(() => _tier = v ?? 'all'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All tiers')),
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                    DropdownMenuItem(value: 'postgraduate', child: Text('Postgraduate')),
                    DropdownMenuItem(value: 'professionals', child: Text('Professionals')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Tier',
                    labelStyle: TextStyle(color: primary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primary.withOpacity(.35)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _desc ? 'newest' : 'oldest',
                  onChanged: (v) => setState(() => _desc = (v == 'newest')),
                  items: const [
                    DropdownMenuItem(value: 'newest', child: Text('Newest first')),
                    DropdownMenuItem(value: 'oldest', child: Text('Oldest first')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Sort',
                    labelStyle: TextStyle(color: primary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primary.withOpacity(.35)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Stream (Cách B: tránh index khi filter Tier)
  Stream<QuerySnapshot<Map<String, dynamic>>> _questionStream() {
    Query<Map<String, dynamic>> q = _col;
    if (_tier != 'all') {
      q = q.where('Tier', isEqualTo: _tier);
      // Không orderBy ở đây → không cần composite index
    } else {
      q = q.orderBy('CreatedAt', descending: _desc);
    }
    return q.snapshots();
  }

  // Question card
  Widget _buildQuestionCard(
    BuildContext context, {
    required String id,
    required String text,
    required String tier,
    required DateTime? createdAt,
  }) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final onSurface = theme.colorScheme.onSurface;
    final preview = text.trim().isEmpty ? '(No text)' : text.trim();

    return Material(
      color: theme.colorScheme.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).pushNamed('/edit_quiz', arguments: {'id': id}),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primary.withOpacity(.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      preview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: primary.withOpacity(.15)),
              const SizedBox(height: 10),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  _Pill(
                    icon: Icons.leaderboard_outlined,
                    text: tier.isEmpty ? 'Tier: N/A' : 'Tier: $tier',
                    bg: primary.withOpacity(.10),
                    fg: primary,
                  ),
                  _Pill(
                    icon: Icons.access_time,
                    text: createdAt != null ? _fmtDate(createdAt) : 'Unknown date',
                    bg: primary.withOpacity(.08),
                    fg: primary,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context)
                        .pushNamed('/edit_quiz', arguments: {'id': id}),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.amber.shade800,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 6),
                  TextButton.icon(
                    onPressed: () => _deleteQuestion(context, id, preview),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Empty state
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return Center(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primary.withOpacity(.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 78, color: primary.withOpacity(.35)),
            const SizedBox(height: 12),
            Text(
              'No questions yet',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Create your first question to get started.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(.75),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/create_quiz'),
              icon: const Icon(Icons.add),
              label: const Text('Create'),
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} • ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    const maxWidth = 920.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              _buildControls(context),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _questionStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _LoadingListPlaceholder();
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    var docs = snapshot.data?.docs ?? [];

                    // Search client-side (substring, case-insensitive)
                    final kw = _search.toLowerCase();
                    if (kw.isNotEmpty) {
                      docs = docs.where((d) {
                        final txt = (d.data()['Text'] ?? '').toString().toLowerCase();
                        return txt.contains(kw);
                      }).toList();
                    }

                    // Sort client-side nếu đang filter Tier (tránh index)
                    if (_tier != 'all') {
                      docs.sort((a, b) {
                        final ta = (a.data()['CreatedAt'] as Timestamp?)?.toDate();
                        final tb = (b.data()['CreatedAt'] as Timestamp?)?.toDate();
                        final cmp = (ta ?? DateTime(0)).compareTo(tb ?? DateTime(0));
                        return _desc ? -cmp : cmp; // _desc=true => newest first
                      });
                    }

                    if (docs.isEmpty) return _buildEmptyState(context);

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final data = docs[i].data();
                        final id = docs[i].id;
                        final text = (data['Text'] ?? '').toString();
                        final tier = (data['Tier'] ?? '').toString();
                        final createdAt = (data['CreatedAt'] as Timestamp?)?.toDate();

                        return _buildQuestionCard(
                          ctx,
                          id: id,
                          text: text,
                          tier: tier,
                          createdAt: createdAt,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== Helper widgets =====

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.text,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: fg,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingListPlaceholder extends StatelessWidget {
  const _LoadingListPlaceholder();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return ListView.separated(
      itemCount: 6,
      padding: EdgeInsets.zero,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 98,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: primary.withOpacity(.25)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
