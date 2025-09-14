class CareerPath {
  final String levelName;
  final String description;
  final int levelOrder;
  final String salaryRange;
  final List<String> skills;

  CareerPath({
    required this.levelName,
    required this.description,
    required this.levelOrder,
    required this.salaryRange,
    required this.skills,
  });

  factory CareerPath.fromFirestore(Map<String, dynamic> data) {
    return CareerPath(
      levelName: data["Level_Name"] ?? "",
      description: data["Description"] ?? "",
      levelOrder: data["Level_Order"] ?? 0,
      salaryRange: data["Salary_Range"] ?? "",
      skills: List<String>.from(data["Skills"] ?? []),
    );
  }
}
