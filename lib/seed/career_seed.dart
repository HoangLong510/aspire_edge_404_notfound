import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedSoftwareDeveloper() async {
  final fs = FirebaseFirestore.instance;
  const careerId = "software_developer";

  // Tạo career chính
  await fs.collection("CareerBank").doc(careerId).set({
    "Title": "Software Developer",
    "IndustryId": "it",
    "Industry": "Information Technology",
    "Description": "Designs, builds, and maintains software systems and applications.",
    "Skills": "Programming, Problem-solving, System Design, Debugging",
    "Salary_Range": "\$60,000 - \$120,000 / year",
    "Education_Path": "Bachelor's in Computer Science, coding bootcamps, online certifications",
    "createdAt": FieldValue.serverTimestamp(),
    "updatedAt": FieldValue.serverTimestamp(),
  });

  // Thêm levels
  final levels = [
    {
      "Level_Name": "Junior Developer",
      "Salary_Range": "\$60,000 - \$75,000 / year",
      "Description": "Assist in writing code, debugging, and learning project workflows.",
      "Skills": ["Basic programming", "Git", "Collaboration"],
      "Level_Order": 1,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    },
    {
      "Level_Name": "Mid-level Developer",
      "Salary_Range": "\$75,000 - \$95,000 / year",
      "Description": "Work independently on modules, optimize code, and mentor juniors.",
      "Skills": ["System design basics", "Debugging", "Code reviews"],
      "Level_Order": 2,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    },
    {
      "Level_Name": "Senior Developer",
      "Salary_Range": "\$95,000 - \$120,000 / year",
      "Description": "Lead projects, design architecture, and guide the development team.",
      "Skills": ["Architecture design", "Leadership", "Advanced programming"],
      "Level_Order": 3,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    },
  ];

  for (final level in levels) {
    await fs.collection("CareerBank").doc(careerId).collection("CareerPaths").add(level);
  }

  // Thêm docs
  final docs = [
    {
      "careerId": "software_developer",
      "careerTitle": "Software Developer",
      "industry":"it",
      "title": "Career Overview",
      "type": "pdf",
      "url": "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757678301/TECHWIZ_CARROUSSAL_copy_1_zz2woo.pdf",
      "description": "Short overview of Software Developer career.",
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    },
    {
      "careerId": "software_developer",
      "careerTitle": "Software Developer",
      "industry":"it",
      "title": "Learning Path",
      "type": "mp4",
      "url": "https://res.cloudinary.com/daxpkqhmd/video/upload/v1757735216/2025-09-12-21-20-48_oymlnd.mp4",
      "description": "Step-by-step education and career roadmap.",
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    },
  ];

  for (final doc in docs) {
    await fs.collection("CareerBank").doc(careerId).collection("Docs").add(doc);
  }
}
