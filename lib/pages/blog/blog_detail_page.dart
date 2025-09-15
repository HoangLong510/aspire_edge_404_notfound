import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:video_player/video_player.dart';

class BlogDetailPage extends StatefulWidget {
  final String blogId;
  const BlogDetailPage({super.key, required this.blogId});

  @override
  State<BlogDetailPage> createState() => _BlogDetailPageState();
}

class _BlogDetailPageState extends State<BlogDetailPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  VideoPlayerController? _videoController;
  int _currentImage = 0;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _relatedBlogs = [];

  @override
  void initState() {
    super.initState();
    _loadBlogData();
  }

  Future<void> _loadBlogData() async {
    try {
      await FirebaseFirestore.instance
          .collection("Blogs")
          .doc(widget.blogId)
          .update({"Views": FieldValue.increment(1)});

      final snap = await FirebaseFirestore.instance
          .collection("Blogs")
          .doc(widget.blogId)
          .get();

      if (!snap.exists) {
        if (!mounted) return;
        setState(() {
          _error = "Blog not found.";
          _loading = false;
        });
        return;
      }

      final data = snap.data()!;
      _data = data;

      final videoUrl = data["VideoUrl"]?.toString();
      if (videoUrl != null && videoUrl.isNotEmpty) {
        _videoController = VideoPlayerController.network(videoUrl)
          ..initialize().then((_) {
            if (mounted) setState(() {});
          });
      }

      final dynamic careerIdDyn = data["CareerId"];
      final createdAt = (data["CreatedAt"] as Timestamp?)?.toDate();

      if (createdAt != null) {
        final col = FirebaseFirestore.instance.collection("Blogs");
        final sameCareer = await col
            .where("CareerId", isEqualTo: careerIdDyn)
            .limit(50)
            .get();
        
        final related = sameCareer.docs
            .where((d) => d.id != widget.blogId)
            .map((d) {
              final dt = (d["CreatedAt"] as Timestamp?)?.toDate() ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final diff = (dt.difference(createdAt)).inMilliseconds.abs();
              return MapEntry(d, diff);
            })
            .toList();

        related.sort((a, b) => a.value.compareTo(b.value));
        _relatedBlogs = related.take(5).map((e) => e.key).toList();
      }

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Widget _buildHeader(BuildContext context, String title, {bool showBack = true}) {
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
          if (showBack)
            IconButton.outlined(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Back',
              style: IconButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: primary.withOpacity(.6)),
              ),
              icon: const Icon(Icons.arrow_back),
            )
          else
            const SizedBox(width: 48),
          const SizedBox(width: 8),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: .2,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(14),
  }) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withOpacity(.12), width: 1),
        gradient: LinearGradient(
          colors: [Colors.white, primary.withOpacity(.015)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: padding,
      child: child,
    );
  }

  String _plainFromMd(String s) {
    var text = s;
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
    text = text.replaceAll(RegExp(r'`[^`]*`'), ' ');
    text = text.replaceAll(RegExp(r'!\[[^\]]*\]\([^)]+\)'), ' ');
    text = text.replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1');
    text = text.replaceAll(RegExp(r'\*\*|__|\*|_|~~|^> ?', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*#{1,6}\s*', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*[-+*]\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text.trim();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Blog Detail")),
        body: Center(child: Text(_error!)),
      );
    }

    final title = _data?["Title"] ?? "Untitled";
    final content = _data?["ContentMarkdown"] ?? "";
    final imageUrls = (_data?["ImageUrls"] as List?)?.cast<String>() ?? [];
    final createdAt = (_data?["CreatedAt"] as Timestamp?)?.toDate();
    final views = (_data?["Views"] ?? 0) as int;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, "Blog Detail"),

                  _buildSectionCard(
                    context: context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            _ChipInfo(
                              icon: Icons.calendar_today_outlined,
                              label: createdAt == null
                                  ? "Unknown date"
                                  : DateFormat("dd/MM/yyyy HH:mm")
                                      .format(createdAt),
                            ),
                            _ChipInfo(
                              icon: Icons.visibility_outlined,
                              label: "$views views",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (imageUrls.isNotEmpty)
                    _buildSectionCard(
                      context: context,
                      padding: EdgeInsets.zero,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: PageView.builder(
                              itemCount: imageUrls.length,
                              onPageChanged: (i) =>
                                  setState(() => _currentImage = i),
                              itemBuilder: (context, index) {
                                final url = imageUrls[index];
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    url,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            ),
                          ),
                          if (imageUrls.length > 1)
                            Positioned(
                              bottom: 10,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children:
                                    List.generate(imageUrls.length, (index) {
                                  final active = _currentImage == index;
                                  return AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    width: active ? 20 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? primary
                                          : Colors.white.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  );
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (imageUrls.isNotEmpty) const SizedBox(height: 14),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: MarkdownBody(
                      data: content,
                      selectable: true,
                      extensionSet: md.ExtensionSet.gitHubWeb,
                      styleSheet: MarkdownStyleSheet.fromTheme(
                        Theme.of(context),
                      ).copyWith(
                        p: const TextStyle(fontSize: 16, height: 1.6),
                        h1: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold),
                        h2: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                        h3: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (_videoController != null &&
                      _videoController!.value.isInitialized)
                    _buildSectionCard(
                      context: context,
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: VideoPlayer(_videoController!),
                            ),
                          ),
                          VideoProgressIndicator(
                            _videoController!,
                            allowScrubbing: true,
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _videoController!.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: primary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (_videoController!.value.isPlaying) {
                                      _videoController!.pause();
                                    } else {
                                      _videoController!.play();
                                    }
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.replay_10),
                                onPressed: () {
                                  final pos =
                                      _videoController!.value.position;
                                  _videoController!.seekTo(
                                    pos - const Duration(seconds: 10),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.forward_10),
                                onPressed: () {
                                  final pos =
                                      _videoController!.value.position;
                                  _videoController!.seekTo(
                                    pos + const Duration(seconds: 10),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (_videoController != null &&
                      _videoController!.value.isInitialized)
                    const SizedBox(height: 14),

                  if (_relatedBlogs.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
                      child: Text(
                        "Related Blogs",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: primary,
                            ),
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _relatedBlogs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final d = _relatedBlogs[index];
                        final data = d.data();
                        final id = d.id;

                        final relTitle =
                            (data["Title"] ?? "Untitled").toString();
                        final relContent =
                            (data["ContentMarkdown"] ?? "").toString();
                        final relCreatedAt =
                            (data["CreatedAt"] as Timestamp?)?.toDate();
                        final relViews = (data["Views"] ?? 0) as int;

                        final images =
                            (data["ImageUrls"] as List?)?.cast<String>() ?? [];
                        final thumb = images.isNotEmpty ? images.first : null;

                        return Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                "/blog_detail",
                                arguments: {"blogId": id},
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primary.withOpacity(.12),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                    child: SizedBox(
                                      width: 120,
                                      height: 110,
                                      child: thumb != null
                                          ? Image.network(
                                              thumb,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: Colors.grey[200],
                                              child: Icon(
                                                Icons
                                                    .image_not_supported_outlined,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          12, 10, 12, 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            relTitle,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _plainFromMd(relContent),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Colors.grey[700],
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .calendar_today_outlined,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                relCreatedAt == null
                                                    ? "Unknown"
                                                    : DateFormat(
                                                            "dd/MM/yyyy HH:mm")
                                                        .format(relCreatedAt),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Icon(
                                                Icons.visibility_outlined,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "$relViews views",
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
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