import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as md;

class BlogEditPage extends StatefulWidget {
  final String blogId;
  const BlogEditPage({super.key, required this.blogId});

  @override
  State<BlogEditPage> createState() => _BlogEditPageState();
}

class _BlogEditPageState extends State<BlogEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  String? _selectedCareerId;

  // Media
  final _picker = ImagePicker();
  List<String> _existingImages = [];
  String? _existingVideo;
  List<XFile> _newImages = [];
  XFile? _newVideo;

  // State
  bool _loading = true;
  bool _submitting = false;
  double _uploadProgress = 0;
  bool _showPreview = false;

  // Cloudinary
  static const _cloudName = 'daxpkqhmd';
  static const _uploadPreset = '404notfound';

  @override
  void initState() {
    super.initState();
    _loadBlog();

    // Khi preview bật, cập nhật live khi nội dung thay đổi
    _contentCtrl.addListener(() {
      if (_showPreview && mounted) setState(() {});
    });
  }

  Future<void> _loadBlog() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('Blogs')
          .doc(widget.blogId)
          .get();

      if (!snap.exists) {
        _snack("Blog not found", isError: true);
        if (mounted) Navigator.of(context).pop();
        return;
      }

      final data = snap.data()!;
      _titleCtrl.text = data['Title'] ?? '';
      _contentCtrl.text = data['ContentMarkdown'] ?? '';
      _selectedCareerId = data['CareerId'];
      _existingImages =
          (data['ImageUrls'] as List?)?.map((e) => e.toString()).toList() ?? [];
      _existingVideo = data['VideoUrl'];

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      _snack("Failed to load blog: $e", isError: true);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  // ===== Formatting toolbar =====
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

  // ===== Pick media =====
  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 90);
    if (files.isEmpty) return;
    setState(() => _newImages.addAll(files));
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _newVideo = file);
  }

  // ===== Cloudinary upload =====
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
    final totalParts = _newImages.length + (_newVideo != null ? 1 : 0);
    final urls = <String>[];
    for (var i = 0; i < _newImages.length; i++) {
      if (totalParts > 0) {
        setState(() => _uploadProgress = i / totalParts);
      }
      final url = await _uploadFile(_newImages[i], isVideo: false);
      urls.add(url);
    }
    return urls;
  }

  Future<String?> _uploadVideo() async {
    if (_newVideo == null) return _existingVideo;
    final totalParts = _newImages.length + 1;
    setState(() => _uploadProgress = _newImages.length / totalParts);
    return await _uploadFile(_newVideo!, isVideo: true);
  }

  // ===== Save (Update) =====
  Future<void> _updateBlog() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _uploadProgress = 0;
    });

    try {
      final newImageUrls = await _uploadImages();
      final finalImageUrls = [..._existingImages, ...newImageUrls];
      final videoUrl = await _uploadVideo();

      final data = {
        'Title': _titleCtrl.text.trim(),
        'ContentMarkdown': _contentCtrl.text,
        'CareerId': _selectedCareerId,
        'ImageUrls': finalImageUrls,
        'VideoUrl': videoUrl,
        'UpdatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('Blogs')
          .doc(widget.blogId)
          .update(data);

      _snack('Blog updated successfully.');
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _snack('Failed to update blog: $e', isError: true);
      if (mounted) {
        setState(() {
          _submitting = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  void _snack(String msg, {bool isError = false}) {
    final color = isError ? Colors.red : Theme.of(context).primaryColor;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ===== UI helpers =====
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
            onPressed: _submitting ? null : () => Navigator.of(context).maybePop(),
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
                  'Edit Blog',
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
                  items.add(DropdownMenuItem(value: d.id, child: Text(title)));
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
          btn(Icons.format_bold, 'Bold', () => _toggleWrapSelection('**', '**')),
          btn(Icons.format_italic, 'Italic', () => _toggleWrapSelection('_', '_')),
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

        // Existing images
        if (_existingImages.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _existingImages.asMap().entries.map((e) {
              final idx = e.key;
              final url = e.value;
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
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
                          : () => setState(() => _existingImages.removeAt(idx)),
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

        // New images (local)
        if (_newImages.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _newImages.asMap().entries.map((e) {
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
                          : () => setState(() => _newImages.removeAt(idx)),
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
        ],

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
              label: const Text('Replace video'),
            ),
          ],
        ),

        // Existing video (if not replaced)
        if (_existingVideo != null && _newVideo == null) ...[
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
                Expanded(child: Text(_existingVideo!, overflow: TextOverflow.ellipsis)),
                IconButton(
                  onPressed: _submitting
                      ? null
                      : () => setState(() => _existingVideo = null),
                  icon: const Icon(Icons.delete_outline),
                )
              ],
            ),
          ),
        ],

        // New video (local)
        if (_newVideo != null) ...[
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
                Expanded(child: Text(_newVideo!.name, overflow: TextOverflow.ellipsis)),
                IconButton(
                  onPressed:
                      _submitting ? null : () => setState(() => _newVideo = null),
                  icon: const Icon(Icons.delete_outline),
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

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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

                    // Title
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: _dec(context, 'Title', hint: 'Blog title...'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 12),

                    // Career dropdown
                    _careerDropdown(context),
                    const SizedBox(height: 12),

                    // Content + Toolbar + Preview
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
                        decoration: _dec(
                          context,
                          'Write your blog...',
                          hint: 'Use toolbar to format (Bold/Italic/Underline)',
                        ),
                        minLines: 8,
                        maxLines: null,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Please enter content' : null,
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
                          // Đảm bảo xuống dòng mượt
                          data: _contentCtrl.text.replaceAll("\n", "  \n"),
                          selectable: true,
                          extensionSet: md.ExtensionSet.gitHubWeb,
                          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                              .copyWith(p: const TextStyle(fontSize: 16, height: 1.5)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Media
                    _mediaPicker(),
                    const SizedBox(height: 22),

                    // Progress
                    if (_submitting)
                      Column(
                        children: [
                          LinearProgressIndicator(
                              value: _uploadProgress == 0 ? null : _uploadProgress),
                          const SizedBox(height: 8),
                          Text(_uploadProgress == 0
                              ? 'Uploading...'
                              : '${(_uploadProgress * 100).toStringAsFixed(0)}%'),
                          const SizedBox(height: 8),
                        ],
                      ),

                    // Save
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : _updateBlog,
                        icon: _submitting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save_outlined),
                        label: Text(_submitting ? 'Saving...' : 'Update Blog'),
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape:
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
