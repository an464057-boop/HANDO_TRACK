import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'layout/responsive_layout.dart';
import 'widgets/app_theme.dart';
import 'views/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize native background notifications
  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint("App startup: Notification init error: $e");
  }

  // Initialize Firebase (and auto-fallback to local preferences database if config missing)
  try {
    await FirebaseService.init();
  } catch (e) {
    // If Firebase completely fails, app will still run in local-only mode
    debugPrint("App startup: Firebase init error: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const TransferSystemApp(),
    ),
  );
}

class TransferSystemApp extends StatelessWidget {
  const TransferSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transfer System - نظام تسليم الشغل',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const SplashView(),
    );
  }
}
