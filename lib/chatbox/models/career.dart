class Career {
  final String id;
  final String title;
  final String description;
  final String industry;
  final String industryId;
  final String salaryRange;
  final String educationPath;
  final List<String> skills;

  Career({
    required this.id,
    required this.title,
    required this.description,
    required this.industry,
    required this.industryId,
    required this.salaryRange,
    required this.educationPath,
    required this.skills,
  });

  factory Career.fromFirestore(String id, Map<String, dynamic> data) {
    return Career(
      id: id,
      title: data["Title"] ?? "",
      description: data["Description"] ?? "",
      industry: data["Industry"] ?? "",
      industryId: data["IndustryId"] ?? "",
      salaryRange: data["Salary_Range"] ?? "",
      educationPath: data["Education_Path"] ?? "",
      skills: (data["Skills"] is String)
          ? (data["Skills"] as String).split(",").map((e) => e.trim()).toList()
          : List<String>.from(data["Skills"] ?? []),
    );
  }
}
