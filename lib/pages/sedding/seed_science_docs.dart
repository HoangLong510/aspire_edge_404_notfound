import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedScienceDocs() async {
  final fs = FirebaseFirestore.instance;

  // Data Scientist docs
  final dataScientistDocs = [
    {
      "careerId": "data_scientist",
      "careerTitle": "Data Scientist",
      "industry": "it",
      "title": "Career Overview of Data Scientist",
      "type": "pdf",
      "url":
      "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757870356/xu5waea9lbnseyg7ifjj.pdf",
      "description": "Short overview of Data Scientist career.",
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    },
    {
      "careerId": "data_scientist",
      "careerTitle": "Data Scientist",
      "industry": "it",
      "title": "Data Science Pathway",
      "type": "mp4",
      "url":
      "https://res.cloudinary.com/daxpkqhmd/video/upload/v1757870551/2025-09-15-00-21-00_zwrytr.mp4",
      "description": "Step-by-step education and career roadmap for Data Scientists.",
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    },
  ];

  // Research Scientist docs
  final researchScientistDocs = [
    {
      "careerId": "research_scientist",
      "careerTitle": "Research Scientist",
      "industry": "it",
      "title": "Career Overview of Research Scientist",
      "type": "pdf",
      "url":
      "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757870376/ri4f9kmo4obh4fwar2m2.pdf",
      "description": "Short overview of Research Scientist career.",
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    },
    {
      "careerId": "research_scientist",
      "careerTitle": "Research Scientist",
      "industry": "it",
      "title": "Research Science Pathway",
      "type": "mp4",
      "url":
      "https://res.cloudinary.com/daxpkqhmd/video/upload/v1757870551/2025-09-15-00-21-00_zwrytr.mp4",
      "description": "Step-by-step education and career roadmap for Research Scientists.",
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    },
  ];

  // Seed Data Scientist
  for (final doc in dataScientistDocs) {
    await fs
        .collection("CareerBank")
        .doc("data_scientist")
        .collection("Docs")
        .add(doc);
  }

  // Seed Research Scientist
  for (final doc in researchScientistDocs) {
    await fs
        .collection("CareerBank")
        .doc("research_scientist")
        .collection("Docs")
        .add(doc);
  }

  print("✅ Seeded Data Scientist & Research Scientist docs successfully!");
}
