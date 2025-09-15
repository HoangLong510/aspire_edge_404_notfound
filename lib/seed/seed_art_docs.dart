import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedArtDocs() async {
  final fs = FirebaseFirestore.instance;

  // =============== Illustrator ===============
  final illustratorDocs = [
    {
      "careerId": "illustrator",
      "careerTitle": "Illustrator",
      "industry": "art",
      "title": "Career Overview of Illustrator",
      "type": "pdf",
      "url": "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757831549/rccdmskc2gfrlvqijr8h.pdf",
      "description": "Short overview of Illustrator career.",
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    },
    {
      "careerId": "illustrator",
      "careerTitle": "Illustrator",
      "industry": "art",
      "title": "Learning Path of Illustrator",
      "type": "mp4",
      "url": "https://res.cloudinary.com/daxpkqhmd/video/upload/v1757735216/2025-09-12-21-20-48_oymlnd.mp4",
      "description": "Step-by-step roadmap to becoming an Illustrator.",
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    },
  ];

  for (final doc in illustratorDocs) {
    await fs.collection("CareerBank").doc("illustrator").collection("Docs").add(doc);
  }

  // =============== Graphic Designer ===============
  final graphicDesignerDocs = [
    {
      "careerId": "graphic_designer",
      "careerTitle": "Graphic Designer",
      "industry": "art",
      "title": "Career Overview of Graphic Designer",
      "type": "pdf",
      "url": "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757831562/mwejkltl2ubbavyahxfm.pdf",
      "description": "Short overview of Graphic Designer career.",
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    },
    {
      "careerId": "graphic_designer",
      "careerTitle": "Graphic Designer",
      "industry": "art",
      "title": "Learning Path of Graphic Designer",
      "type": "mp4",
      "url": "https://res.cloudinary.com/daxpkqhmd/video/upload/v1757735216/2025-09-12-21-20-48_oymlnd.mp4",
      "description": "Step-by-step roadmap to becoming a Graphic Designer.",
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    },
  ];

  for (final doc in graphicDesignerDocs) {
    await fs.collection("CareerBank").doc("graphic_designer").collection("Docs").add(doc);
  }
}
