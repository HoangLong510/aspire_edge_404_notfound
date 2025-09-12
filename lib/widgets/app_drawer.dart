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
  final bool isAdmin; // <-- add flag to switch title/icon for /career_matches

  const AppDrawer({
    super.key,
    required this.currentPageRoute,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    this.isAdmin = false, // default non-admin
  });

  List<_DrawerItem> _drawerItems() => [
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
    // Dynamic title & icon for /career_matches
    _DrawerItem(
      title: isAdmin ? 'Career Quiz' : 'Career Matches',
      icon: isAdmin ? Icons.quiz_rounded : Icons.favorite_rounded,
      route: '/career_matches',
    ),
    const _DrawerItem(
      title: 'Testimonials',
      icon: Icons.star_rate_rounded,
      route: '/testimonials',
    ),
    const _DrawerItem(
      title: 'Feedback',
      icon: Icons.feedback_rounded,
      route: '/feedback_form',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final items = _drawerItems();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context),
          ...items.map((item) => _buildDrawerTile(context, item)),
        ],
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
        backgroundImage: (avatarUrl.isNotEmpty)
            ? NetworkImage(avatarUrl)
            : null,
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
