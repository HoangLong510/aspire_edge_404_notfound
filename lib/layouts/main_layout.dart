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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
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
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _logout();
            },
            child: const Text('Confirm'),
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
        final String avatarUrl = (userData['AvatarUrl'] ?? '').toString();
        final String tier = (userData['Tier'] ?? '').toString();

        // Bọc bằng NotificationsListener nếu có uid
        final String? uid = _auth.currentUser?.uid;
        Widget scaffold = _buildMainScaffold(fullName, email, avatarUrl, tier);
        if (uid != null) {
          scaffold = NotificationsListener(uid: uid, child: scaffold);
        }
        return scaffold;
      },
    );
  }

  Scaffold _buildMainScaffold(String fullName, String email, String avatarUrl, String tier) {
    final color = Theme.of(context).colorScheme;

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
          _UserMenuAnchor(
            fullName: fullName,
            email: email,
            avatarUrl: avatarUrl,
            onProfile: () => Navigator.of(context).pushNamed('/profile'),
            onChangePassword: () => Navigator.of(context).pushNamed('/change-password'),
            onLogout: _showLogoutConfirmationDialog,
          ),
        ],
      ),
      drawer: AppDrawer(
        currentPageRoute: widget.currentPageRoute,
        fullName: fullName,
        email: email,
        avatarUrl: avatarUrl,
         isAdmin: tier.toLowerCase() == 'admin',
      ),
      body: widget.body,
      backgroundColor: color.background,
    );
  }
}

/// =======================
///   M3 Menu (MenuAnchor)
/// =======================

class _UserMenuAnchor extends StatefulWidget {
  const _UserMenuAnchor({
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    required this.onProfile,
    required this.onChangePassword,
    required this.onLogout,
  });

  final String fullName;
  final String email;
  final String avatarUrl;
  final VoidCallback onProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  @override
  State<_UserMenuAnchor> createState() => _UserMenuAnchorState();
}

class _UserMenuAnchorState extends State<_UserMenuAnchor> {
  final MenuController _menuController = MenuController();

  void _toggleMenu() {
    if (_menuController.isOpen) {
      _menuController.close();
    } else {
      _menuController.open();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: MenuTheme(
        data: MenuThemeData(
          style: MenuStyle(
            backgroundColor: MaterialStatePropertyAll(cs.surface),
            surfaceTintColor: MaterialStatePropertyAll(cs.surfaceTint),
            elevation: const MaterialStatePropertyAll(8),
            shape: MaterialStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
            shadowColor: MaterialStatePropertyAll(Colors.black.withOpacity(.25)),
          ),
        ),
        child: MenuAnchor(
          controller: _menuController,
          alignmentOffset: const Offset(0, 8),
          menuChildren: [
            // Header: bấm -> /profile
            MenuItemButton(
              onPressed: () {
                _menuController.close();
                widget.onProfile();
              },
              child: SizedBox(
                width: 260,
                child: Row(
                  children: [
                    _CircleAvatar(
                      imageUrl: widget.avatarUrl,
                      fallbackText: _initials(widget.fullName),
                      radius: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.fullName,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              )),
                          const SizedBox(height: 2),
                          Text(widget.email,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              )),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: theme.primaryColor),
                  ],
                ),
              ),
            ),
            const Divider(height: 8, thickness: 1),
            MenuItemButton(
              onPressed: () {
                _menuController.close();
                widget.onChangePassword();
              },
              leadingIcon: Icon(Icons.lock_outline, color: cs.onSurface),
              child: const Text('Change Password'),
            ),
            MenuItemButton(
              onPressed: () {
                _menuController.close();
                widget.onLogout();
              },
              leadingIcon: const Icon(Icons.logout, color: Colors.red),
              style: ButtonStyle(
                foregroundColor: MaterialStatePropertyAll(Colors.red.shade700),
              ),
              child: const Text('Logout'),
            ),
          ],
          builder: (context, controller, child) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _toggleMenu,
                splashColor: Colors.white.withOpacity(.15),
                highlightColor: Colors.white.withOpacity(.10),
                child: _PillAvatarButton(
                  avatarUrl: widget.avatarUrl,
                  fullName: widget.fullName,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

/// Nút pill hiển thị trên AppBar (avatar + mũi tên)
class _PillAvatarButton extends StatelessWidget {
  const _PillAvatarButton({
    required this.avatarUrl,
    required this.fullName,
  });

  final String avatarUrl;
  final String fullName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 2, 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CircleAvatar(
            imageUrl: avatarUrl,
            fallbackText: _initials(fullName),
            radius: 16,
          ),
          const SizedBox(width: 6),
          const Icon(Icons.expand_more, color: Colors.white),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

/// Avatar tròn dùng `AvatarUrl` có fallback chữ cái đầu
class _CircleAvatar extends StatelessWidget {
  const _CircleAvatar({
    required this.imageUrl,
    required this.fallbackText,
    this.radius = 16,
  });

  final String imageUrl;
  final String fallbackText;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.isNotEmpty;
    final primary = Theme.of(context).primaryColor;

    return CircleAvatar(
      radius: radius,
      backgroundColor: primary.withOpacity(.1),
      backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
      child: hasImage
          ? null
          : Text(
              fallbackText,
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w800,
                fontSize: radius - 4,
              ),
            ),
    );
  }
}
