import 'dart:io';
import 'package:aspire_edge_404_notfound/constants/industries.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class CareerDocsAllPage extends StatefulWidget {
  const CareerDocsAllPage({super.key});

  @override
  State<CareerDocsAllPage> createState() => _CareerDocsAllPageState();
}

class _CareerDocsAllPageState extends State<CareerDocsAllPage> {
  final _searchCtrl = TextEditingController();
  String? _selectedIndustryId;
  String? _selectedCareerId;
  String? _selectedType;

  final Map<String, int> _progressMap = {};
  final Dio _dio = Dio();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    }
  }

  Future<void> _downloadFile(
    BuildContext context,
    String url,
    String filename,
  ) async {
    await _checkPermission();
    Directory dir = Platform.isAndroid
        ? (await getExternalStorageDirectory())!
        : await getApplicationDocumentsDirectory();

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final filePath = "${dir.path}/$filename";

    try {
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (count, total) {
          if (total > 0) {
            final progress = (count / total * 100).toInt();
            setState(() {
              _progressMap[filename] = progress;
            });
          }
        },
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Downloaded $filename")));
      await OpenFile.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Download failed: $e")));
    }
  }

  void _openVideo(BuildContext context, String url, String title, String desc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            VideoPlayerPage(videoUrl: url, title: title, description: desc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 2,
        title: const Text(
          "Resource Hub – All Careers",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            tooltip: "Reset filters",
            onPressed: () {
              setState(() {
                _selectedIndustryId = null;
                _selectedCareerId = null;
                _selectedType = null;
                _searchCtrl.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: "Search by document or career...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedIndustryId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Industry",
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text("All Industries"),
                      ),
                      ...INDUSTRIES.map(
                        (ind) => DropdownMenuItem(
                          value: ind.id,
                          child: Row(
                            children: [
                              Icon(ind.icon, size: 18),
                              const SizedBox(width: 6),
                              Text(ind.name),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _selectedIndustryId = v;
                        _selectedCareerId = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedIndustryId != null)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("CareerBank")
                          .where("IndustryId", isEqualTo: _selectedIndustryId)
                          .snapshots(),
                      builder: (ctx, snap) {
                        if (!snap.hasData) return const SizedBox();
                        final careers = snap.data!.docs;
                        if (careers.isEmpty) {
                          return const Text("No careers for this industry");
                        }
                        return DropdownButtonFormField<String>(
                          value: _selectedCareerId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: "Career",
                            border: OutlineInputBorder(),
                          ),
                          items: careers.map((d) {
                            final name = d['Title'] ?? '';
                            return DropdownMenuItem(
                              value: d.id,
                              child: Text(name),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCareerId = v),
                        );
                      },
                    ),
                  if (_selectedIndustryId != null) const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: "Type",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text("All")),
                      DropdownMenuItem(value: "pdf", child: Text("PDF")),
                      DropdownMenuItem(value: "mp4", child: Text("Video")),
                    ],
                    onChanged: (v) => setState(() => _selectedType = v),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup("Docs")
                  .snapshots(),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No resources found"));
                }

                final q = _searchCtrl.text.trim().toLowerCase();
                final docs = snapshot.data!.docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final careerTitle = (data['careerTitle'] ?? '')
                      .toString()
                      .toLowerCase();
                  final type = (data['type'] ?? '').toString().toLowerCase();
                  final industryId = data['industry'];
                  final careerId = data['careerId'];

                  final matchSearch =
                      q.isEmpty || title.contains(q) || careerTitle.contains(q);
                  final matchType =
                      _selectedType == null || type == _selectedType;
                  final matchIndustry =
                      _selectedIndustryId == null ||
                      industryId == _selectedIndustryId;
                  final matchCareer =
                      _selectedCareerId == null ||
                      careerId == _selectedCareerId;

                  return matchSearch &&
                      matchType &&
                      matchIndustry &&
                      matchCareer;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("No documents match filter"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final updatedAt = (data['updatedAt'] as Timestamp?)
                        ?.toDate();
                    final type = (data['type'] ?? '').toString();
                    final title = (data['title'] ?? '').toString();
                    final desc = (data['description'] ?? '').toString();
                    final url = (data['url'] ?? '').toString();
                    final filename = type == "pdf"
                        ? "$title.pdf"
                        : "$title.mp4";
                    final progress = _progressMap[filename];
                    final Color chipColor = type == "pdf"
                        ? Colors.red
                        : Colors.orange;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: chipColor.withOpacity(0.1),
                                  child: Icon(
                                    type == 'mp4'
                                        ? Icons.play_circle_fill
                                        : Icons.picture_as_pdf,
                                    color: chipColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (desc.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                          ),
                                          child: Text(
                                            desc,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      if (updatedAt != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                          ),
                                          child: Text(
                                            "Updated: ${updatedAt.day}/${updatedAt.month}/${updatedAt.year}",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(
                                    type.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: chipColor,
                                  labelStyle: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (type == "pdf")
                                  TextButton.icon(
                                    onPressed: () {
                                      if (url.isNotEmpty)
                                        _downloadFile(context, url, filename);
                                    },
                                    icon: const Icon(Icons.download, size: 18),
                                    label: const Text("Download"),
                                    style: TextButton.styleFrom(
                                      foregroundColor: chipColor,
                                    ),
                                  ),
                                if (type == "mp4")
                                  TextButton.icon(
                                    onPressed: () =>
                                        _openVideo(context, url, title, desc),
                                    icon: const Icon(
                                      Icons.play_arrow,
                                      size: 18,
                                    ),
                                    label: const Text("Play"),
                                    style: TextButton.styleFrom(
                                      foregroundColor: chipColor,
                                    ),
                                  ),
                              ],
                            ),
                            if (progress != null && progress < 100) ...[
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: progress / 100,
                                color: chipColor,
                                backgroundColor: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 4),
                              Text("Downloading: $progress%"),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String? description;

  const VideoPlayerPage({
    super.key,
    required this.videoUrl,
    required this.title,
    this.description,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: false,
          allowFullScreen: true,
          allowMuting: true,
          showControls: true,
        );
        setState(() {});
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _openInYoutube() async {
    final uri = Uri.parse(widget.videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open video externally")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child:
                  _chewieController != null &&
                      _chewieController!
                          .videoPlayerController
                          .value
                          .isInitialized
                  ? Chewie(controller: _chewieController!)
                  : const CircularProgressIndicator(),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.description != null &&
                              widget.description!.isNotEmpty)
                            Text(
                              widget.description!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new, color: Colors.white),
                      onPressed: _openInYoutube,
                      tooltip: "Open externally",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
