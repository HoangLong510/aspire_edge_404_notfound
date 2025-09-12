import 'package:flutter/material.dart';

class _DrawerItem {
  final String title;
  final IconData icon;
  final String route;

  const _DrawerItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}

class AppDrawer extends StatelessWidget {
  final String currentPageRoute;
  final String fullName;
  final String email;
  final String avatarUrl;
  final bool isAdmin; // hiển thị nhóm Admin nếu true

  const AppDrawer({
    super.key,
    required this.currentPageRoute,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    this.isAdmin = false,
  });

  // Menu chung
  static final List<_DrawerItem> _drawerItems = [
    const _DrawerItem(title: 'Home', icon: Icons.home_rounded, route: '/'),
    const _DrawerItem(
      title: 'Career Bank',
      icon: Icons.business_center_rounded,
      route: '/career_bank',
    ),
    const _DrawerItem(
      title: 'Coaching Tools',
      icon: Icons.school_rounded,
      route: '/coaching_tools',
    ),
    const _DrawerItem(
      title: 'Resources Hub',
      icon: Icons.collections_bookmark_rounded,
      route: '/resource_hub',
    ),
    const _DrawerItem(
      title: 'Career Quiz',
      icon: Icons.quiz_rounded,
      route: '/career_quiz',
    ),
    const _DrawerItem(
      title: 'Testimonials',
      icon: Icons.star_rate_rounded,
      route: '/testimonials',
    ),
    const _DrawerItem(
      title: 'About Us',
      icon: Icons.info_rounded,
      route: '/about_us',
    ),
    const _DrawerItem(
      title: 'Contact Us',
      icon: Icons.feedback_rounded,
      route: '/contact_us',
    ),
  ];

  // Menu riêng cho Admin
  static final List<_DrawerItem> _adminItems = [
    const _DrawerItem(
      title: 'Admin Panel',
      icon: Icons.admin_panel_settings_rounded,
      route: '/admin_panel',
    ),
    const _DrawerItem(
      title: 'Seed Achievements',
      icon: Icons.storage_rounded,
      route: '/seed_achievements',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _buildDrawerHeader(context),
      ..._drawerItems.map((item) => _buildDrawerTile(context, item)),
    ];

    if (isAdmin) {
      children.add(const Divider(height: 12));
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
          child: Text(
            'Admin',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      );
      children.addAll(_adminItems.map((item) => _buildDrawerTile(context, item)));
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: children,
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    return UserAccountsDrawerHeader(
      accountName: Text(
        fullName,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      accountEmail: Text(email),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        backgroundImage: (avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
        child: (avatarUrl.isNotEmpty)
            ? null
            : Icon(Icons.person_rounded, size: 40, color: primaryColor),
      ),
      decoration: BoxDecoration(color: primaryColor),
    );
  }

  Widget _buildDrawerTile(BuildContext context, _DrawerItem item) {
    final bool isSelected = currentPageRoute == item.route;
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color activeColor = primaryColor;
    final Color inactiveColor = Colors.grey.shade700;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: isSelected ? activeColor : inactiveColor,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? activeColor : Colors.black87,
          ),
        ),
        selected: isSelected,
        selectedTileColor: activeColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          Navigator.pop(context);
          if (!isSelected) {
            Navigator.pushReplacementNamed(context, item.route);
          }
        },
      ),
    );
  }
}
