import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TopStoriesSection extends StatefulWidget {
  const TopStoriesSection({super.key});

  @override
  State<TopStoriesSection> createState() => _TopStoriesSectionState();
}

class _TopStoriesSectionState extends State<TopStoriesSection> {
  List<Map<String, dynamic>> _stories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection("Stories")
          .where("status", isEqualTo: "approved")
          .orderBy("createdAt", descending: true)
          .limit(5)
          .get();

      List<Map<String, dynamic>> tmp = [];
      for (final doc in snap.docs) {
        final data = doc.data();
        final userId = data["userId"];
        final userSnap =
            await FirebaseFirestore.instance.collection("Users").doc(userId).get();
        final user = userSnap.data() ?? {};

        tmp.add({
          "id": doc.id,
          "title": data["subTitle"] ?? "",
          "name": user["Name"] ?? "Anonymous",
          "avatar": user["AvatarUrl"] ?? "",
        });
      }
      setState(() => _stories = tmp);
    } catch (e) {
      debugPrint("Error loading stories: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_stories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("No success stories yet"),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "🌟 Success Stories",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _stories.length,
            itemBuilder: (ctx, i) {
              final s = _stories[i];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    "/story_detail",
                    arguments: s["id"], // 👈 gửi storyId qua detail
                  );
                },
                child: Container(
                  width: 240,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: (s["avatar"] as String).isNotEmpty
                                ? NetworkImage(s["avatar"])
                                : null,
                            radius: 22,
                            child: (s["avatar"] as String).isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s["name"],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        s["title"],
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.grey[700], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
