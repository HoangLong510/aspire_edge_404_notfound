import 'career_service.dart';
import 'team_service.dart';

class ChatRouter {
  final CareerService _careerService = CareerService();
  final TeamService _teamService = TeamService();

  Future<String> detectTopic(String text) async {
    final lower = text.toLowerCase();

    if (lower.contains("quiz") || lower.contains("test")) {
      return "quiz";
    }
    if (lower.contains("career") ||
        lower.contains("job") ||
        lower.contains("about career")) {
      return "career";
    }
    if (lower.contains("team") || lower.contains("aspire edge")) {
      return "team";
    }
    return "fallback";
  }

  Future<Map<String, dynamic>> handleRequest(String topic, String text) async {
    switch (topic) {
      case "quiz":
        final tier = await _careerService.getUserTier();
        return {"action": "quiz", "tier": tier};

      case "career":
        String careerTitle = "";
        if (text.toLowerCase().contains("about")) {
          careerTitle = text.split("about").last.trim();
        } else {
          careerTitle = text.trim();
        }

        if (careerTitle.isEmpty) {
          return {"action": "fallback"};
        }
        return {"action": "career", "title": careerTitle};

      case "team":
        return {"action": "team", "data": TeamService.getTeamInfo()};

      default:
        return {"action": "fallback"};
    }
  }
}
