import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aspire_edge_404_notfound/routes/router.dart';
import 'package:aspire_edge_404_notfound/layouts/main_layout.dart';

class LocalNoti {
  static Future<void> init() async {}
}

class NotificationsListener extends StatelessWidget {
  final String uid;
  final Widget child;
  const NotificationsListener({
    Key? key,
    required this.uid,
    required this.child,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return child;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await LocalNoti.init();

  final user = FirebaseAuth.instance.currentUser;
  runApp(
    user == null
        ? const MyApp()
        : NotificationsListener(uid: user.uid, child: const MyApp()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

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

  Widget _withLayout(Widget body, String route) =>
      MainLayout(body: body, currentPageRoute: route);

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
      initialRoute: '/',
      routes: getAppRoutes(isAdmin, _withLayout),
    );
  }
}
