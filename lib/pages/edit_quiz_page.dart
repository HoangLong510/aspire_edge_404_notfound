// edit_quiz_page.dart
// UI English, Vietnamese notes. Body-only, Firestore PascalCase fields.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditQuizPage extends StatefulWidget {
  const EditQuizPage({super.key});

  @override
  State<EditQuizPage> createState() => _EditQuizPageState();
}

class _EditQuizPageState extends State<EditQuizPage> {
  // --- STATE & CONTROLLERS ---
  final _formKey = GlobalKey<FormState>();

  final _questionCtrl = TextEditingController();
  String _selectedTier = 'student'; // default (fallback)

  final _optACtrl = TextEditingController();
  final _optBCtrl = TextEditingController();
  final _optCCtrl = TextEditingController();
  final _optDCtrl = TextEditingController();

  bool _submitting = false;

  // load state
  bool _initializing = true;
  bool _notFound = false;
  String? _docId; // Questions/{_docId}
  Timestamp? _createdAt; // keep original

  @override
  void dispose() {
    _questionCtrl.dispose();
    _optACtrl.dispose();
    _optBCtrl.dispose();
    _optCCtrl.dispose();
    _optDCtrl.dispose();
    super.dispose();
  }

  // --- LOAD FROM FIRESTORE ---
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializing) {
      // read arguments once
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['id'] is String) {
        _docId = args['id'] as String;
        _fetchDoc();
      } else {
        // no id passed → cannot proceed
        setState(() {
          _initializing = false;
          _notFound = true;
        });
      }
    }
  }

  Future<void> _fetchDoc() async {
    try {
      final ref = FirebaseFirestore.instance.collection('Questions').doc(_docId);
      final snap = await ref.get();

      if (!snap.exists) {
        setState(() {
          _initializing = false;
          _notFound = true;
        });
        return;
      }

      final data = snap.data() as Map<String, dynamic>? ?? {};

      // Map fields defensively
      final text = (data['Text'] ?? '').toString();
      final tier = (data['Tier'] ?? 'student').toString();

      final options = (data['Options'] as Map?) ?? {};
      String _opt(Map? m) => (m?['Text'] ?? '').toString();

      _questionCtrl.text = text;
      _selectedTier = tier;
      _optACtrl.text = _opt(options['A'] as Map?);
      _optBCtrl.text = _opt(options['B'] as Map?);
      _optCCtrl.text = _opt(options['C'] as Map?);
      _optDCtrl.text = _opt(options['D'] as Map?);

      _createdAt = data['CreatedAt'] is Timestamp ? data['CreatedAt'] as Timestamp : null;

      setState(() {
        _initializing = false;
      });
    } catch (e) {
      setState(() {
        _initializing = false;
        _notFound = true;
      });
      if (mounted) {
        final primary = Theme.of(context).primaryColor;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load question: $e'),
            backgroundColor: primary,
          ),
        );
      }
    }
  }

  // --- SAVE UPDATES TO FIRESTORE ---
  Future<void> _saveEdits() async {
    if (_docId == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final update = <String, dynamic>{
        'Text': _questionCtrl.text.trim(),
        'Tier': _selectedTier, // 'student' | 'postgraduate' | 'professionals'
        // keep original CreatedAt (do not touch)
        'UpdatedAt': Timestamp.now(),
        'Options': {
          'A': {'Text': _optACtrl.text.trim()},
          'B': {'Text': _optBCtrl.text.trim()},
          'C': {'Text': _optCCtrl.text.trim()},
          'D': {'Text': _optDCtrl.text.trim()},
        },
      };

      await FirebaseFirestore.instance
          .collection('Questions')
          .doc(_docId)
          .update(update);

      if (!mounted) return;
      final primary = Theme.of(context).primaryColor;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Question updated successfully.'),
          backgroundColor: primary,
        ),
      );

      // Optionally pop back
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      final primary = Theme.of(context).primaryColor;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update question: $e'),
          backgroundColor: primary,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // --- DECORATION (accent = primaryColor) ---
  InputDecoration _dec(BuildContext context, String label, {String? hint}) {
    final primary = Theme.of(context).primaryColor;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.black.withOpacity(0.03),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary.withOpacity(.18)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary.withOpacity(.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2),
      ),
    );
  }

  // --- SIMPLE OPTION CARD (no careers; accent = primaryColor) ---
  Widget _optionCard({
    required BuildContext context,
    required String title, // 'Option A'
    required TextEditingController textCtrl,
  }) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: textCtrl,
            decoration: _dec(
              context,
              'Answer text',
              hint: 'Type the answer...',
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter an answer'
                : null,
          ),
        ],
      ),
    );
  }

  // --- HEADER (gradient + buttons; use primaryColor) ---
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
          // Back/Cancel (outlined, primary)
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

          // Title responsive, center
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Edit Quiz Question',
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

          // Save (filled, primaryColor)
          FilledButton.icon(
            onPressed: (_submitting || _initializing || _notFound)
                ? null
                : _saveEdits,
            label: _submitting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // --- BUILD (body-only) ---
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
                const Text('Loading question...'),
              ],
            ),
          ),
        ),
      );
    }

    if (_notFound) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              children: [
                _header(context),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: primary.withOpacity(.22)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Question not found or invalid link.',
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _header(context),

                // CreatedAt pill (read-only info)
                if (_createdAt != null) ...[
                  Align(
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
                          const Icon(Icons.access_time, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _fmtDate(_createdAt!.toDate()),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Question Text
                TextFormField(
                  controller: _questionCtrl,
                  decoration: _dec(
                    context,
                    'Question text',
                    hint: 'Type your question...',
                  ),
                  minLines: 1,
                  maxLines: null,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter the question text'
                      : null,
                ),
                const SizedBox(height: 12),

                // Tier
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tier',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primary.withOpacity(.22),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTier,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'student',
                          child: Text('student'),
                        ),
                        DropdownMenuItem(
                          value: 'postgraduate',
                          child: Text('postgraduate'),
                        ),
                        DropdownMenuItem(
                          value: 'professionals',
                          child: Text('professionals'),
                        ),
                      ],
                      onChanged: _submitting
                          ? null
                          : (v) => setState(() => _selectedTier = v ?? 'student'),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Options A–D (simple)
                _optionCard(
                  context: context,
                  title: 'Option A',
                  textCtrl: _optACtrl,
                ),
                const SizedBox(height: 12),
                _optionCard(
                  context: context,
                  title: 'Option B',
                  textCtrl: _optBCtrl,
                ),
                const SizedBox(height: 12),
                _optionCard(
                  context: context,
                  title: 'Option C',
                  textCtrl: _optCCtrl,
                ),
                const SizedBox(height: 12),
                _optionCard(
                  context: context,
                  title: 'Option D',
                  textCtrl: _optDCtrl,
                ),

                const SizedBox(height: 22),

                // Save bottom (mobile-friendly)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _saveEdits,
                    icon: _submitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_submitting ? 'Saving...' : 'Save changes'),
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} • ${two(dt.hour)}:${two(dt.minute)}';
  }
}
