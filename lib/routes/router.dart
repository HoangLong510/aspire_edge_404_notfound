import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aspire_edge_404_notfound/pages/contact/about_us_page.dart';
import 'package:aspire_edge_404_notfound/pages/quiz/answer_quiz_page.dart';
import 'package:aspire_edge_404_notfound/pages/blog/blog_detail_page.dart';
import 'package:aspire_edge_404_notfound/pages/blog/blog_edit_page.dart';
import 'package:aspire_edge_404_notfound/pages/blog/blog_page.dart';
import 'package:aspire_edge_404_notfound/pages/career/career_detail_page.dart';
import 'package:aspire_edge_404_notfound/pages/career/career_docs_all_page.dart';
import 'package:aspire_edge_404_notfound/pages/career/career_manage_page.dart';
import 'package:aspire_edge_404_notfound/pages/quiz/career_quiz_page.dart';
import 'package:aspire_edge_404_notfound/pages/auth/change_password_page.dart';
import 'package:aspire_edge_404_notfound/chatbox/pages/coaching_tools_page.dart';
import 'package:aspire_edge_404_notfound/pages/contact/contact_us_page.dart';
import 'package:aspire_edge_404_notfound/pages/blog/create_blog_page.dart';
import 'package:aspire_edge_404_notfound/pages/quiz/create_quiz_page.dart';
import 'package:aspire_edge_404_notfound/pages/quiz/edit_quiz_page.dart';
import 'package:aspire_edge_404_notfound/pages/feedback/feedback_edit_page.dart';
import 'package:aspire_edge_404_notfound/pages/feedback/feedback_form_page.dart';
import 'package:aspire_edge_404_notfound/pages/feedback/feedback_page.dart';
import 'package:aspire_edge_404_notfound/pages/home/cv_tip_detail_page.dart';
import 'package:aspire_edge_404_notfound/pages/home/interview_question_detail_page.dart';
import 'package:aspire_edge_404_notfound/pages/home/home_page.dart';
import 'package:aspire_edge_404_notfound/pages/resource_hub/industry_intro_page.dart';
import 'package:aspire_edge_404_notfound/pages/auth/login_page.dart';
import 'package:aspire_edge_404_notfound/pages/home/notifications_center_page.dart';
import 'package:aspire_edge_404_notfound/pages/home/profile_page.dart';
import 'package:aspire_edge_404_notfound/pages/quiz/quiz_management_page.dart';
import 'package:aspire_edge_404_notfound/pages/auth/register_page.dart';
import 'package:aspire_edge_404_notfound/pages/stories/add_story_page.dart';
import 'package:aspire_edge_404_notfound/pages/stories/admin_stories_page.dart';
import 'package:aspire_edge_404_notfound/pages/stories/personal_stories_page.dart';
import 'package:aspire_edge_404_notfound/pages/stories/public_story_page.dart';
import 'package:aspire_edge_404_notfound/pages/stories/story_detail_page.dart';

Map<String, WidgetBuilder> getAppRoutes(bool isAdmin, Function withLayout) {
  return {
    '/login': (context) => const LoginPage(),
    '/register': (context) => const RegisterPage(),
    '/change-password': (context) =>
        withLayout(const ChangePasswordPage(), '/change-password'),
    '/notifications': (context) => withLayout(
      NotificationsInboxPage(uid: FirebaseAuth.instance.currentUser!.uid),
      '/notifications',
    ),
    '/': (context) => withLayout(const HomePage(), '/'),
    '/profile': (context) => withLayout(const ProfilePage(), '/profile'),
    '/career_bank': (context) =>
        withLayout(const CareerManagePage(), '/career_bank'),
    '/career_detail': (context) {
      final careerId = ModalRoute.of(context)!.settings.arguments as String;
      return withLayout(CareerDetailPage(careerId: careerId), '/career_detail');
    },
    '/career_quiz': (context) => isAdmin
        ? withLayout(const QuizManagementPage(), '/career_quiz')
        : withLayout(const CareerQuizPage(), '/career_quiz'),
    '/quiz_management': (context) =>
        withLayout(const QuizManagementPage(), '/quiz_management'),
    '/create_quiz': (context) =>
        withLayout(const CreateQuizPage(), '/create_quiz'),
    '/edit_quiz': (context) => withLayout(const EditQuizPage(), '/edit_quiz'),
    '/resources_hub': (context) =>
        withLayout(const CareerDocsAllPage(), '/resources_hub'),
    '/my_stories': (context) =>
        withLayout(const PersonalStoriesPage(), '/my_stories'),
    '/stories': (context) => withLayout(const PublicStoriesPage(), '/stories'),
    '/stories_admin': (context) =>
        withLayout(const AdminStoriesPage(), '/stories_admin'),
    '/coaching_tools': (context) =>
        withLayout(const CoachingChatPage(), '/coaching_tools'),
    '/add_story': (context) => withLayout(const AddStoryPage(), '/add_story'),
    '/story_detail': (context) {
      final storyId = ModalRoute.of(context)!.settings.arguments as String;
      return StoryDetailPage(storyId: storyId);
    },
    '/contact_us': (context) =>
        withLayout(const ContactUsPage(), '/contact_us'),
    '/industry_intro': (context) =>
        withLayout(const IndustryIntroPage(), '/industry_intro'),
    '/feedback': (context) => withLayout(const FeedbackPage(), '/feedback'),
    '/feedback_form': (context) =>
        withLayout(const FeedbackFormPage(), '/feedback_form'),
    '/feedback_edit': (context) =>
        withLayout(const FeedbackEditPage(), '/feedback_edit'),
    '/about_us': (context) => withLayout(const AboutUsPage(), '/about_us'),
    '/answer_quiz': (context) => const AnswerQuizPage(),
    '/cv_detail': (context) => const CurriculumVitaeTipDetailPage(),
    '/interview_detail': (context) => const InterviewQuestionDetailPage(),
    '/blog': (context) => withLayout(const BlogPage(), '/blog'),
    '/blog_create': (context) => const CreateBlogPage(),
    '/blog_detail': (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final blogId = args['blogId'] as String;
      return BlogDetailPage(blogId: blogId);
    },
    '/blog_edit': (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final blogId = args['blogId'] as String;
      return BlogEditPage(blogId: blogId);
    },
  };
}
