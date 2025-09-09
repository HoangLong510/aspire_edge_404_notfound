import 'package:aspire_edge_404_notfound/layouts/main_layout.dart';
import 'package:aspire_edge_404_notfound/pages/change_password_page.dart';
import 'package:aspire_edge_404_notfound/pages/home_page.dart';
import 'package:aspire_edge_404_notfound/pages/login_page.dart';
import 'package:aspire_edge_404_notfound/pages/register_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // await FirebaseAuth.instance.signOut();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      initialRoute: FirebaseAuth.instance.currentUser == null
          ? '/login'
          : '/',
      routes: {
        '/': (context) => MainLayout(body: HomePage(), currentPageRoute: "/"),

        '/login': (context) => const LoginPage(),

        '/register': (context) => const RegisterPage(),

        '/change-password': (context) => const ChangePasswordPage(),
      },
    );
  }
}
