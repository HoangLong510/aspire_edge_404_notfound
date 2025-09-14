import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:iconsax/iconsax.dart';

class BlogDetailPage extends StatefulWidget {
  const BlogDetailPage({super.key});

  @override
  State<BlogDetailPage> createState() => _BlogDetailPageState();
}

class _BlogDetailPageState extends State<BlogDetailPage> {
  late VideoPlayerController _videoController;
  bool _isVideoReady = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse("https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4"),
    )
      ..initialize().then((_) {
        setState(() {
          _isVideoReady = true;
        });
        _videoController.setLooping(true);
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const title = "5 Secrets to a Successful Interview";
    const subtitle = "Insights from HR Experts";
    const image =
        "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757492366/career-advice-abstract-concept-illustration_107173-20083_qdqawl.avif";
    const content =
        "In this article, we will explore 5 key tips to pass your interview:\n\n"
        "1. Research the company and position thoroughly.\n\n"
        "2. Practice answering common interview questions.\n\n"
        "3. Dress professionally and appropriately.\n\n"
        "4. Stay confident and communicate clearly.\n\n"
        "5. Ask thoughtful questions to show genuine interest.\n\n"
        "By applying these tips, you can significantly increase your chances of success in an interview.";

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                "Blog Details",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                color: Colors.black45,
                colorBlendMode: BlendMode.darken,
                placeholder: (ctx, url) => Container(
                  color: Colors.black12,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                errorWidget: (ctx, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Iconsax.image, size: 60, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ).animate().fadeIn(duration: 500.ms),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                  ).animate().slideX(begin: -0.2, duration: 500.ms),
                  const Divider(height: 32),
                  Text(
                    content,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                  const SizedBox(height: 32),
                  const Text(
                    "Related Video",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  AspectRatio(
                    aspectRatio: _videoController.value.aspectRatio,
                    child: _isVideoReady
                        ? Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              VideoPlayer(_videoController),
                              VideoProgressIndicator(
                                _videoController,
                                allowScrubbing: true,
                                colors: VideoProgressColors(
                                  playedColor: Colors.blueAccent,
                                ),
                              ),
                              Align(
                                alignment: Alignment.center,
                                child: IconButton(
                                  icon: Icon(
                                    _videoController.value.isPlaying
                                        ? Iconsax.pause
                                        : Iconsax.play,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _videoController.value.isPlaying
                                          ? _videoController.pause()
                                          : _videoController.play();
                                    });
                                  },
                                ),
                              ),
                            ],
                          )
                        : const Center(
                            child: CircularProgressIndicator(),
                          ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, "/career_quiz"),
                      icon: const Icon(Iconsax.play),
                      label: const Text("Take the Quiz 🚀"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ).animate().scale(duration: 400.ms, delay: 400.ms),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
