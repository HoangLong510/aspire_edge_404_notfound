import 'package:flutter/material.dart';

// Một class dữ liệu đơn giản để code dễ đọc và an toàn hơn
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

  const AppDrawer({
    super.key,
    required this.currentPageRoute,
    required this.fullName,
    required this.email,
  });

  // Danh sách các mục trong drawer, giờ đây sử dụng class _DrawerItem
  static final List<_DrawerItem> _drawerItems = [
    const _DrawerItem(title: 'Home', icon: Icons.home_rounded, route: '/home'),
    const _DrawerItem(
      title: 'Career Bank',
      icon: Icons.business_center_rounded,
      route: '/career_bank',
    ),
    const _DrawerItem(
      title: 'Admission & Coaching Tools',
      icon: Icons.school_rounded,
      route: '/admission_tools',
    ),
    const _DrawerItem(
      title: 'Resources Hub',
      icon: Icons.collections_bookmark_rounded,
      route: '/resources_hub',
    ),
    const _DrawerItem(
      title: 'Interest Quiz',
      icon: Icons.quiz_rounded,
      route: '/interest_quiz',
    ),
    const _DrawerItem(
      title: 'Multimedia Guides',
      icon: Icons.video_library_rounded,
      route: '/multimedia_guides',
    ),
    const _DrawerItem(
      title: 'Testimonials',
      icon: Icons.star_rate_rounded,
      route: '/testimonials',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context),
          ..._drawerItems.map((item) => _buildDrawerTile(context, item)),
        ],
      ),
    );
  }

  // Widget riêng cho phần header của drawer
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
        child: Icon(Icons.person_rounded, size: 40, color: primaryColor),
      ),
      decoration: BoxDecoration(color: primaryColor),
    );
  }

  // Widget riêng cho mỗi mục trong drawer
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
          Navigator.pop(context); // Luôn đóng drawer trước
          if (!isSelected) {
            Navigator.pushReplacementNamed(context, item.route);
          }
        },
      ),
    );
  }
}
