

import 'package:aspire_edge_404_notfound/layouts/main_layout.dart';
import 'package:aspire_edge_404_notfound/pages/achievements_slider_page.dart';
import 'package:aspire_edge_404_notfound/pages/admin_panel_page.dart';
import 'package:aspire_edge_404_notfound/pages/career_bank_page.dart';
import 'package:aspire_edge_404_notfound/pages/career_quiz_page.dart';
import 'package:aspire_edge_404_notfound/pages/change_password_page.dart';
import 'package:aspire_edge_404_notfound/pages/coaching_tools_page.dart';
import 'package:aspire_edge_404_notfound/pages/feedback_form_page.dart';
import 'package:aspire_edge_404_notfound/pages/home/blog_detail_page.dart';
import 'package:aspire_edge_404_notfound/pages/home/cv_tip_detail_page.dart';
import 'package:aspire_edge_404_notfound/pages/home/interview_question_detail_page.dart';
import 'package:aspire_edge_404_notfound/pages/home_page.dart';
import 'package:aspire_edge_404_notfound/pages/login_page.dart';
import 'package:aspire_edge_404_notfound/pages/profile_page.dart';
import 'package:aspire_edge_404_notfound/pages/register_page.dart';
import 'package:aspire_edge_404_notfound/pages/resource_hub_page.dart';
import 'package:aspire_edge_404_notfound/pages/seed_achievements_page.dart';
import 'package:aspire_edge_404_notfound/pages/testimonials_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // helper: quấn trang trong MainLayout
  Widget withLayout(Widget body, String route) =>
      MainLayout(body: body, currentPageRoute: route);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "AspireEdge",
      theme: ThemeData(
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      initialRoute: FirebaseAuth.instance.currentUser == null ? '/login' : '/',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot_password': (context) => const ChangePasswordPage(),

        '/achievements': (context) => const AchievementsSliderPage(),
        '/seed_achievements': (context) =>
            withLayout(const SeedAchievementsPage(), '/seed_achievements'),

        '/': (context) => withLayout(const HomePage(), '/'),
        '/change_password': (context) =>
            withLayout(const ChangePasswordPage(), '/change_password'),
        '/profile': (context) => withLayout(const ProfilePage(), '/profile'),
        '/career_bank': (context) =>
            withLayout(const CareerBankPage(), '/career_bank'),
        '/career_quiz': (context) =>
            withLayout(const CareerQuizPage(), '/career_quiz'),
        '/coaching_tools': (context) =>
            withLayout(const CoachingToolsPage(), '/coaching_tools'),
        '/resource_hub': (context) =>
            withLayout(const ResourceHubPage(), '/resource_hub'),
        '/testimonials': (context) =>
            withLayout(const TestimonialsPage(), '/testimonials'),
        '/feedback_form': (context) =>
            withLayout(const FeedbackFormPage(), '/feedback_form'),
        '/admin_panel': (context) =>
            withLayout(const AdminPanelPage(), '/admin_panel'),

        '/cv_detail': (context) => const CVTipDetailPage(),
        '/interview_detail': (context) => const InterviewQuestionDetailPage(),
        '/blog_detail': (context) => const BlogDetailPage(),
      },
    );
  }
}
