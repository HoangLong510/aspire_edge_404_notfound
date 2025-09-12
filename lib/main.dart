import 'dart:async';

import 'package:aspire_edge_404_notfound/layouts/main_layout.dart';
import 'package:aspire_edge_404_notfound/pages/about_us_page.dart';
import 'package:aspire_edge_404_notfound/pages/achievements_slider_page.dart';
import 'package:aspire_edge_404_notfound/pages/admin_panel_page.dart';
import 'package:aspire_edge_404_notfound/pages/answer_quiz_page.dart';
import 'package:aspire_edge_404_notfound/pages/career_manage_page.dart';
import 'package:aspire_edge_404_notfound/pages/career_matches_page.dart';
import 'package:aspire_edge_404_notfound/pages/career_quiz_page.dart';
import 'package:aspire_edge_404_notfound/pages/change_password_page.dart';
import 'package:aspire_edge_404_notfound/pages/coaching_tools_page.dart';
import 'package:aspire_edge_404_notfound/pages/contact/contact_us_page.dart';
import 'package:aspire_edge_404_notfound/pages/create_quiz_page.dart';
import 'package:aspire_edge_404_notfound/pages/edit_quiz_page.dart';
import 'package:aspire_edge_404_notfound/pages/home/blog_detail_page.dart';
import 'package:aspire_edge_404_notfound/pages/home/cv_tip_detail_page.dart';
import 'package:aspire_edge_404_notfound/pages/home/interview_question_detail_page.dart';
import 'package:aspire_edge_404_notfound/pages/home_page.dart';
import 'package:aspire_edge_404_notfound/pages/login_page.dart';
import 'package:aspire_edge_404_notfound/pages/profile_page.dart';
import 'package:aspire_edge_404_notfound/pages/quiz_management_page.dart';
import 'package:aspire_edge_404_notfound/pages/register_page.dart';
import 'package:aspire_edge_404_notfound/pages/resource_hub_page.dart';
import 'package:aspire_edge_404_notfound/pages/seed_achievements_page.dart';
import 'package:aspire_edge_404_notfound/pages/testimonials_page.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

/// Keep user + tier + hasMatches at top-level for simple checks in routes
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  Widget withLayout(Widget body, String route) =>
      MainLayout(body: body, currentPageRoute: route);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? _user;
  String _tier = ''; // empty => not admin by default
  bool _userDocReady = false;
  bool _hasMatches = false;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
      _user = u;
      _userDocSub?.cancel();
      _userDocReady = false;
      _tier = '';
      _hasMatches = false;

      if (u != null) {
        _userDocSub = FirebaseFirestore.instance
            .collection('Users')
            .doc(u.uid)
            .snapshots()
            .listen((snap) {
          final data = snap.data();
          _tier = (data?['Tier'] ?? '').toString();
          final matches = (data?['CareerMatches'] as List?) ?? const [];
          _hasMatches = matches.isNotEmpty;
          _userDocReady = true;
          if (mounted) setState(() {});
        });
      } else {
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _tier.toLowerCase() == 'admin';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Aspire Edge",
      theme: ThemeData(
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      initialRoute: FirebaseAuth.instance.currentUser == null ? '/login' : '/',
      routes: {
        // Auth
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/change-password': (context) => const ChangePasswordPage(),

        // Main pages
        '/': (context) => widget.withLayout(const HomePage(), '/'),
        '/profile': (context) => widget.withLayout(const ProfilePage(), '/profile'),
        '/career_quiz': (context) =>
            widget.withLayout(const CareerQuizPage(), '/career_quiz'),
        '/career_bank': (context) =>
            widget.withLayout(CareerManagePage(), '/career_bank'),

        // Career matches logic
        '/career_matches': (context) {
          if (isAdmin) {
            return widget.withLayout(const QuizManagementPage(), '/career_matches');
          }
          if (_user == null) {
            return widget.withLayout(const CareerQuizPage(), '/career_matches');
          }
          if (!_userDocReady) {
            return widget.withLayout(
              const Center(child: CircularProgressIndicator()),
              '/career_matches',
            );
          }
          return widget.withLayout(
            _hasMatches ? const CareerMatchesPage() : const CareerQuizPage(),
            '/career_matches',
          );
        },

        // Quiz authoring / admin
        '/create_quiz': (context) =>
            widget.withLayout(const CreateQuizPage(), '/create_quiz'),
        '/edit_quiz': (context) =>
            widget.withLayout(const EditQuizPage(), '/edit_quiz'),
        '/quiz_management': (context) =>
            widget.withLayout(const QuizManagementPage(), '/quiz_management'),
        '/admin_panel': (context) =>
            widget.withLayout(const AdminPanelPage(), '/admin_panel'),

        // Tools & resources
        '/coaching_tools': (context) =>
            widget.withLayout(const CoachingToolsPage(), '/coaching_tools'),
        '/resource_hub': (context) =>
            widget.withLayout(const ResourceHubPage(), '/resource_hub'),
        '/testimonials': (context) =>
        '/contact_us': (context) => withLayout(const ContactUsPage(), '/contact_us'),
        '/admin_panel': (context) =>
            withLayout(const AdminPanelPage(), '/admin_panel'),

            widget.withLayout(const TestimonialsPage(), '/testimonials'),
        '/feedback_form': (context) =>
            widget.withLayout(const FeedbackFormPage(), '/feedback_form'),
        '/about_us': (context) =>
            widget.withLayout(const AboutUsPage(), '/about_us'),

        // Achievements
        '/achievements': (context) => const AchievementsSliderPage(),
        '/seed_achievements': (context) =>
            widget.withLayout(const SeedAchievementsPage(), '/seed_achievements'),

        // Answer quiz page (standalone route)
        '/answer_quiz': (context) => MainLayout(
              body: const AnswerQuizPage(),
              currentPageRoute: "/answer_quiz",
            ),

        // Detail pages (không bọc layout nếu bạn muốn full-screen riêng)
        '/cv_detail': (context) => const CVTipDetailPage(),
        '/interview_detail': (context) => const InterviewQuestionDetailPage(),
        '/blog_detail': (context) => const BlogDetailPage(),
      },
    );
  }
}
