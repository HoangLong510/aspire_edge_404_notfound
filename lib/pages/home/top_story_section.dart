import 'dart:convert';
import 'package:aspire_edge_404_notfound/constants/env_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// ===========================
/// OpenAI config
/// ===========================
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
    _loadStories();
  }

  Future<void> _loadStories() async {
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

      // 👉 Gọi GPT để rank
      final ranked = await _callOpenAIForTopStories(stories);

      // lấy top 5 id
      final topIds = ranked.take(5).map((e) => e["storyId"]).toList();

      // join lại thông tin user
      List<Map<String, dynamic>> tmp = [];
      for (final story in stories.where((s) => topIds.contains(s["id"]))) {
        final userSnap = await FirebaseFirestore.instance
            .collection("Users")
            .doc(story["userId"])
            .get();
        final user = userSnap.data() ?? {};
        tmp.add({
          "id": story["id"],
          "title": story["title"],
          "name": user["Name"] ?? "Anonymous",
          "avatar": user["AvatarUrl"] ?? "",
          "likes": story["likes"],
          "commentCount": story["commentCount"],
        });
      }

      setState(() => _stories = tmp);
    } catch (e) {
      debugPrint("Error loading top stories: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _callOpenAIForTopStories(
      List<Map<String, dynamic>> stories) async {
    if (kOpenAIApiKey.trim().isEmpty) {
      throw Exception(
          'Missing OPENAI_API_KEY. Pass it via --dart-define=OPENAI_API_KEY=...');
    }

    final systemPrompt = '''
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
        {
          'role': 'user',
          'content': jsonEncode({"stories": stories}),
        }
      ],
    });

    final res = await http.post(uri, headers: headers, body: body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('OpenAI HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = (decoded['choices'] as List?) ?? [];
    final content = choices.isNotEmpty
        ? (choices.first['message']?['content'] ?? '')
        : '';

    final parsed = jsonDecode(content);
    final rawMatches =
        (parsed['matches'] is List) ? parsed['matches'] as List : [];

    rawMatches.sort(
        (a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

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
            "🌟 Top Success Stories",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 200,
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
                      const Spacer(),
                      Row(
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
