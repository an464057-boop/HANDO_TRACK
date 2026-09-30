import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'app_theme.dart';

class AppSidebar extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback? onItemTap;

  const AppSidebar({
    super.key,
    this.isCollapsed = false,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final activeView = appState.currentView;
    final role = appState.currentUser?.role ?? '';
    final isTechnician = role == 'فني' || role.startsWith('فني -');

    return Container(
      width: isCollapsed ? 80 : 280,
      decoration: const BoxDecoration(
        color: AppTheme.sidebarBg,
        border: Border(
          right: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar Logo Block
          _buildLogo(context),
          const SizedBox(height: 32),

          // Menu List
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context,
                  viewId: 'dashboard',
                  icon: FontAwesomeIcons.house,
                  enTitle: 'Home',
                  arTitle: 'الرئيسية',
                  isActive: activeView == 'dashboard',
                  appState: appState,
                ),
                const SizedBox(height: 8),
                if (isTechnician) ...[
                  _buildMenuItem(
                    context,
                    viewId: 'new-transfer',
                    icon: FontAwesomeIcons.rightLeft,
                    enTitle: 'Transfers',
                    arTitle: 'التسليم',
                    isActive: activeView == 'new-transfer',
                    appState: appState,
                  ),
                  const SizedBox(height: 8),
                ],
                _buildMenuItem(
                  context,
                  viewId: 'notifications',
                  icon: FontAwesomeIcons.bell,
                  enTitle: 'Notifications',
                  arTitle: 'الإشعارات',
                  isActive: activeView == 'notifications',
                  appState: appState,
                  badgeCount: appState.notifications.where((n) => n.status == 'pending').length,
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  context,
                  viewId: 'projects',
                  icon: FontAwesomeIcons.folderOpen,
                  enTitle: 'Projects',
                  arTitle: 'المشاريع',
                  isActive: activeView == 'projects' || activeView == 'project-details',
                  appState: appState,
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  context,
                  viewId: 'profile',
                  icon: FontAwesomeIcons.userGear,
                  enTitle: 'Profile',
                  arTitle: 'الملف الشخصي',
                  isActive: activeView == 'profile',
                  appState: appState,
                ),
              ],
            ),
          ),

          // Footer Logout Action
          _buildLogoutItem(context),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    if (isCollapsed) {
      return Center(
        child: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Transfer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
              Text(
                'System',
                style: TextStyle(
                  color: AppTheme.sidebarText,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String viewId,
    required IconData icon,
    required String enTitle,
    required String arTitle,
    required bool isActive,
    required AppState appState,
    int badgeCount = 0,
  }) {
    if (isCollapsed) {
      return Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: Icon(
              icon,
              color: isActive ? AppTheme.sidebarActiveText : AppTheme.sidebarText,
              size: 20,
            ),
            onPressed: () {
              appState.switchView(viewId);
              if (onItemTap != null) onItemTap!();
            },
          ),
          if (badgeCount > 0)
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.danger,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    }

    return InkWell(
      onTap: () {
        appState.switchView(viewId);
        if (onItemTap != null) onItemTap!();
      },
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.sidebarActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppTheme.sidebarActiveText : AppTheme.sidebarText,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enTitle,
                    style: TextStyle(
                      color: isActive ? AppTheme.sidebarActiveText : AppTheme.sidebarText,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    arTitle,
                    style: TextStyle(
                      color: isActive
                          ? AppTheme.sidebarActiveText.withOpacity(0.9)
                          : AppTheme.sidebarText.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.danger,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    if (isCollapsed) {
      return Center(
        child: IconButton(
          icon: const Icon(
            FontAwesomeIcons.rightFromBracket,
            color: AppTheme.sidebarText,
            size: 20,
          ),
          onPressed: () => _simulateLogout(context),
        ),
      );
    }

    return Column(
      children: [
        const Divider(color: Colors.white10),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _simulateLogout(context),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  FontAwesomeIcons.rightFromBracket,
                  size: 18,
                  color: AppTheme.sidebarText,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: AppTheme.sidebarText,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'تسجيل خروج',
                      style: TextStyle(
                        color: Colors.white24,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _simulateLogout(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final isRTL = appState.currentLanguage == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isRTL ? 'تم تسجيل الخروج بنجاح!' : 'Logged out successfully!',
          textAlign: isRTL ? TextAlign.right : TextAlign.left,
          style: const TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary,
      ),
    );
    await appState.logout();
  }
}
