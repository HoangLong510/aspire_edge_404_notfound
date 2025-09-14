class ChatMessage {
  final String role; // "user", "ai", "loading"
  final String content;
  final List<String>? suggestions;

  ChatMessage({
    required this.role,
    required this.content,
    this.suggestions,
  });

  Map<String, dynamic> toJson() => {
        "role": role,
        "content": content,
        "suggestions": suggestions,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json["role"],
      content: json["content"],
      suggestions: (json["suggestions"] as List?)?.cast<String>(),
    );
  }
}
