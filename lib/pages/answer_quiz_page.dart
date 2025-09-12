import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'career_matches_page.dart';

const String kOpenAIBaseUrl = 'https://api.openai.com/v1';
const String kOpenAIModel = 'gpt-4o-mini';
final String kOpenAIApiKey = dotenv.env['OPENAI_API_KEY'] ?? 'sk-REPLACE_WITH_YOUR_KEY';

class AnswerQuizPage extends StatefulWidget {
  const AnswerQuizPage({super.key});

  @override
  State<AnswerQuizPage> createState() => _AnswerQuizPageState();
}

class _AnswerQuizPageState extends State<AnswerQuizPage> {
  bool _initializing = true;
  bool _loading = false;
  String? _error;

  String? _userId;
  String? _userTier;

  final List<_QItem> _questions = [];
  int _index = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _initializing = true;
      _error = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        throw Exception('No signed-in user. Please sign in first.');
      }
      _userId = uid;
      await _loadData();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _questions.clear();
      _index = 0;
    });

    try {
      final userSnap = await FirebaseFirestore.instance
          .collection('Users')
          .doc(_userId)
          .get();
      if (!userSnap.exists) {
        throw Exception('User document not found: Users/$_userId.');
      }
      final data = userSnap.data() as Map<String, dynamic>? ?? {};
      final tier = (data['Tier'] ?? '').toString().trim();
      if (tier.isEmpty) {
        throw Exception('User Tier is empty (Users/$_userId.Tier).');
      }
      _userTier = tier;

      final qs = await FirebaseFirestore.instance
          .collection('Questions')
          .where('Tier', isEqualTo: _userTier)
          .get();

      for (final d in qs.docs) {
        final q = d.data();
        final text = (q['Text'] ?? '').toString();
        final options = (q['Options'] as Map?) ?? {};
        String _opt(Map? m) => (m?['Text'] ?? '').toString();
        final createdAt = (q['CreatedAt'] as Timestamp?)?.toDate();

        _questions.add(
          _QItem(
            id: d.id,
            text: text,
            options: {
              'A': _opt(options['A'] as Map?),
              'B': _opt(options['B'] as Map?),
              'C': _opt(options['C'] as Map?),
              'D': _opt(options['D'] as Map?),
            },
            createdAt: createdAt,
          ),
        );
      }

      _questions.sort((a, b) {
        final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ta.compareTo(tb);
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _isFirst => _index == 0;
  bool get _isLast => _questions.isNotEmpty && _index == _questions.length - 1;
  _QItem get _current => _questions[_index];

  bool get _canGoNext => !_isLast && _current.selected != null;
  bool get _canSubmit => _isLast && _current.selected != null;

  void _prev() {
    if (_isFirst) return;
    setState(() => _index -= 1);
  }

  void _next() {
    if (!_canGoNext) {
      final primary = Theme.of(context).primaryColor;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please choose an option to continue.'),
          backgroundColor: primary,
        ),
      );
      return;
    }
    setState(() => _index += 1);
  }

  Future<void> _submit() async {
    final unanswered = _questions.where((q) => q.selected == null).toList();
    if (unanswered.isNotEmpty) {
      final primary = Theme.of(context).primaryColor;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please answer all questions • ${unanswered.length} remaining',
          ),
          backgroundColor: primary,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final quizPayload = _buildResultPayload();

      final careerSnap = await FirebaseFirestore.instance
          .collection('CareerBank')
          .get();
      final careers = careerSnap.docs.map((d) {
        return {'id': d.id, 'doc': d.data()};
      }).toList();

      final aiResults = await _callOpenAIForCareerMatch(
        careers: careers,
        quizResult: quizPayload,
        userTier: _userTier ?? '',
      );

      await FirebaseFirestore.instance.collection('Users').doc(_userId).set({
        'CareerMatches': aiResults,
        'CareerMatchesUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CareerMatchesPage()),
      );
    } catch (e) {
      if (!mounted) return;
      final primary = Theme.of(context).primaryColor;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI matching failed: $e'),
          backgroundColor: primary,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  List<Map<String, String>> _buildResultPayload() {
    return _questions.map((q) {
      final key = q.selected!;
      final optionText = q.options[key] ?? '';
      return {'question': q.text, 'option': optionText};
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _callOpenAIForCareerMatch({
    required List<Map<String, dynamic>> careers,
    required List<Map<String, String>> quizResult,
    required String userTier,
  }) async {
    if (kOpenAIApiKey == 'sk-REPLACE_WITH_YOUR_KEY' ||
        kOpenAIApiKey.trim().isEmpty) {
      throw Exception('Please set kOpenAIApiKey in answer_quiz_page.dart');
    }

    final systemPrompt = '''
You are a strict career-matching assistant. For EACH career provided, compute a suitability score from 0 to 100 based on the user's tier and quiz answers.
Be decisive and use the full 0–100 range. Keep each assessment short (<= 25 words), specific, and actionable. Do not repeat question texts.
Return ONLY JSON following the provided schema. No extra commentary.
''';

    final userPayload = {
      'instruction':
          'Given the user tier and quiz result, compute a suitability score and a concise assessment for EVERY career.',
      'userTier': userTier,
      'quizResult': quizResult,
      'careers': careers,
      'required_output_schema': {
        'type': 'object',
        'properties': {
          'matches': {
            'type': 'array',
            'items': {
              'type': 'object',
              'properties': {
                'careerId': {'type': 'string'},
                'fitPercent': {'type': 'integer', 'minimum': 0, 'maximum': 100},
                'assessment': {'type': 'string'},
              },
              'required': ['careerId', 'fitPercent', 'assessment'],
              'additionalProperties': false,
            },
          },
        },
        'required': ['matches'],
        'additionalProperties': false,
      },
      'example': {
        'matches': [
          {
            'careerId': 'abc123',
            'fitPercent': 86,
            'assessment': 'Strong alignment with your interests and skills.',
          },
          {
            'careerId': 'def456',
            'fitPercent': 42,
            'assessment': 'Possible, but other roles fit better.',
          },
        ],
      },
    };

    final uri = Uri.parse('$kOpenAIBaseUrl/chat/completions');
    final headers = {
      'Authorization': 'Bearer $kOpenAIApiKey',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'model': kOpenAIModel,
      'temperature': 0.2,
      'response_format': {'type': 'json_object'},
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {
          'role': 'user',
          'content':
              'Return ONLY a strict JSON object following the schema { matches: [{careerId, fitPercent, assessment}] }.\nAssess every career in "careers". Here is the input:\n\n${jsonEncode(userPayload)}',
        },
      ],
    });

    final res = await http.post(uri, headers: headers, body: body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('OpenAI HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final content = (decoded['choices'] as List).isNotEmpty
        ? ((decoded['choices'][0]['message']?['content']) ??
              (decoded['choices'][0]['message']?['delta']?['content']) ??
              '')
        : '';

    Map<String, dynamic>? parsed;
    try {
      parsed = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      final m = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (m == null) throw Exception('LLM did not return valid JSON.');
      parsed = jsonDecode(m.group(0)!) as Map<String, dynamic>;
    }

    final matches = (parsed['matches'] is List)
        ? parsed['matches'] as List
        : [];
    final results = matches.map<Map<String, dynamic>>((m) {
      final id = '${m['careerId'] ?? ''}';
      final percent = _clampInt((m['fitPercent'] ?? 0) as num, 0, 100);
      final assessment = '${m['assessment'] ?? ''}';
      return {'careerId': id, 'fitPercent': percent, 'assessment': assessment};
    }).toList();

    results.sort(
      (a, b) => (b['fitPercent'] ?? 0).compareTo(a['fitPercent'] ?? 0),
    );
    return results;
  }

  int _clampInt(num n, int min, int max) {
    final v = n.isFinite ? n.round() : min;
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }

  Widget _header(BuildContext context) {
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
            onPressed: _submitting
                ? null
                : () => Navigator.of(context).maybePop(),
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
                  'Answer Quiz',
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
          // (Removed the top Submit button)
        ],
      ),
    );
  }

  Widget _progressPill(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final total = _questions.length;
    final current = (_index + 1).clamp(1, total);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: primary.withOpacity(.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: primary.withOpacity(.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.help_outline, size: 16),
            const SizedBox(width: 6),
            Text(
              'Question $current / $total',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionCard(_QItem q) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final entries = q.options.entries
        .where((e) => e.value.trim().isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: primary.withOpacity(.22)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            q.text.isEmpty ? '(No text)' : q.text,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...entries.map((e) {
            final key = e.key;
            final label = e.value;
            return RadioListTile<String>(
              value: key,
              groupValue: q.selected,
              onChanged: (v) => setState(() => q.selected = v),
              title: Text('$key. $label'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    if (_initializing) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              children: [
                _header(context),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                const Text('Preparing quiz...'),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              children: [
                _header(context),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: primary.withOpacity(.22)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text('Error: $_error', textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _error = null;
                            _initializing = true;
                          });
                          _init();
                        },
                        child: const Text('Retry'),
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

    if (_loading) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              children: [
                _header(context),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                const Text('Loading questions...'),
              ],
            ),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              children: [
                _header(context),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: primary.withOpacity(.22)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'No questions for your tier (${_userTier ?? 'unknown'}).',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context),
              _progressPill(context),
              const SizedBox(height: 12),
              _questionCard(_current),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isFirst ? null : _prev,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                  ),
                  const Spacer(),
                  if (!_isLast)
                    FilledButton.icon(
                      onPressed: _canGoNext && !_submitting ? _next : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _canSubmit && !_submitting ? _submit : null,
                      icon: _submitting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(_submitting ? 'Submitting...' : 'Submit'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QItem {
  _QItem({
    required this.id,
    required this.text,
    required this.options,
    this.selected,
    this.createdAt,
  });

  final String id;
  final String text;
  final Map<String, String> options;
  String? selected;
  final DateTime? createdAt;
}
