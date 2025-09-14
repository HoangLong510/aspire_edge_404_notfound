import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class CreateBlogPage extends StatefulWidget {
  const CreateBlogPage({super.key});

  @override
  State<CreateBlogPage> createState() => _CreateBlogPageState();
}

class _CreateBlogPageState extends State<CreateBlogPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  String? _selectedCareerId;
  final _picker = ImagePicker();

  List<XFile> _images = [];
  XFile? _video;
  bool _submitting = false;
  double _uploadProgress = 0;
  bool _showPreview = false;

  static const _cloudName = 'daxpkqhmd';
  static const _uploadPreset = '404notfound';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  // === MARKDOWN FORMAT ===
  void _toggleWrapSelection(String left, String right) {
    final selection = _contentCtrl.selection;
    final text = _contentCtrl.text;
    if (!selection.isValid) return;

    final start = selection.start;
    final end = selection.end;
    final selected = text.substring(start, end);

    final before = text.substring(0, start);
    final after = text.substring(end);

    final alreadyWrapped =
        selected.startsWith(left) && selected.endsWith(right);
    String newSelected;
    if (alreadyWrapped) {
      newSelected =
          selected.substring(left.length, selected.length - right.length);
    } else {
      newSelected = '$left$selected$right';
    }

    final newText = before + newSelected + after;
    final newCursor = before.length + newSelected.length;
    _contentCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    setState(() {});
  }

  // === PICK MEDIA ===
  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 90);
    if (files == null || files.isEmpty) return;
    setState(() => _images.addAll(files));
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _video = file);
  }

  // === CLOUDINARY UPLOAD ===
  Future<String> _uploadFile(XFile file, {required bool isVideo}) async {
    final url =
        'https://api.cloudinary.com/v1_1/$_cloudName/${isVideo ? "video" : "image"}/upload';
    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Cloudinary upload failed: $body');
    }
    final data = jsonDecode(body);
    return data['secure_url'];
  }

  Future<List<String>> _uploadImages() async {
    final urls = <String>[];
    for (var i = 0; i < _images.length; i++) {
      setState(() => _uploadProgress = i / (_images.length + (_video != null ? 1 : 0)));
      final url = await _uploadFile(_images[i], isVideo: false);
      urls.add(url);
    }
    return urls;
  }

  Future<String?> _uploadVideo() async {
    if (_video == null) return null;
    setState(() => _uploadProgress = _images.length / (_images.length + 1));
    return await _uploadFile(_video!, isVideo: true);
  }

  // === SAVE BLOG ===
  Future<void> _saveBlog() async {
    if (!_formKey.currentState!.validate()) return;
    if (FirebaseAuth.instance.currentUser == null) {
      _snack('You must be logged in to post.', isError: true);
      return;
    }

    setState(() {
      _submitting = true;
      _uploadProgress = 0;
    });

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final col = FirebaseFirestore.instance.collection('Blogs');
    final docRef = col.doc();

    try {
      final imageUrls = await _uploadImages();
      final videoUrl = await _uploadVideo();
      setState(() => _uploadProgress = 1);

      final data = {
        'Title': _titleCtrl.text.trim(),
        'ContentMarkdown': _contentCtrl.text,
        'CareerId': _selectedCareerId,
        'ImageUrls': imageUrls,
        'VideoUrl': videoUrl,
        'AuthorId': uid,
        'CreatedAt': Timestamp.now(),
        'UpdatedAt': Timestamp.now(),
      };

      await docRef.set(data);

      _snack('Blog created successfully.');
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _snack('Failed to create blog: $e', isError: true);
      setState(() {
        _submitting = false;
        _uploadProgress = 0;
      });
    }
  }

  void _snack(String msg, {bool isError = false}) {
    final color = isError ? Colors.red : Theme.of(context).primaryColor;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // === UI HELPERS ===
  InputDecoration _dec(BuildContext context, String label, {String? hint}) {
    final primary = Theme.of(context).primaryColor;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.black.withOpacity(0.03),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
            onPressed:
                _submitting ? null : () => Navigator.of(context).maybePop(),
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
                  'Create Blog',
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
        ],
      ),
    );
  }

  Widget _careerDropdown(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Career (optional)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primary.withOpacity(.22)),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('CareerBank')
                .orderBy('Title')
                .snapshots(),
            builder: (context, snap) {
              final items = <DropdownMenuItem<String?>>[
                const DropdownMenuItem(
                  value: null,
                  child: Text('No relation'),
                )
              ];
              if (snap.hasData) {
                for (final d in snap.data!.docs) {
                  final data = d.data() as Map<String, dynamic>;
                  final title =
                      (data['Name'] ?? data['Title'] ?? d.id).toString();
                  items.add(
                      DropdownMenuItem(value: d.id, child: Text(title)));
                }
              }
              return DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedCareerId,
                  isExpanded: true,
                  items: items,
                  onChanged: _submitting
                      ? null
                      : (v) => setState(() => _selectedCareerId = v),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _toolbar(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final primary = Theme.of(context).primaryColor;

    Widget btn(IconData icon, String tooltip, VoidCallback onTap) {
      return IconButton(
        icon: Icon(icon, size: 20, color: primary),
        tooltip: tooltip,
        onPressed: _submitting ? null : onTap,
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withOpacity(.18)),
      ),
      child: Row(
        children: [
          Text('Format',
              style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          btn(Icons.format_bold, 'Bold',
              () => _toggleWrapSelection('**', '**')),
          btn(Icons.format_italic, 'Italic',
              () => _toggleWrapSelection('_', '_')),
          btn(Icons.format_underline, 'Underline',
              () => _toggleWrapSelection('__', '__')),
          const Spacer(),
          Switch.adaptive(
            value: _showPreview,
            onChanged: _submitting
                ? null
                : (v) => setState(() => _showPreview = v),
          ),
          const SizedBox(width: 4),
          Text('Preview', style: t.labelLarge),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _mediaPicker() {
    final primary = Theme.of(context).primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Media',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _submitting ? null : _pickImages,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Add images'),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _submitting ? null : _pickVideo,
              icon: const Icon(Icons.video_library_outlined),
              label: const Text('Add video (max 1)'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_images.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _images.asMap().entries.map((e) {
              final idx = e.key;
              final file = e.value;
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(file.path),
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: InkWell(
                      onTap: _submitting
                          ? null
                          : () => setState(() => _images.removeAt(idx)),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black54,
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        if (_video != null) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: primary.withOpacity(.22)),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                const Icon(Icons.videocam_outlined),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_video!.name,
                        overflow: TextOverflow.ellipsis)),
                IconButton(
                  onPressed:
                      _submitting ? null : () => setState(() => _video = null),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove video',
                )
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _header(context),
                    TextFormField(
                      controller: _titleCtrl,
                      decoration:
                          _dec(context, 'Title', hint: 'Blog title...'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter a title'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _careerDropdown(context),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Content',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    _toolbar(context),
                    AnimatedCrossFade(
                      crossFadeState: _showPreview
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                      firstChild: TextFormField(
                        controller: _contentCtrl,
                        decoration: _dec(context, 'Write your blog...',
                            hint:
                                'Use toolbar to format (Bold/Italic/Underline)'),
                        minLines: 8,
                        maxLines: null,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Please enter content'
                                : null,
                      ),
                      secondChild: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primary.withOpacity(.18)),
                        ),
                        child: MarkdownBody(
                          data: _contentCtrl.text.replaceAll("\n", "  \n"),
                          selectable: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _mediaPicker(),
                    const SizedBox(height: 22),
                    if (_submitting)
                      Column(
                        children: [
                          LinearProgressIndicator(
                              value: _uploadProgress == 0
                                  ? null
                                  : _uploadProgress),
                          const SizedBox(height: 8),
                          Text(_uploadProgress == 0
                              ? 'Uploading...'
                              : '${(_uploadProgress * 100).toStringAsFixed(0)}%'),
                          const SizedBox(height: 8),
                        ],
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : _saveBlog,
                        icon: _submitting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save_outlined),
                        label:
                            Text(_submitting ? 'Saving...' : 'Publish'),
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
