import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class CareerDocsPage extends StatefulWidget {
  final String careerId;
  const CareerDocsPage({super.key, required this.careerId});

  @override
  State<CareerDocsPage> createState() => _CareerDocsPageState();
}

class _CareerDocsPageState extends State<CareerDocsPage> {
  final Map<String, int> _progressMap = {};
  final Dio _dio = Dio();

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

    Directory dir;
    if (Platform.isAndroid) {
      dir = (await getExternalStorageDirectory())!;
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

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
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Career Resources"),
        centerTitle: true,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("CareerBank")
            .doc(widget.careerId)
            .collection("Docs")
            .orderBy("updatedAt", descending: true)
            .snapshots(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No resources available"));
          }

          final pdfDocs = docs.where((d) => d['type'] == 'pdf').toList();
          final videoDocs = docs.where((d) => d['type'] == 'mp4').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pdfDocs.isNotEmpty) ...[
                Text(
                  "PDF Documents",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...pdfDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString();
                  final desc = (data['description'] ?? '').toString();
                  final url = (data['url'] ?? '').toString();
                  final filename = "$title.pdf";
                  final progress = _progressMap[filename];

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.redAccent,
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(desc),
                          trailing: IconButton(
                            icon: const Icon(Icons.download),
                            color: primary,
                            onPressed: () {
                              if (url.isNotEmpty) {
                                _downloadFile(context, url, filename);
                              }
                            },
                          ),
                        ),
                        if (progress != null && progress < 100)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                LinearProgressIndicator(
                                  value: progress / 100,
                                  color: primary,
                                  backgroundColor: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 4),
                                Text("Downloading: $progress%"),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
              if (videoDocs.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text("Videos", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...videoDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString();
                  final desc = (data['description'] ?? '').toString();
                  final url = (data['url'] ?? '').toString();

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.video_library, color: primary),
                      title: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(desc),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        color: primary,
                        onPressed: () => _openVideo(context, url, title, desc),
                      ),
                    ),
                  );
                }),
              ],
            ],
          );
        },
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
        const SnackBar(content: Text("Could not open video in external app")),
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
                      tooltip: "Open in YouTube / Browser",
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
