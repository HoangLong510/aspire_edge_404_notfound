import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedHealthcareDocs() async {
  final fs = FirebaseFirestore.instance;

  // Registered Nurse docs
  final nurseDocs = [
    {
      "careerId": "registered_nurse",
      "careerTitle": "Registered Nurse",
      "industry": "health",
      "title": "Career Overview of Registered Nurse",
      "type": "pdf",
      "url":
      "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757826003/iezcsf9k6vflbhqdyjnj.pdf",
      "description": "Short overview of Registered Nurse career.",
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    },
    {
      "careerId": "registered_nurse",
      "careerTitle": "Registered Nurse",
      "industry": "health",
      "title": "Nursing Pathway of Registered Nurse",
      "type": "mp4",
      "url":
      "https://res.cloudinary.com/daxpkqhmd/video/upload/v1757735216/2025-09-12-21-20-48_oymlnd.mp4",
      "description": "Step-by-step education and career roadmap for nurses.",
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    },
  ];

  // Pharmacist docs
  final pharmacistDocs = [
    {
      "careerId": "pharmacist",
      "careerTitle": "Pharmacist",
      "industry": "health",
      "title": "Career Overview of Pharmacist",
      "type": "pdf",
      "url":
      "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757828668/pvo2mw7w3p8nqg8svvzh.pdf",
      "description": "Short overview of Pharmacist career.",
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    },
    {
      "careerId": "pharmacist",
      "careerTitle": "Pharmacist",
      "industry": "health",
      "title": "Pharmacy Pathway of Pharmacist",
      "type": "mp4",
      "url":
      "https://res.cloudinary.com/daxpkqhmd/video/upload/v1757735216/2025-09-12-21-20-48_oymlnd.mp4",
      "description": "Step-by-step education and career roadmap for pharmacists.",
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    },
  ];

  // Seed Registered Nurse
  for (final doc in nurseDocs) {
    await fs
        .collection("CareerBank")
        .doc("registered_nurse")
        .collection("Docs")
        .add(doc);
  }

  // Seed Pharmacist
  for (final doc in pharmacistDocs) {
    await fs
        .collection("CareerBank")
        .doc("pharmacist")
        .collection("Docs")
        .add(doc);
  }

  print("✅ Seeded Registered Nurse & Pharmacist docs successfully!");
}
