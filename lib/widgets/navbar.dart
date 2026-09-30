import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'app_theme.dart';

class AppNavbar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuToggle;
  final String title;

  const AppNavbar({
    super.key,
    required this.onMenuToggle,
    required this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final pendingNotifCount = appState.notifications.where((n) => n.status == 'pending').length;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        boxShadow: AppTheme.shadowSm,
        border: const Border(
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < 600 ? 12 : 24),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Side: Sidebar Toggle & Page Title
            Row(
              children: [
                IconButton(
                  onPressed: onMenuToggle,
                  icon: const Icon(FontAwesomeIcons.bars),
                  color: AppTheme.darkNeutral,
                  splashRadius: 20,
                  hoverColor: AppTheme.primaryLight,
                ),
                if (appState.currentView != 'dashboard') ...[
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () {
                      appState.switchView('dashboard');
                    },
                    icon: const Icon(FontAwesomeIcons.house),
                    color: AppTheme.primary,
                    iconSize: 18,
                    splashRadius: 20,
                    tooltip: appState.currentLanguage == 'ar' ? 'الرئيسية' : 'Home',
                    hoverColor: AppTheme.primaryLight,
                  ),
                ],
                const SizedBox(width: 12),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.32,
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.darkNeutral,
                      fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),

            // Right Side: Language Toggle, Bell Icon & User Profile Block
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    appState.toggleLanguage();
                  },
                  icon: const Icon(
                    Icons.translate,
                    size: 20,
                    color: AppTheme.lightNeutral,
                  ),
                  tooltip: appState.currentLanguage == 'ar' ? 'English' : 'العربية',
                  hoverColor: AppTheme.primaryLight,
                ),
                const SizedBox(width: 8),

                // Notification Bell with Badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    InkWell(
                      onTap: () {
                        appState.switchView('notifications');
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppTheme.bg,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            FontAwesomeIcons.bell,
                            size: 18,
                            color: AppTheme.lightNeutral,
                          ),
                        ),
                      ),
                    ),
                    if (pendingNotifCount > 0)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.danger,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.cardBg, width: 2),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$pendingNotifCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),

                // User profile card
                if (user != null)
                  Row(
                    children: [
                      // User Info Details (Only show on screen width > 700px)
                      if (MediaQuery.of(context).size.width > 700) ...[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                color: AppTheme.darkNeutral,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  user.role,
                                  style: const TextStyle(
                                    color: AppTheme.lightNeutral,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  '|',
                                  style: TextStyle(
                                    color: AppTheme.borderColor,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  user.id,
                                  style: const TextStyle(
                                    color: AppTheme.lightNeutral,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                      ],

                      // User Avatar Image
                      _buildAvatar(user.avatar),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatar) {
    if (avatar == null) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.primaryLight, width: 2),
        ),
        child: const Center(
          child: Icon(FontAwesomeIcons.user, color: AppTheme.primary, size: 20),
        ),
      );
    }

    ImageProvider imageProvider;
    if (avatar.startsWith('data:image') || avatar.startsWith('base64,')) {
      // Decode base64
      final base64String = avatar.substring(avatar.indexOf(',') + 1);
      imageProvider = MemoryImage(base64Decode(base64String));
    } else {
      imageProvider = AssetImage(avatar);
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primaryLight, width: 2),
        boxShadow: AppTheme.shadowSm,
        image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
