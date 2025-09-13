import 'package:flutter/material.dart';

class StoryCard extends StatelessWidget {
  final String storyId;
  final String mainTitle;
  final String subTitle;
  final String? bannerUrl;

  // 👇 Thông tin người tạo
  final String? authorName;
  final String? authorEmail;
  final String? authorAvatar;

  // 👇 Trạng thái chỉ dành cho admin
  final String? status;
  final Widget? footer;
  final bool showStatus;

  const StoryCard({
    super.key,
    required this.storyId,
    required this.mainTitle,
    required this.subTitle,
    this.bannerUrl,
    this.authorName,
    this.authorEmail,
    this.authorAvatar,
    this.status,
    this.footer,
    this.showStatus = false, // 👈 mặc định ẩn cho Public
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(
            context,
            "/story_detail",
            arguments: storyId,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            if (bannerUrl != null && bannerUrl!.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  bannerUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 160,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image,
                        size: 48, color: Colors.grey),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    mainTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Subtitle
                  if (subTitle.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],

                  // 👇 Info người tạo
                  if ((authorName != null && authorName!.isNotEmpty) ||
                      (authorEmail != null && authorEmail!.isNotEmpty)) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: (authorAvatar != null &&
                                  authorAvatar!.isNotEmpty)
                              ? NetworkImage(authorAvatar!)
                              : null,
                          child: (authorAvatar == null ||
                                  authorAvatar!.isEmpty)
                              ? const Icon(Icons.person, size: 20)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authorName ?? "Anonymous",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (authorEmail != null &&
                                authorEmail!.isNotEmpty)
                              Text(
                                authorEmail!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],

                  // 👇 Chỉ admin mới thấy trạng thái
                  if (showStatus && status != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        color: status == "approved"
                            ? Colors.green.withOpacity(0.15)
                            : status == "rejected"
                                ? Colors.red.withOpacity(0.15)
                                : Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status == "approved"
                            ? "Approved"
                            : status == "rejected"
                                ? "Rejected"
                                : "Pending Review",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: status == "approved"
                              ? Colors.green
                              : status == "rejected"
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                      ),
                    ),
                  ],

                  if (footer != null) ...[
                    const Divider(),
                    footer!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
