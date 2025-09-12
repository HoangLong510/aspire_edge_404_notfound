import 'package:aspire_edge_404_notfound/pages/notifications_center_page.dart';
import 'package:aspire_edge_404_notfound/widgets/app_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MainLayout extends StatefulWidget {
  final Widget body;
  final String currentPageRoute;

  const MainLayout({
    super.key,
    required this.body,
    required this.currentPageRoute,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = _auth.currentUser;
    if (user != null) {
      _userFuture = _firestore.collection('Users').doc(user.uid).get();
    } else {
      _userFuture = Future.error('No user logged in.');
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error logging out: $e')));
      }
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Confirm Logout',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text('Are you sure you want to log out?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _logout();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(
              child: Text('Error loading user data. Please try again.'),
            ),
          );
        }

        final userData = snapshot.data!.data()!;
        final String fullName = (userData['Name'] ?? 'Guest').toString();
        final String email = _auth.currentUser?.email ?? 'No email';
        final String tier = (userData['Tier'] ?? '').toString().toLowerCase();
        final bool isAdmin = tier == 'admin';
        final String uid = _auth.currentUser!.uid;

        return NotificationsListener(
          uid: uid,
          child: _buildMainScaffold(fullName, email, isAdmin),
        );
      },
    );
  }

  Scaffold _buildMainScaffold(String fullName, String email, bool isAdmin) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Aspire Edge',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          if (_auth.currentUser != null)
            NotificationBell(uid: _auth.currentUser!.uid),
          _buildPopupMenu(fullName, email),
        ],
      ),
      drawer: AppDrawer(
        currentPageRoute: widget.currentPageRoute,
        fullName: fullName,
        email: email,
        isAdmin: isAdmin, // <-- bật mục Admin/Seed Achievements nếu là admin
      ),
      // bọc SafeArea + padding nhẹ để tránh tràn viền
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: widget.body,
        ),
      ),
    );
  }

  Widget _buildPopupMenu(String fullName, String email) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'logout') {
          _showLogoutConfirmationDialog();
        } else if (value == 'change_password') {
          // FIX: đồng bộ với routes '/change_password'
          Navigator.of(context).pushNamed('/change_password');
        }
      },
      icon: const Icon(Icons.account_circle, size: 28),
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      itemBuilder: (context) => [
        _buildPopupHeader(fullName, email),
        const PopupMenuDivider(height: 1),
        _buildPopupMenuItem(
          value: 'change_password',
          icon: Icons.lock_outline,
          text: 'Change Password',
          color: Colors.grey.shade700,
        ),
        _buildPopupMenuItem(
          value: 'logout',
          icon: Icons.logout,
          text: 'Logout',
          color: Colors.red.shade700,
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupHeader(String fullName, String email) {
    return PopupMenuItem<String>(
      enabled: false,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(Icons.person, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem({
    required String value,
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: color),
        title: Text(text, style: TextStyle(color: color)),
      ),
    );
  }
}
