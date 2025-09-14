import 'dart:convert';
import 'package:aspire_edge_404_notfound/constants/env_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String kOpenAIBaseUrl = 'https://api.openai.com/v1';
const String kOpenAIModel = 'gpt-4o-mini';
final String kOpenAIApiKey = EnvConfig.openAIApiKey;

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
    _checkOrGenerateTopStories();
  }

  Future<void> _checkOrGenerateTopStories() async {
    final todayId = DateTime.now().toIso8601String().split("T").first;
    final todayDoc =
        FirebaseFirestore.instance.collection("TopStoriesDaily").doc(todayId);

    final todaySnap = await todayDoc.get();
    if (todaySnap.exists) {
      final data = todaySnap.data() as Map<String, dynamic>;
      final raw = data["storyIds"];

      final ids = raw is List
          ? raw.cast<String>()
          : (raw as Map).values.cast<String>().toList();

      await _loadStoriesByIds(ids);
    } else {
      await _generateTopStories(todayDoc);
    }
  }

  Future<void> _generateTopStories(DocumentReference todayDoc) async {
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection("Stories")
          .where("status", isEqualTo: "approved")
          .get();

      List<Map<String, dynamic>> stories = [];
      for (final doc in snap.docs) {
        final data = doc.data();
        final likesSnap = await doc.reference.collection("likes").get();
        final commentsSnap = await doc.reference.collection("comments").get();

        stories.add({
          "id": doc.id,
          "title": data["subTitle"] ?? "",
          "mainTitle": data["mainTitle"] ?? "",
          "bannerUrl": data["bannerUrl"] ?? "",
          "userId": data["userId"],
          "likes": likesSnap.size,
          "commentCount": commentsSnap.size,
        });
      }

      if (stories.isEmpty) {
        setState(() {
          _stories = [];
          _loading = false;
        });
        return;
      }

      final ranked = await _callOpenAIForTopStories(stories);
      final topIds =
          ranked.take(5).map((e) => e["storyId"] as String).toList();

      // ✅ always store as List<String>
      await todayDoc.set({
        "createdAt": FieldValue.serverTimestamp(),
        "storyIds": List<String>.from(topIds),
      });

      await _loadStoriesByIds(topIds);
    } catch (e) {
      debugPrint("Error generating top stories: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> _loadStoriesByIds(List<String> ids) async {
    try {
      List<Map<String, dynamic>> tmp = [];
      for (final id in ids) {
        final doc =
            await FirebaseFirestore.instance.collection("Stories").doc(id).get();
        if (!doc.exists) continue;
        final data = doc.data()!;
        final likesSnap = await doc.reference.collection("likes").get();
        final commentsSnap = await doc.reference.collection("comments").get();
        final userSnap = await FirebaseFirestore.instance
            .collection("Users")
            .doc(data["userId"])
            .get();
        final user = userSnap.data() ?? {};

        tmp.add({
          "id": doc.id,
          "title": data["subTitle"] ?? "",
          "mainTitle": data["mainTitle"] ?? "",
          "bannerUrl": data["bannerUrl"] ?? "",
          "name": user["Name"] ?? "Anonymous",
          "avatar": user["AvatarUrl"] ?? "",
          "likes": likesSnap.size,
          "commentCount": commentsSnap.size,
        });
      }
      setState(() => _stories = tmp);
    } catch (e) {
      debugPrint("Error loading stories by IDs: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _callOpenAIForTopStories(
      List<Map<String, dynamic>> stories) async {
    if (kOpenAIApiKey.trim().isEmpty) {
      throw Exception('Missing OPENAI_API_KEY');
    }

    const systemPrompt = '''
You are ranking user success stories.
Criteria:
- More likes = higher score
- More positive comments = higher score
Return ONLY JSON in this schema:
{ "matches": [{ "storyId": string, "score": integer }] }
    ''';

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
        {'role': 'user', 'content': jsonEncode({"stories": stories})}
      ],
    });

    final res = await http.post(uri, headers: headers, body: body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('OpenAI HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = (decoded['choices'] as List?) ?? [];
    final content =
        choices.isNotEmpty ? (choices.first['message']?['content'] ?? '') : '';

    final parsed = jsonDecode(content);
    final rawMatches =
        (parsed['matches'] is List) ? parsed['matches'] as List : [];

    rawMatches.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

    return rawMatches.cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_stories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("No top stories yet"),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "Top Success Stories",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 260,
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
                    arguments: s["id"],
                  );
                },
                child: Container(
                  width: 260,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      if ((s["bannerUrl"] as String).isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: Image.network(
                            s["bannerUrl"],
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundImage:
                                        (s["avatar"] as String).isNotEmpty
                                            ? NetworkImage(s["avatar"])
                                            : null,
                                    child: (s["avatar"] as String).isEmpty
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      s["name"],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                s["mainTitle"],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Flexible(
                                child: Text(
                                  s["title"],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.favorite,
                                size: 16, color: Colors.red),
                            const SizedBox(width: 4),
                            Text("${s["likes"]}"),
                            const SizedBox(width: 16),
                            const Icon(Icons.comment,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text("${s["commentCount"]}"),
                          ],
                        ),
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
