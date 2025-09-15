import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/career.dart';
import '../models/career_path.dart';

class CareerService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<String> getUserTier() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return "";

      final doc = await _firestore.collection("Users").doc(uid).get();
      if (!doc.exists) return "";

      return doc.data()?["Tier"]?.toString() ?? "";
    } catch (e) {
      return "";
    }
  }

  Future<List<Map<String, dynamic>>> getQuizQuestions(String tier) async {
    try {
      final snap = await _firestore
          .collection("Questions")
          .where("Tier", isEqualTo: tier)
          .limit(5)
          .get();

      if (snap.docs.isEmpty) return [];

      return snap.docs.map((d) {
        final data = d.data();
        final options = (data["Options"] as Map).values
            .map((o) => o["Text"].toString())
            .toList();

        return {"text": data["Text"], "options": options};
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCareerFallbackQuiz() async {
    try {
      final careers = await _firestore.collection("CareerBank").get();

      return careers.docs.map((d) {
        final title = d.data()["Title"];
        return {
          "text": "Would you be interested in exploring the $title career?",
          "options": ["Yes", "Maybe", "Not interested"],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getCareerDetails(String careerId) async {
    try {
      final doc = await _firestore.collection("CareerBank").doc(careerId).get();
      if (!doc.exists) return {};

      final career = Career.fromFirestore(doc.id, doc.data()!);

      final pathsSnap = await _firestore
          .collection("CareerBank")
          .doc(careerId)
          .collection("CareerPaths")
          .orderBy("Level_Order")
          .get();

      final paths = pathsSnap.docs
          .map((d) => CareerPath.fromFirestore(d.data()))
          .toList();

      return {"career": career, "paths": paths};
    } catch (e) {
      return {};
    }
  }

  Future<List<Career>> getAllCareers() async {
    try {
      final snap = await _firestore.collection("CareerBank").get();
      return snap.docs
          .map((d) => Career.fromFirestore(d.id, d.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
