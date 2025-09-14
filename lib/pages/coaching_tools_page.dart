import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aspire_edge_404_notfound/constants/env_config.dart';

const String kOpenAIBaseUrl = 'https://api.openai.com/v1';
const String kOpenAIModel = 'gpt-4o-mini';
final String kOpenAIApiKey = EnvConfig.openAIApiKey;

const String systemPrompt = """
You are Aspire Edge's career assistant.
You only provide:
- Career guidance
- Skill recommendations
- CV and resume advice
- Interview tips
- Career path orientation

Never answer topics unrelated to careers or the Aspire Edge app.
If asked something outside these areas, reply:
"Sorry, I can only help with career guidance and Aspire Edge app related topics."
""";

enum ChatMode { normal, inQuiz, careerInfo }

class CoachingChatPage extends StatefulWidget {
  const CoachingChatPage({super.key});

  @override
  State<CoachingChatPage> createState() => _CoachingChatPageState();
}

class _CoachingChatPageState extends State<CoachingChatPage> {
  final List<_Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  ChatMode _mode = ChatMode.normal;
  int _currentQuizIndex = -1;
  List<Map<String, dynamic>> _quizQuestions = [];

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<Map<String, dynamic>> _getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};
    final snap =
        await FirebaseFirestore.instance.collection("Users").doc(uid).get();
    if (!snap.exists) return {};
    return snap.data() ?? {};
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList("chat_history") ?? [];
    setState(() {
      _messages.clear();
      _messages.addAll(saved.map((e) {
        final map = jsonDecode(e) as Map<String, dynamic>;
        return _Message(
          role: map['role'],
          content: map['content'],
          suggestions: (map['suggestions'] as List?)?.cast<String>(),
        );
      }));
    });
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _messages
        .map((m) => jsonEncode({
              'role': m.role,
              'content': m.content,
              'suggestions': m.suggestions,
            }))
        .toList();
    await prefs.setStringList("chat_history", data);
  }

  // ==========================================================
  // QUIZ
  // ==========================================================
  Future<List<Map<String, dynamic>>> _getQuizQuestions(String tier) async {
    final snap = await FirebaseFirestore.instance
        .collection("Questions")
        .where("Tier", isEqualTo: tier)
        .limit(5)
        .get();

    if (snap.docs.isEmpty) return [];
    return snap.docs.map((d) {
      final data = d.data();
      final options = (data["Options"] as Map).values
          .map((o) => o["Text"].toString())
          .toList();
      return {"text": data["Text"], "options": options};
    }).toList();
  }

  Future<void> _startInChatQuiz(String tier) async {
    _quizQuestions = await _getQuizQuestions(tier);

    if (_quizQuestions.isEmpty) {
      final careers =
          await FirebaseFirestore.instance.collection("CareerBank").get();
      _quizQuestions = careers.docs.map((d) {
        final title = d.data()["Title"];
        return {
          "text": "Would you be interested in exploring the $title career?",
          "options": ["Yes", "Maybe", "Not interested"]
        };
      }).toList();
    }

    _mode = ChatMode.inQuiz;
    _currentQuizIndex = 0;
    _askQuizQuestion();
  }

  void _askQuizQuestion() {
    final q = _quizQuestions[_currentQuizIndex];
    setState(() {
      _messages.add(_Message(
        role: "ai",
        content: q["text"],
        suggestions: (q["options"] as List).cast<String>(),
      ));
    });
  }

  Future<void> _handleQuizAnswer(String answer) async {
    _messages.add(_Message(role: "user", content: answer));

    _currentQuizIndex++;
    if (_currentQuizIndex < _quizQuestions.length) {
      _askQuizQuestion();
    } else {
      _mode = ChatMode.normal;
      setState(() {
        _messages.add(_Message(
          role: "ai",
          content:
              "✅ Quiz completed! I will now suggest careers that may fit you.",
        ));
      });
      // TODO: save answers to Firestore CareerMatches
    }
  }

  // ==========================================================
  // CAREER INFO
  // ==========================================================
  Future<Map<String, dynamic>> _getCareerDetails(String careerId) async {
    final doc = await FirebaseFirestore.instance
        .collection("CareerBank")
        .doc(careerId)
        .get();

    if (!doc.exists) return {};

    final careerData = doc.data()!;
    final pathsSnap = await FirebaseFirestore.instance
        .collection("CareerBank")
        .doc(careerId)
        .collection("CareerPaths")
        .orderBy("Level_Order")
        .get();

    final paths = pathsSnap.docs.map((d) => d.data()).toList();

    return {
      "career": careerData,
      "paths": paths,
    };
  }

  Future<void> _handleCareerRequest(String title) async {
    final id = title.toLowerCase().replaceAll(" ", "_");
    final details = await _getCareerDetails(id);

    if (details.isEmpty) {
      setState(() {
        _messages.add(_Message(
            role: "ai", content: "Sorry, no data available for $title yet."));
      });
      return;
    }

    final c = details["career"];
    final paths = details["paths"] as List;

    setState(() {
      _messages.add(_Message(
        role: "ai",
        content: "${c["Title"]} (${c["Industry"]})\n"
            "Skills: ${c["Skills"]}\n"
            "Salary: ${c["Salary_Range"]}\n"
            "Description: ${c["Description"]}",
      ));
    });

    for (final level in paths) {
      setState(() {
        _messages.add(_Message(
          role: "ai",
          content: "➡️ ${level["Level_Name"]}: ${level["Description"]}\n"
              "Skills: ${level["Skills"]}\n"
              "Salary: ${level["Salary_Range"]}",
        ));
      });
    }

    setState(() {
      _messages.add(_Message(
        role: "ai",
        content: "Do you want to open the detailed page for $title?",
        suggestions: ["Open page $title"],
      ));
    });

    _mode = ChatMode.careerInfo;
  }

  // ==========================================================
  // GPT FALLBACK
  // ==========================================================
  Future<void> _sendToGPT(String text) async {
    setState(() {
      _messages.add(_Message(role: "user", content: text));
      _messages.add(_Message(role: "loading", content: ""));
      _loading = true;
    });

    try {
      final res = await http.post(
        Uri.parse("$kOpenAIBaseUrl/chat/completions"),
        headers: {
          "Authorization": "Bearer $kOpenAIApiKey",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "model": kOpenAIModel,
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": text}
          ]
        }),
      );

      final decoded = jsonDecode(res.body);

      String reply;
      if (decoded["choices"] != null &&
          decoded["choices"].isNotEmpty &&
          decoded["choices"][0]["message"]?["content"] != null) {
        reply = decoded["choices"][0]["message"]["content"];
      } else {
        reply =
            "⚠️ Sorry, I couldn’t generate a response right now. Please try again.";
      }

      // If reply contains the "Sorry..." → add hints
      if (reply.contains("Sorry")) {
        final careers =
            await FirebaseFirestore.instance.collection("CareerBank").get();
        final suggestions = careers.docs
            .map((d) => d.data()["Title"]?.toString() ?? "")
            .where((t) => t.isNotEmpty)
            .take(3)
            .map((t) => "Tell me more about $t")
            .toList();

        setState(() {
          _messages.removeWhere((m) => m.role == "loading");
          _messages.add(
              _Message(role: "ai", content: reply, suggestions: suggestions));
        });
      } else {
        setState(() {
          _messages.removeWhere((m) => m.role == "loading");
          _messages.add(_Message(role: "ai", content: reply));
        });
      }
    } catch (e) {
      setState(() {
        _messages.removeWhere((m) => m.role == "loading");
        _messages.add(_Message(role: "ai", content: "⚠️ Error: $e"));
      });
    } finally {
      _loading = false;
      await _saveChatHistory();
    }
  }

  // ==========================================================
  // DISPATCHER
  // ==========================================================
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    if (_mode == ChatMode.inQuiz) {
      await _handleQuizAnswer(text);
      return;
    }

    if (text.startsWith("Open page")) {
      final careerName = text.replaceAll("Open page ", "");
      Navigator.pushNamed(context, "/career_detail",
          arguments: careerName.toLowerCase().replaceAll(" ", "_"));
      return;
    }

    if (text.toLowerCase().contains("tell me more about")) {
      final career = text.split("about ").last;
      await _handleCareerRequest(career);
      return;
    }

    await _sendToGPT(text);
    _controller.clear(); // clear input after send
  }

  // ==========================================================
  // UI
  // ==========================================================
  Widget _buildBubble(_Message msg,
      {required bool isUser, required int index}) {
    return GestureDetector(
      onLongPress: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Delete message"),
              content: const Text("Do you want to delete this message?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Delete"),
                ),
              ],
            );
          },
        );

        if (confirm == true) {
          setState(() {
            _messages.removeAt(index);
          });
          await _saveChatHistory();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[200] : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Text(
          msg.content,
          style: TextStyle(color: Colors.grey[900], fontSize: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Career Assistant"),
        actions: [
  Padding(
    padding: const EdgeInsets.only(right: 12),
    child: ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red, 
        foregroundColor: Colors.white, 
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove("chat_history");
        setState(() => _messages.clear());
      },
      icon: const Icon(Icons.delete_forever, size: 18),
      label: const Text("Clear", style: TextStyle(fontSize: 14)),
    ),
  ),
],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.role == "user";
                final isBot = msg.role == "ai" || msg.role == "loading";

                if (msg.role == "loading") {
                  return Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(
                          "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757825848/dpcr7z0mtiqobc63r6n4.png",
                        ),
                      ),
                      const SizedBox(width: 8),
                      Lottie.asset("assets/lottie/loading_chat.json",
                          width: 60, height: 40),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (isBot)
                          const CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(
                              "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757825848/dpcr7z0mtiqobc63r6n4.png",
                            ),
                          ),
                        if (isBot) const SizedBox(width: 8),
                        Flexible(
                            child: _buildBubble(msg,
                                isUser: isUser, index: index)),
                      ],
                    ),
                    if (msg.suggestions != null &&
                        msg.suggestions!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: msg.suggestions!.map((s) {
                          return ActionChip(
                            label: Text(s),
                            onPressed: () => _sendMessage(s),
                          );
                        }).toList(),
                      ),
                    ]
                  ],
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Ask about your career...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _loading
                          ? null
                          : () => _sendMessage(_controller.text.trim()),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _Message {
  final String role;
  final String content;
  final List<String>? suggestions;

  _Message({required this.role, required this.content, this.suggestions});
}
