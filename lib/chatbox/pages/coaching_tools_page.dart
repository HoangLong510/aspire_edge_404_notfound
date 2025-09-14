import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/message.dart';
import '../models/team_member.dart';
import '../services/chat_router.dart';
import '../services/career_service.dart';
import '../services/gpt_service.dart';
import '../services/team_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/suggestion_chip.dart';
import '../../constants/env_config.dart';

enum ChatMode { normal, inQuiz, careerInfo }

class CoachingChatPage extends StatefulWidget {
  const CoachingChatPage({super.key});

  @override
  State<CoachingChatPage> createState() => _CoachingChatPageState();
}

class _CoachingChatPageState extends State<CoachingChatPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  final ChatRouter _router = ChatRouter();
  final CareerService _careerService = CareerService();
  final GptService _gpt = GptService(EnvConfig.openAIApiKey);

  ChatMode _mode = ChatMode.normal;
  int _currentQuizIndex = -1;
  List<Map<String, dynamic>> _quizQuestions = [];

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList("chat_history") ?? [];
    setState(() {
      _messages
        ..clear()
        ..addAll(saved.map((e) => ChatMessage.fromJson(jsonDecode(e))));
    });
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _messages.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList("chat_history", data);
  }

  Future<void> _startInChatQuiz(String tier) async {
    _quizQuestions = await _careerService.getQuizQuestions(tier);

    if (_quizQuestions.isEmpty) {
      final fallback = await _careerService.getCareerFallbackQuiz();
      _quizQuestions = fallback;
    }

    _mode = ChatMode.inQuiz;
    _currentQuizIndex = 0;
    _askQuizQuestion();
  }

  void _askQuizQuestion() {
    final q = _quizQuestions[_currentQuizIndex];
    setState(() {
      _messages.add(ChatMessage(
        role: "ai",
        content: q["text"],
        suggestions: (q["options"] as List).cast<String>(),
      ));
    });
  }

  Future<void> _handleQuizAnswer(String answer) async {
    _messages.add(ChatMessage(role: "user", content: answer));

    _currentQuizIndex++;
    if (_currentQuizIndex < _quizQuestions.length) {
      _askQuizQuestion();
    } else {
      _mode = ChatMode.normal;
      setState(() {
        _messages.add(ChatMessage(
          role: "ai",
          content: "✅ Quiz completed! I will now suggest careers that may fit you.",
        ));
      });
    }
  }

  Future<void> _handleCareerRequest(String title) async {
    final details = await _careerService
        .getCareerDetails(title.toLowerCase().replaceAll(" ", "_"));

    if (details.isEmpty) {
      setState(() {
        _messages.add(ChatMessage(
          role: "ai",
          content: "Sorry, no data available for $title yet.",
        ));
      });
      return;
    }

    final career = details["career"];
    final paths = details["paths"];

    setState(() {
      _messages.add(ChatMessage(
        role: "ai",
        content: "${career.title} (${career.industry})\n"
            "Skills: ${career.skills.join(", ")}\n"
            "Salary: ${career.salaryRange}\n"
            "Description: ${career.description}",
      ));
    });

    for (final level in paths) {
      setState(() {
        _messages.add(ChatMessage(
          role: "ai",
          content: "➡️ ${level.levelName}: ${level.description}\n"
              "Skills: ${level.skills.join(", ")}\n"
              "Salary: ${level.salaryRange}",
        ));
      });
    }

    setState(() {
      _messages.add(ChatMessage(
        role: "ai",
        content: "Do you want to open the detailed page for $title?",
        suggestions: ["Open page $title"],
      ));
    });

    _mode = ChatMode.careerInfo;
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    if (_mode == ChatMode.inQuiz) {
      await _handleQuizAnswer(text);
      return;
    }

    if (text.startsWith("Open page")) {
      final careerName = text.replaceAll("Open page ", "");
      Navigator.pushNamed(
        context,
        "/career_detail",
        arguments: careerName.toLowerCase().replaceAll(" ", "_"),
      );
      return;
    }

    final topic = await _router.detectTopic(text);
    final result = await _router.handleRequest(topic, text);

    switch (result["action"]) {
      case "quiz":
        await _startInChatQuiz(result["tier"]);
        break;
      case "career":
        await _handleCareerRequest(result["title"]);
        break;
      case "team":
        final info = result["data"];
        final List<TeamMember> members = info["members"];
        setState(() {
          _messages.add(ChatMessage(
            role: "ai",
            content: "Meet our team:\n" +
                members.map((m) => "${m.name} - ${m.email}").join("\n"),
          ));
        });
        break;
      default:
        await _sendToGPT(text);
    }

    _controller.clear();
  }

  Future<void> _sendToGPT(String text) async {
    setState(() {
      _messages.add(ChatMessage(role: "user", content: text));
      _messages.add(ChatMessage(role: "loading", content: ""));
      _loading = true;
    });

    try {
      final reply = await _gpt.sendToGPT(text);

      setState(() {
        _messages.removeWhere((m) => m.role == "loading");
        _messages.add(ChatMessage(role: "ai", content: reply));
      });
    } catch (e) {
      setState(() {
        _messages.removeWhere((m) => m.role == "loading");
        _messages.add(ChatMessage(
          role: "ai",
          content: "Something went wrong. Please try again later.",
        ));
      });
    } finally {
      _loading = false;
      await _saveChatHistory();
    }
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  crossAxisAlignment:
                      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                          child: ChatBubble(
                            msg: msg,
                            isUser: isUser,
                            index: index,
                            onDelete: () async {
                              setState(() => _messages.removeAt(index));
                              await _saveChatHistory();
                            },
                          ),
                        ),
                      ],
                    ),
                    if (msg.suggestions != null && msg.suggestions!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: msg.suggestions!
                            .map((s) => SuggestionChip(
                                  label: s,
                                  onTap: () => _sendMessage(s),
                                ))
                            .toList(),
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
