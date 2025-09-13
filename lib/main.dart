import 'dart:async';

import 'package:aspire_edge_404_notfound/layouts/main_layout.dart';
import 'package:aspire_edge_404_notfound/pages/about_us_page.dart';
import 'package:aspire_edge_404_notfound/pages/achievements_slider_page.dart';
import 'package:aspire_edge_404_notfound/pages/admin_panel_page.dart';
import 'package:aspire_edge_404_notfound/pages/answer_quiz_page.dart';
import 'package:aspire_edge_404_notfound/pages/career_docs_all_page.dart';
import 'package:aspire_edge_404_notfound/pages/career_manage_page.dart';
import 'package:aspire_edge_404_notfound/pages/career_quiz_page.dart';
import 'package:aspire_edge_404_notfound/pages/change_password_page.dart';
import 'package:aspire_edge_404_notfound/pages/coaching_tools_page.dart';
import 'package:aspire_edge_404_notfound/pages/contact/contact_us_page.dart';
import 'package:aspire_edge_404_notfound/pages/create_quiz_page.dart';
import 'package:aspire_edge_404_notfound/pages/edit_quiz_page.dart';
import 'package:aspire_edge_404_notfound/pages/feedback_edit_page.dart';
import 'package:aspire_edge_404_notfound/pages/feedback_form_page.dart';
import 'package:aspire_edge_404_notfound/pages/feedback_page.dart';
import 'package:aspire_edge_404_notfound/pages/home/blog_detail_page.dart';
import 'package:aspire_edge_404_notfound/pages/home/cv_tip_detail_page.dart';
import 'package:aspire_edge_404_notfound/pages/home/interview_question_detail_page.dart';
import 'package:aspire_edge_404_notfound/pages/home_page.dart';
import 'package:aspire_edge_404_notfound/pages/industry_intro_page.dart';
import 'package:aspire_edge_404_notfound/pages/login_page.dart';
import 'package:aspire_edge_404_notfound/pages/notifications_center_page.dart';
import 'package:aspire_edge_404_notfound/pages/profile_page.dart';
import 'package:aspire_edge_404_notfound/pages/quiz_management_page.dart';
import 'package:aspire_edge_404_notfound/pages/register_page.dart';
import 'package:aspire_edge_404_notfound/pages/seed_achievements_page.dart';
import 'package:aspire_edge_404_notfound/pages/stories/personal_stories_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

const portName = "downloader_send_port";


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await LocalNoti.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  Widget withLayout(Widget body, String route) =>
      MainLayout(body: body, currentPageRoute: route);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _tier = '';

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
      _userDocSub?.cancel();
      _tier = '';

      if (u != null) {
        _userDocSub = FirebaseFirestore.instance
            .collection('Users')
            .doc(u.uid)
            .snapshots()
            .listen((snap) {
              final data = snap.data();
              _tier = (data?['Tier'] ?? '').toString();
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

        // Notifications
        '/notifications': (context) => widget.withLayout(
          NotificationsInboxPage(uid: FirebaseAuth.instance.currentUser!.uid),
          '/notifications',
        ),

        // Main pages
        '/': (context) => widget.withLayout(const HomePage(), '/'),
        '/profile': (context) =>
            widget.withLayout(const ProfilePage(), '/profile'),
        '/career_quiz': (context) =>
            widget.withLayout(const CareerQuizPage(), '/career_quiz'),
        '/career_bank': (context) =>
            widget.withLayout(const CareerManagePage(), '/career_bank'),

        // Career matches logic
        '/career_matches': (context) {
          if (isAdmin) {
            return widget.withLayout(
              const QuizManagementPage(),
              '/career_matches',
            );
          }
          return widget.withLayout(const CareerQuizPage(), '/career_matches');
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
        '/resources_hub': (context) =>
            widget.withLayout(const CareerDocsAllPage(), '/resources_hub'),
        '/stories': (context) => widget.withLayout(
          const PersonalStoriesPage(isAdmin: false),
          '/stories',
        ),
        '/stories_admin': (context) => widget.withLayout(
          const PersonalStoriesPage(isAdmin: true),
          '/stories_admin',
        ),
        '/contact_us': (context) =>
            widget.withLayout(const ContactUsPage(), '/contact_us'),
        "/industry_intro": (context) => const IndustryIntroPage(),

        '/feedback': (context) =>
            widget.withLayout(const FeedbackPage(), '/feedback'),
        '/feedback_form': (context) => const FeedbackFormPage(),
        '/feedback_edit': (context) => const FeedbackEditPage(),
        '/about_us': (context) =>
            widget.withLayout(const AboutUsPage(), '/about_us'),

        // Achievements
        '/achievements': (context) => const AchievementsSliderPage(),
        '/seed_achievements': (context) => widget.withLayout(
          const SeedAchievementsPage(),
          '/seed_achievements',
        ),

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
