import 'dart:async';

import 'package:aspire_edge_404_notfound/layouts/main_layout.dart';
import 'package:aspire_edge_404_notfound/pages/answer_quiz_page.dart';
import 'package:aspire_edge_404_notfound/pages/career_manage_page.dart';
import 'package:aspire_edge_404_notfound/pages/admin_panel_page.dart';
import 'package:aspire_edge_404_notfound/pages/career_matches_page.dart';
import 'package:aspire_edge_404_notfound/pages/career_quiz_page.dart';
import 'package:aspire_edge_404_notfound/pages/change_password_page.dart';
import 'package:aspire_edge_404_notfound/pages/coaching_tools_page.dart';
import 'package:aspire_edge_404_notfound/pages/create_quiz_page.dart';
import 'package:aspire_edge_404_notfound/pages/edit_quiz_page.dart';
import 'package:aspire_edge_404_notfound/pages/feedback_form_page.dart';
import 'package:aspire_edge_404_notfound/pages/home_page.dart';
import 'package:aspire_edge_404_notfound/pages/login_page.dart';
import 'package:aspire_edge_404_notfound/pages/profile_page.dart';
import 'package:aspire_edge_404_notfound/pages/quiz_management_page.dart';
import 'package:aspire_edge_404_notfound/pages/register_page.dart';
import 'package:aspire_edge_404_notfound/pages/resource_hub_page.dart';
import 'package:aspire_edge_404_notfound/pages/testimonials_page.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  runApp(const MyApp());
}

/// Keep user + tier + hasMatches at top-level for simple checks in routes
class MyApp extends StatefulWidget {
  const MyApp({super.key});

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

  // helper: wrap in MainLayout
  Widget withLayout(Widget body, String route) =>
      MainLayout(body: body, currentPageRoute: route);

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
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/change-password': (context) => const ChangePasswordPage(),
        '/profile': (context) => const ProfilePage(),

        '/career_bank': (context) => MainLayout(
          body: CareerManagePage(),
          currentPageRoute: "/career_bank",
        ),

        '/': (context) => withLayout(const HomePage(), '/'),

        '/career_matches': (context) {
          if (isAdmin) {
            return withLayout(const QuizManagementPage(), '/career_matches');
          }
          if (_user == null) {
            return withLayout(const CareerQuizPage(), '/career_matches');
          }
          if (!_userDocReady) {
            return withLayout(
              const Center(child: CircularProgressIndicator()),
              '/career_matches',
            );
          }
          return withLayout(
            _hasMatches ? const CareerMatchesPage() : const CareerQuizPage(),
            '/career_matches',
          );
        },

        '/answer_quiz': (context) => MainLayout(
          body: const AnswerQuizPage(),
          currentPageRoute: "/answer_quiz",
        ),
        '/create_quiz': (context) =>
            withLayout(const CreateQuizPage(), '/create_quiz'),
        '/edit_quiz': (context) =>
            withLayout(const EditQuizPage(), '/edit_quiz'),

        // '/quiz_management' removed as requested
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
      },
    );
  }
}
