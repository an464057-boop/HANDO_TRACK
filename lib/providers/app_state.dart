import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  UserModel? _currentUser;
  List<TransferModel> _transfers = [];
  List<NotificationModel> _notifications = [];
  List<ProjectModel> _projects = [];

  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isProfileCompleted = false;
  String _currentView = 'dashboard';
  String _notifFilter = 'all';
  String _activeProjectId = 'p-1';
  String _currentLanguage = 'ar';

  static const int currentVersionCode = 1;
  static const String currentVersionName = "1.0.0";

  bool _showUpdateDialog = false;
  Map<String, dynamic>? _appConfig;

  // Firestore stream subscriptions
  StreamSubscription? _projectsSubscription;
  StreamSubscription? _transfersSubscription;
  StreamSubscription? _notificationsSubscription;
  StreamSubscription? _appConfigSubscription;

  // Polling Timer for Backend API
  Timer? _apiPollingTimer;

  // New notification callback
  Function(NotificationModel)? onNewNotification;

  // Getters
  UserModel? get currentUser => _currentUser;
  List<TransferModel> get transfers => _transfers;
  List<NotificationModel> get notifications => _notifications;
  List<ProjectModel> get projects => _projects;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get isProfileCompleted => _isProfileCompleted;
  String get currentView => _currentView;
  String get notifFilter => _notifFilter;
  String get activeProjectId => _activeProjectId;
  String get currentLanguage => _currentLanguage;
  bool get showUpdateDialog => _showUpdateDialog;
  Map<String, dynamic>? get appConfig => _appConfig;

  // Constructor
  AppState() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await FirebaseService.getUser();

      if (FirebaseService.useBackendApi) {
        // App update check
        final config = await FirebaseService.getAppConfig();
        if (config != null) {
          _appConfig = config;
          final latestCode = config['latestVersionCode'] as int? ?? 1;
          if (latestCode > currentVersionCode) {
            _showUpdateDialog = true;
          }
        }
        await refreshData();
        startApiPolling();
      } else if (FirebaseService.isFirebaseEnabled) {
        startFirestoreListeners();

        // App update check
        final config = await FirebaseService.getAppConfig();
        if (config != null) {
          _appConfig = config;
          final latestCode = config['latestVersionCode'] as int? ?? 1;
          if (latestCode > currentVersionCode) {
            _showUpdateDialog = true;
          }
        }
      } else {
        _transfers = await FirebaseService.getTransfers();
        _notifications = await FirebaseService.getNotifications();
        _projects = await FirebaseService.getProjects();
      }

      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString('current_language') ?? 'ar';
      _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      _isProfileCompleted = prefs.getBool('is_profile_completed') ?? false;

      if (FirebaseService.useBackendApi && _isLoggedIn) {
        startApiPolling();
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startApiPolling() {
    _apiPollingTimer?.cancel();
    if (!FirebaseService.useBackendApi) return;

    _apiPollingTimer = Timer.periodic(const Duration(seconds: 15), (
      timer,
    ) async {
      if (_isLoggedIn) {
        await refreshData();
      }
    });
  }

  Future<void> refreshData() async {
    try {
      final transfers = await FirebaseService.getTransfers();
      final notifications = await FirebaseService.getNotifications();
      final projects = await FirebaseService.getProjects();

      // Show notification if we got a new handover
      if (_currentUser != null &&
          _notifications.isNotEmpty &&
          notifications.isNotEmpty) {
        final oldNotifIds = _notifications.map((n) => n.id).toSet();
        for (var notif in notifications) {
          if (!oldNotifIds.contains(notif.id) &&
              notif.status == 'pending' &&
              notif.toDept == _currentUser!.department &&
              notif.sender != _currentUser!.name) {
            try {
              final isAr = _currentLanguage == 'ar';
              NotificationService.showNotification(
                id: notif.id.hashCode,
                title: isAr ? 'طلب تسليم جديد' : 'New Handover Request',
                body: isAr
                    ? 'قام ${notif.sender} بتسليم ${notif.qty} قطعة من (${notif.part}) لقسمك في مشروع ${notif.project}'
                    : '${notif.sender} sent ${notif.qty} pcs of (${notif.part}) to your department for ${notif.project}',
              );
            } catch (e) {
              debugPrint("Error showing system notification: $e");
            }

            if (onNewNotification != null) {
              onNewNotification!(notif);
            }
          }
        }
      }

      _transfers = transfers;
      _notifications = notifications;
      _projects = projects;
      notifyListeners();
    } catch (e) {
      debugPrint("API Polling Error: $e");
    }
  }

  void startFirestoreListeners() {
    if (!FirebaseService.isFirebaseEnabled) return;

    _projectsSubscription?.cancel();
    _transfersSubscription?.cancel();
    _notificationsSubscription?.cancel();

    // Listen to projects
    _projectsSubscription = FirebaseFirestore.instance
        .collection('projects')
        .snapshots()
        .listen((snapshot) {
          try {
            _projects = snapshot.docs
                .map((doc) => ProjectModel.fromMap(doc.data()))
                .toList();
            notifyListeners();
          } catch (e) {
            debugPrint("Projects stream parse error: $e");
          }
        }, onError: (e) => debugPrint("Projects stream error: $e"));

    // Listen to transfers
    _transfersSubscription = FirebaseFirestore.instance
        .collection('transfers')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
          try {
            _transfers = snapshot.docs
                .map((doc) => TransferModel.fromMap(doc.data()))
                .toList();
            notifyListeners();
          } catch (e) {
            debugPrint("Transfers stream parse error: $e");
          }
        }, onError: (e) => debugPrint("Transfers stream error: $e"));

    // Listen to notifications
    bool isInitial = true;
    _notificationsSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .snapshots()
        .listen((snapshot) {
          try {
            final oldNotifIds = _notifications.map((n) => n.id).toSet();
            final incoming = snapshot.docs
                .map((doc) => NotificationModel.fromMap(doc.data()))
                .toList();

            if (_currentUser != null && !isInitial) {
              for (var notif in incoming) {
                if (!oldNotifIds.contains(notif.id) &&
                    notif.status == 'pending' &&
                    notif.toDept == _currentUser!.department &&
                    notif.sender != _currentUser!.name) {
                  // Trigger native background/local system notification
                  try {
                    final isAr = _currentLanguage == 'ar';
                    NotificationService.showNotification(
                      id: notif.id.hashCode,
                      title: isAr ? 'طلب تسليم جديد' : 'New Handover Request',
                      body: isAr
                          ? 'قام ${notif.sender} بتسليم ${notif.qty} قطعة من (${notif.part}) لقسمك في مشروع ${notif.project}'
                          : '${notif.sender} sent ${notif.qty} pcs of (${notif.part}) to your department for ${notif.project}',
                    );
                  } catch (e) {
                    debugPrint("Error showing system notification: $e");
                  }

                  if (onNewNotification != null) {
                    onNewNotification!(notif);
                  }
                }
              }
            }

            _notifications = incoming;
            isInitial = false;
            notifyListeners();
          } catch (e) {
            debugPrint("Notifications stream parse error: $e");
          }
        }, onError: (e) => debugPrint("Notifications stream error: $e"));

    // Listen to app config live
    _appConfigSubscription?.cancel();
    _appConfigSubscription = FirebaseFirestore.instance
        .collection('config')
        .doc('app_config')
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final config = snapshot.data();
            if (config != null) {
              _appConfig = config;
              final latestCode = config['latestVersionCode'] as int? ?? 1;
              if (latestCode > currentVersionCode) {
                _showUpdateDialog = true;
              } else {
                _showUpdateDialog = false;
              }
              notifyListeners();
            }
          }
        }, onError: (e) => debugPrint("App config stream error: $e"));
  }

  @override
  void dispose() {
    _apiPollingTimer?.cancel();
    _projectsSubscription?.cancel();
    _transfersSubscription?.cancel();
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  // Toggle language preference
  Future<void> toggleLanguage() async {
    _currentLanguage = _currentLanguage == 'ar' ? 'en' : 'ar';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_language', _currentLanguage);
    } catch (e) {
      print("Error saving language preference: $e");
    }
  }

  void switchView(String viewId) {
    // Route guard: block non-technicians from accessing the handover submission view
    final role = _currentUser?.role ?? '';
    final isTechnician = role == 'فني' || role.startsWith('فني -');
    if (viewId == 'new-transfer' && !isTechnician) {
      return;
    }
    _currentView = viewId;
    notifyListeners();
  }

  // Complete profile setup and transition to main app dashboard
  Future<void> completeProfile() async {
    _isProfileCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_profile_completed', true);
    notifyListeners();
  }

  // Update current user model in memory
  void updateCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  // Login handler
  Future<bool> login(String username, String password) async {
    final UserModel? dbUser;
    if (FirebaseService.useBackendApi) {
      dbUser = await ApiService.login(username, password);
    } else {
      dbUser = await FirebaseService.getUserById(username);
    }

    if (dbUser != null) {
      final savedPassword = dbUser.password ?? '0000';
      if (password == savedPassword) {
        _currentUser = dbUser;
        await FirebaseService.saveUser(dbUser); // Save as active session

        final prefs = await SharedPreferences.getInstance();
        _isLoggedIn = true;
        await prefs.setBool('is_logged_in', true);

        final isCompleted =
            dbUser.name.isNotEmpty &&
            dbUser.department.isNotEmpty &&
            dbUser.role.isNotEmpty &&
            dbUser.id != dbUser.name;
        _isProfileCompleted = isCompleted;
        await prefs.setBool('is_profile_completed', isCompleted);

        if (FirebaseService.useBackendApi) {
          await refreshData();
          startApiPolling();
        }

        notifyListeners();
        return true;
      }
    }
    return false;
  }

  // Logout handler
  Future<void> logout() async {
    _isLoggedIn = false;
    _apiPollingTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    notifyListeners();
  }

  // Update password and complete login
  Future<void> updatePassword(String username, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();

    var dbUser = await FirebaseService.getUserById(username);

    if (dbUser == null) {
      dbUser = UserModel(
        id: username,
        name: username,
        role: "مشرف",
        department: "تشكيل",
        avatar: "assets/avatar.png",
        password: newPassword,
      );
      _isProfileCompleted = false;
      await prefs.setBool('is_profile_completed', false);
    } else {
      dbUser = dbUser.copyWith(password: newPassword);
      _isProfileCompleted = true;
      await prefs.setBool('is_profile_completed', true);
    }

    _currentUser = dbUser;
    await FirebaseService.saveUser(dbUser);

    _isLoggedIn = true;
    await prefs.setBool('is_logged_in', true);

    notifyListeners();
  }

  // Set active project for Details Page
  void setActiveProject(String projectId) {
    _activeProjectId = projectId;
    notifyListeners();
  }

  // Set notification filter
  void setNotifFilter(String filter) {
    _notifFilter = filter;
    notifyListeners();
  }

  // Add new transfer and trigger pending notification
  Future<void> addTransfer({
    required String version,
    required String project,
    required String part,
    required String jo,
    required String toDept,
    required int qty,
    required String notes,
    String? imageUrl,
  }) async {
    if (_currentUser == null) return;

    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy hh:mm a').format(now);
    final idSuffix = DateTime.now().millisecondsSinceEpoch.toString();
    final transferId = 't-$idSuffix';
    final notifId = 'notif-$idSuffix';

    // 1. Create Transfer Object
    final newTransfer = TransferModel(
      id: transferId,
      date: dateStr,
      project: project,
      version: version,
      jo: jo,
      part: part,
      qty: qty,
      fromDept: _currentUser!.department,
      toDept: toDept,
      status: "قيد الانتظار",
      notes: notes.isNotEmpty ? notes : "لا توجد ملاحظات.",
      imageUrl: imageUrl,
      senderName: _currentUser!.name,
      receiverName: "",
    );

    // 2. Create Notification Object
    final newNotif = NotificationModel(
      id: notifId,
      sender: _currentUser!.name,
      senderDept: _currentUser!.department,
      time: "الآن",
      project: project,
      version: version,
      part: part,
      jo: jo,
      qty: qty,
      status: "pending",
      type: "transfer",
      transferId: transferId,
      toDept: toDept,
    );

    // Update in-memory lists
    _transfers.insert(0, newTransfer);
    _notifications.insert(0, newNotif);

    notifyListeners();

    // Persist to service (Firebase/Local)
    await FirebaseService.saveTransfer(newTransfer);
    await FirebaseService.saveNotification(newNotif);
  }

  // Accept notification and increment project job order progress
  Future<void> acceptNotification(String notifId) async {
    if (FirebaseService.useBackendApi) {
      final updated = await ApiService.acceptNotification(
        notifId,
        _currentUser?.name ?? '',
      );
      if (updated != null) {
        await refreshData();
      }
      return;
    }

    final notifIndex = _notifications.indexWhere((n) => n.id == notifId);
    if (notifIndex < 0) return;

    // 1. Update Notification
    final notif = _notifications[notifIndex];
    final updatedNotif = notif.copyWith(status: 'accepted');
    _notifications[notifIndex] = updatedNotif;

    // 2. Update Transfer status
    final transferIndex = _transfers.indexWhere(
      (t) => t.id == notif.transferId,
    );
    if (transferIndex >= 0) {
      final transfer = _transfers[transferIndex];
      final updatedTransfer = transfer.copyWith(
        status: 'تم الاستلام',
        receiverName: _currentUser?.name ?? '',
      );
      _transfers[transferIndex] = updatedTransfer;
      await FirebaseService.saveTransfer(updatedTransfer);

      // 3. Update Project Job Order progress
      final projectIndex = _projects.indexWhere(
        (p) => p.name == transfer.project && p.version == transfer.version,
      );

      if (projectIndex >= 0) {
        final project = _projects[projectIndex];
        final joList = List<JobOrderModel>.from(project.jobOrders);
        final joIndex = joList.indexWhere((j) => j.jo == transfer.jo);

        if (joIndex >= 0) {
          final jo = joList[joIndex];
          // Add delivered quantity (capped at required quantity)
          final newDelivered = (jo.delivered + transfer.qty).clamp(
            0,
            jo.required,
          );
          joList[joIndex] = jo.copyWith(delivered: newDelivered);

          final todayStr = DateFormat('dd/MM/yyyy').format(DateTime.now());
          final updatedProject = project.copyWith(
            jobOrders: joList,
            lastUpdate: todayStr,
          );

          _projects[projectIndex] = updatedProject;
          await FirebaseService.saveProject(updatedProject);
        }
      }
    }

    notifyListeners();
    await FirebaseService.saveNotification(updatedNotif);
  }

  // Reject transfer notification
  Future<void> rejectNotification(String notifId) async {
    if (FirebaseService.useBackendApi) {
      final updated = await ApiService.rejectNotification(
        notifId,
        _currentUser?.name ?? '',
      );
      if (updated != null) {
        await refreshData();
      }
      return;
    }

    final notifIndex = _notifications.indexWhere((n) => n.id == notifId);
    if (notifIndex < 0) return;

    // 1. Update Notification
    final notif = _notifications[notifIndex];
    final updatedNotif = notif.copyWith(status: 'rejected');
    _notifications[notifIndex] = updatedNotif;

    // 2. Update Transfer status
    final transferIndex = _transfers.indexWhere(
      (t) => t.id == notif.transferId,
    );
    if (transferIndex >= 0) {
      final transfer = _transfers[transferIndex];
      final updatedTransfer = transfer.copyWith(
        status: 'مرفوضة',
        receiverName: _currentUser?.name ?? '',
      );
      _transfers[transferIndex] = updatedTransfer;
      await FirebaseService.saveTransfer(updatedTransfer);
    }

    notifyListeners();
    await FirebaseService.saveNotification(updatedNotif);
  }

  // Update user profile details
  Future<void> updateUserProfile({
    required String name,
    required String department,
    required String role,
    String? avatarDataUrl,
  }) async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(
      name: name,
      department: department,
      role: '$role - $department',
      avatar: avatarDataUrl ?? _currentUser!.avatar,
    );

    _currentUser = updatedUser;
    notifyListeners();

    await FirebaseService.saveUser(updatedUser);
  }

  // Filtering Notification lists
  List<NotificationModel> getFilteredNotifications() {
    if (_notifFilter == 'all') {
      return _notifications;
    } else if (_notifFilter == 'accepted') {
      return _notifications.where((n) => n.status == 'accepted').toList();
    } else if (_notifFilter == 'pending') {
      return _notifications.where((n) => n.status == 'pending').toList();
    } else if (_notifFilter == 'technical') {
      // Show notifications with Painting/Quality department targets or involving specific categories
      return _notifications.where((n) {
        final transfer = _transfers.firstWhere(
          (t) => t.id == n.transferId,
          orElse: () => TransferModel(
            id: '',
            date: '',
            project: '',
            version: '',
            jo: '',
            part: '',
            qty: 0,
            fromDept: '',
            toDept: '',
            status: '',
            notes: '',
            senderName: '',
            receiverName: '',
          ),
        );
        return transfer.toDept == 'Painting' ||
            transfer.toDept == 'Quality' ||
            transfer.toDept == 'دهان' ||
            transfer.toDept == 'جودة';
      }).toList();
    }
    return _notifications;
  }
}
