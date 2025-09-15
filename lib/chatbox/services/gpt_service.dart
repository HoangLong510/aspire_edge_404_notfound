import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class GptService {
  final String apiKey;
  GptService(this.apiKey);

  Future<String> sendToGPT(String text) async {
    final res = await http.post(
      Uri.parse("$kOpenAIBaseUrl/chat/completions"),
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": kOpenAIModel,
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": text},
        ],
      }),
    );

    final decoded = jsonDecode(res.body);

    if (decoded["choices"] != null &&
        decoded["choices"].isNotEmpty &&
        decoded["choices"][0]["message"]?["content"] != null) {
      final reply = decoded["choices"][0]["message"]["content"];

      if (reply.contains("Sorry, I can only help")) {
        return "I can only support career guidance, skills, and Aspire Edge topics. Would you like me to suggest some careers you might explore?";
      }

      return reply;
    } else {
      return "I couldn’t generate a response right now. Please try again with a career-related question.";
    }
  }
}
