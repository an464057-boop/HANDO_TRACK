import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/app_state.dart';
import '../widgets/navbar.dart';
import '../widgets/sidebar.dart';
import '../widgets/translations.dart';
import '../widgets/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../views/dashboard_view.dart';
import '../views/new_transfer_view.dart';
import '../views/notifications_view.dart';
import '../views/projects_view.dart';
import '../views/project_details_view.dart';
import '../views/profile_view.dart';
import '../views/login_view.dart';
import '../views/profile_setup_view.dart';
import '../models/models.dart';

class ResponsiveLayout extends StatefulWidget {
  const ResponsiveLayout({super.key});

  @override
  State<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends State<ResponsiveLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _sidebarCollapsed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context, listen: false);
    appState.onNewNotification = (notif) {
      _showInAppNotification(notif);
    };
  }

  void _showInAppNotification(NotificationModel notif) {
    if (!mounted) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final lang = appState.currentLanguage;
    final isRTL = lang == 'ar';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: const Duration(seconds: 8),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          content: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B), // Dark slate
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        FontAwesomeIcons.solidBell,
                        color: AppTheme.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRTL ? 'إشعار تسليم جديد!' : 'New Handover Request!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isRTL
                                ? 'قام ${notif.sender} من قسم (${notif.senderDept}) بإرسال ${notif.qty} قطعة من (${notif.part}) لمشروع ${notif.project}'
                                : '${notif.sender} from (${notif.senderDept}) sent ${notif.qty} pcs of (${notif.part}) for ${notif.project}',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        appState.rejectNotification(notif.id);
                      },
                      child: Text(
                        isRTL ? 'رفض' : 'Reject',
                        style: const TextStyle(
                          color: AppTheme.danger,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        appState.acceptNotification(notif.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isRTL ? 'استلام' : 'Accept',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _getViewWidget(String viewId) {
    switch (viewId) {
      case 'dashboard':
        return const DashboardView();
      case 'new-transfer':
        return const NewTransferView();
      case 'notifications':
        return const NotificationsView();
      case 'projects':
        return const ProjectsView();
      case 'project-details':
        return const ProjectDetailsView();
      case 'profile':
        return const ProfileView();
      default:
        return const DashboardView();
    }
  }

  Widget _buildUpdateScreen(AppState appState) {
    final lang = appState.currentLanguage;
    final isRTL = lang == 'ar';
    final config = appState.appConfig ?? {};
    final apkUrl = config['apkUrl'] as String? ?? 'https://your-domain.com/app-release.apk';
    final latestName = config['latestVersionName'] as String? ?? '1.0.0';
    final whatsNew = isRTL 
        ? (config['whatsNewAr'] as String? ?? 'تحديثات جديدة مضافة للتطبيق.')
        : (config['whatsNewEn'] as String? ?? 'New updates added to the app.');

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E293B),
                Color(0xFF0F172A),
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Update Icon
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            FontAwesomeIcons.cloudArrowDown,
                            size: 36,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Center(
                      child: Text(
                        isRTL ? 'تحديث جديد متاح!' : 'New Update Available!',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.darkNeutral,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        '${isRTL ? 'إصدار' : 'Version'} $latestName',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        isRTL
                            ? 'يرجى تحميل النسخة الأخيرة لتتمكن من الاستمرار في استخدام التطبيق.'
                            : 'Please download the latest version to continue using the app.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.lightNeutral,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Changelog Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.bg,
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRTL ? 'ما الجديد في هذا الإصدار:' : "What's New in this Version:",
                            style: const TextStyle(
                              color: AppTheme.darkNeutral,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            whatsNew,
                            style: const TextStyle(
                              color: AppTheme.lightNeutral,
                              fontSize: 12,
                              height: 1.5,
                            ),
                            textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(apkUrl);
                        try {
                          // Try directly first (more reliable on Android 11+ without package querying restrictions)
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          debugPrint("Direct launch failed, trying fallback: $e");
                          try {
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          } catch (e2) {
                            debugPrint("Could not launch $apkUrl: $e2");
                          }
                        }
                      },
                      icon: const Icon(FontAwesomeIcons.download, size: 16),
                      label: Text(
                        isRTL ? 'تحديث الآن' : 'Update Now',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radius),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    // App update check wall
    if (appState.showUpdateDialog) {
      return _buildUpdateScreen(appState);
    }
    
    // Auth wall check
    if (!appState.isLoggedIn) {
      return const LoginView();
    }
    
    // Profile setup wall check
    if (!appState.isProfileCompleted) {
      return const ProfileSetupView();
    }
    
    final currentView = appState.currentView;
    final lang = appState.currentLanguage;
    final isRTL = lang == 'ar';
    
    // Dynamically retrieve view titles from Translations map (converting hyphens to underscores)
    final viewTitleKey = 'page_${currentView.replaceAll('-', '_')}';
    final viewTitle = Translations.get(viewTitleKey, lang);

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth <= 900;

          if (isMobile) {
            // Mobile Layout: Appbar with menu icon opening a Drawer scaffold
            return Scaffold(
              key: _scaffoldKey,
              appBar: AppNavbar(
                title: viewTitle,
                onMenuToggle: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              drawer: Drawer(
                child: AppSidebar(
                  isCollapsed: false,
                  onItemTap: () {
                    // Auto close drawer when item clicked
                    _scaffoldKey.currentState?.closeDrawer();
                  },
                ),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  child: _getViewWidget(currentView),
                ),
              ),
            );
          } else {
            // Desktop Layout: Sidebar on the left, main content column on the right
            // Swap sidebar placement based on RTL layout
            final sidebar = AppSidebar(isCollapsed: _sidebarCollapsed);
            final mainContent = Expanded(
              child: Column(
                children: [
                  AppNavbar(
                    title: viewTitle,
                    onMenuToggle: () {
                      setState(() {
                        _sidebarCollapsed = !_sidebarCollapsed;
                      });
                    },
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(0),
                      child: _getViewWidget(currentView),
                    ),
                  ),
                ],
              ),
            );

            return Scaffold(
              body: Row(
                children: isRTL 
                    ? [mainContent, sidebar] // Sidebar on the right for RTL
                    : [sidebar, mainContent], // Sidebar on the left for LTR
              ),
            );
          }
        },
      ),
    );
  }
}
