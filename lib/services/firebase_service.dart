import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/models.dart';
import 'api_service.dart';

class FirebaseService {
  static bool _firebaseEnabled = false;
  static SharedPreferences? _prefs;

  // Toggle this to true to use FastAPI backend, false to use Firebase/Local
  static const bool useBackendApi = true;

  static bool get isFirebaseEnabled => !useBackendApi && _firebaseEnabled;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    if (useBackendApi) {
      debugPrint("Atra: Real Python Backend API mode enabled.");
      // Seeding projects in the backend on startup is handled by FastAPI itself.
      return;
    }

    try {
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyCKNgHPYWNuyOzXNJiJMlnECkPmw7Av3Tg",
            appId: "1:504921218841:web:d7045cce88427e64b4af88",
            messagingSenderId: "504921218841",
            projectId: "transfer-system-adb99",
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
      _firebaseEnabled = true;
    } catch (e) {
      _firebaseEnabled = false;
    }

    try {
      // Auto-import projects from assets/projects.json if missing or updated
      await _importProjectsFromAssetIfChanged();
    } catch (e) {
      print("Error importing projects from asset: $e");
    }

    try {
      // Seed initial data if empty
      await _seedInitialDataIfEmpty();
    } catch (e) {
      print("Error seeding initial data: $e");
    }

    if (_firebaseEnabled) {
      try {
        final docRef = FirebaseFirestore.instance.collection('config').doc('app_config');
        final doc = await docRef.get();
        if (!doc.exists) {
          await docRef.set({
            'latestVersionCode': 1,
            'latestVersionName': '1.0.0',
            'apkUrl': 'https://your-domain.com/app-release.apk',
            'whatsNewAr': 'تم تحديث التطبيق وإضافة ميزات جديدة ومزامنة البيانات.',
            'whatsNewEn': 'App updated with new features and data sync.',
          });
        }
      } catch (e) {
        print("Error seeding app config: $e");
      }
    }
  }

  static Future<Map<String, dynamic>?> getAppConfig() async {
    if (useBackendApi) {
      return ApiService.getAppConfig();
    }

    if (_firebaseEnabled) {
      try {
        final doc = await FirebaseFirestore.instance.collection('config').doc('app_config').get();
        if (doc.exists) {
          return doc.data();
        }
      } catch (e) {
        print("Error getting app config from Firestore: $e");
      }
    }
    return null;
  }

  static Future<void> _importProjectsFromAssetIfChanged() async {
    try {
      final jsonString = await rootBundle.loadString('assets/projects.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      final newProjects = jsonList.map((x) => ProjectModel.fromMap(x as Map<String, dynamic>)).toList();
      
      final savedProjects = await getProjects();
      final loadedLength = jsonString.length;
      final lastLoadedLength = _prefs?.getInt('projects_json_length_v4') ?? 0;
      
      if (savedProjects.isEmpty || lastLoadedLength != loadedLength) {
        print("Detected changes in projects.json (stored: $lastLoadedLength, new: $loadedLength). Importing ${newProjects.length} projects...");
        await saveAllProjects(newProjects);
        await _prefs?.setInt('projects_json_length_v4', loadedLength);
        print("Import complete!");
      }
    } catch (e) {
      print("Error importing projects.json: $e");
    }
  }

  // ==========================================================================
  // USER METADATA OPERATIONS
  // ==========================================================================

  static Future<UserModel> getUser() async {
    final rawUser = _prefs?.getString('user_profile');
    String userId = 'EMP-001';
    UserModel? localUser;

    if (rawUser != null) {
      try {
        localUser = UserModel.fromJson(rawUser);
        userId = localUser.id;
      } catch (e) {
        print("Error parsing local user: $e");
      }
    }

    if (useBackendApi) {
      final user = await ApiService.getUserById(userId);
      if (user != null) {
        await _prefs?.setString('user_profile', user.toJson());
        return user;
      }
    } else if (_firebaseEnabled && userId.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (doc.exists && doc.data() != null) {
          final firestoreUser = UserModel.fromMap(doc.data()!);
          await _prefs?.setString('user_profile', firestoreUser.toJson());
          return firestoreUser;
        }
      } catch (e) {
        print("Error getting user from Firestore ($userId): $e");
      }
    }
    
    if (localUser != null) {
      return localUser;
    }
    
    final defaultUser = UserModel(
      id: "EMP-001",
      name: "أحمد محمد",
      role: "مشرف - تشكيل",
      department: "تشكيل",
      avatar: "assets/avatar.png",
      password: "0000",
    );
    await saveUser(defaultUser);
    return defaultUser;
  }

  static Future<UserModel?> getUserById(String id) async {
    if (useBackendApi) {
      return ApiService.getUserById(id);
    }

    if (_firebaseEnabled) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(id).get();
        if (doc.exists && doc.data() != null) {
          final user = UserModel.fromMap(doc.data()!);
          await _prefs?.setString('user_profile_$id', user.toJson());
          return user;
        }
      } catch (e) {
        print("Error getting user by ID ($id) from Firestore: $e");
      }
    }
    
    final rawUser = _prefs?.getString('user_profile_$id');
    if (rawUser != null) {
      try {
        return UserModel.fromJson(rawUser);
      } catch (e) {
        print("Error parsing local user $id: $e");
      }
    }
    return null;
  }

  static Future<void> saveUser(UserModel user) async {
    if (useBackendApi) {
      await ApiService.saveUser(user);
    } else if (_firebaseEnabled) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.id).set(user.toMap());
      } catch (e) {
        print("Error saving user to Firestore: $e");
      }
    }
    // Always persist locally
    await _prefs?.setString('user_profile', user.toJson());
    await _prefs?.setString('user_profile_${user.id}', user.toJson());
  }

  // ==========================================================================
  // TRANSFERS OPERATIONS
  // ==========================================================================

  static Future<List<TransferModel>> getTransfers() async {
    if (useBackendApi) {
      return ApiService.getTransfers();
    }

    if (_firebaseEnabled) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('transfers')
            .orderBy('date', descending: true)
            .get();
        return snapshot.docs.map((doc) => TransferModel.fromMap(doc.data())).toList();
      } catch (e) {
        print("Error getting transfers from Firestore: $e");
      }
    }

    // Fallback/Local
    final rawTransfers = _prefs?.getStringList('transfers');
    if (rawTransfers != null) {
      return rawTransfers.map((item) => TransferModel.fromJson(item)).toList();
    }
    return [];
  }

  static Future<void> saveTransfer(TransferModel transfer) async {
    if (useBackendApi) {
      await ApiService.saveTransfer(transfer);
    } else if (_firebaseEnabled) {
      try {
        await FirebaseFirestore.instance.collection('transfers').doc(transfer.id).set(transfer.toMap());
      } catch (e) {
        print("Error saving transfer to Firestore: $e");
      }
    }

    // Save locally
    final transfers = await getTransfers();
    final index = transfers.indexWhere((t) => t.id == transfer.id);
    if (index >= 0) {
      transfers[index] = transfer;
    } else {
      transfers.insert(0, transfer);
    }
    await _prefs?.setStringList('transfers', transfers.map((t) => t.toJson()).toList());
  }

  // ==========================================================================
  // NOTIFICATIONS OPERATIONS
  // ==========================================================================

  static Future<List<NotificationModel>> getNotifications() async {
    if (useBackendApi) {
      return ApiService.getNotifications();
    }

    if (_firebaseEnabled) {
      try {
        final snapshot = await FirebaseFirestore.instance.collection('notifications').get();
        return snapshot.docs.map((doc) => NotificationModel.fromMap(doc.data())).toList();
      } catch (e) {
        print("Error getting notifications from Firestore: $e");
      }
    }

    // Fallback/Local
    final rawNotifs = _prefs?.getStringList('notifications');
    if (rawNotifs != null) {
      return rawNotifs.map((item) => NotificationModel.fromJson(item)).toList();
    }
    return [];
  }

  static Future<void> saveNotification(NotificationModel notification) async {
    if (useBackendApi) {
      await ApiService.saveNotification(notification);
    } else if (_firebaseEnabled) {
      try {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notification.id)
            .set(notification.toMap());
      } catch (e) {
        print("Error saving notification to Firestore: $e");
      }
    }

    // Save locally
    final notifications = await getNotifications();
    final index = notifications.indexWhere((n) => n.id == notification.id);
    if (index >= 0) {
      notifications[index] = notification;
    } else {
      notifications.insert(0, notification);
    }
    await _prefs?.setStringList('notifications', notifications.map((n) => n.toJson()).toList());
  }

  // ==========================================================================
  // PROJECTS OPERATIONS
  // ==========================================================================

  static Future<List<ProjectModel>> getProjects() async {
    if (useBackendApi) {
      return ApiService.getProjects();
    }

    if (_firebaseEnabled) {
      try {
        final snapshot = await FirebaseFirestore.instance.collection('projects').get();
        return snapshot.docs.map((doc) => ProjectModel.fromMap(doc.data())).toList();
      } catch (e) {
        print("Error getting projects from Firestore: $e");
      }
    }

    // Fallback/Local
    final rawProjects = _prefs?.getStringList('projects');
    if (rawProjects != null) {
      return rawProjects.map((item) => ProjectModel.fromJson(item)).toList();
    }
    return [];
  }

  static Future<void> saveProject(ProjectModel project) async {
    if (useBackendApi) {
      await ApiService.saveProject(project);
    } else if (_firebaseEnabled) {
      try {
        await FirebaseFirestore.instance.collection('projects').doc(project.id).set(project.toMap());
      } catch (e) {
        print("Error saving project to Firestore: $e");
      }
    }

    // Save locally
    final projects = await getProjects();
    final index = projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      projects[index] = project;
    } else {
      projects.add(project);
    }
    await _prefs?.setStringList('projects', projects.map((p) => p.toJson()).toList());
  }

  static Future<void> saveAllProjects(List<ProjectModel> newProjects) async {
    if (useBackendApi) {
      for (var p in newProjects) {
        await ApiService.saveProject(p);
      }
      return;
    }

    if (_firebaseEnabled) {
      try {
        final collection = FirebaseFirestore.instance.collection('projects');
        final existingSnapshot = await collection.get();
        var deleteBatch = FirebaseFirestore.instance.batch();
        int deleteCount = 0;
        for (var doc in existingSnapshot.docs) {
          deleteBatch.delete(doc.reference);
          deleteCount++;
          if (deleteCount == 500) {
            await deleteBatch.commit();
            deleteBatch = FirebaseFirestore.instance.batch();
            deleteCount = 0;
          }
        }
        if (deleteCount > 0) {
          await deleteBatch.commit();
        }

        var writeBatch = FirebaseFirestore.instance.batch();
        int writeCount = 0;
        for (var p in newProjects) {
          final docRef = collection.doc(p.id);
          writeBatch.set(docRef, p.toMap());
          writeCount++;
          if (writeCount == 500) {
            await writeBatch.commit();
            writeBatch = FirebaseFirestore.instance.batch();
            writeCount = 0;
          }
        }
        if (writeCount > 0) {
          await writeBatch.commit();
        }
      } catch (e) {
        print("Error saving all projects to Firestore: $e");
      }
    }

    // Save locally
    if (_prefs != null) {
      await _prefs!.setStringList('projects', newProjects.map((p) => p.toJson()).toList());
    }
  }

  // ==========================================================================
  // SEED MOCK DATA LOGIC
  // ==========================================================================

  static Future<void> _seedInitialDataIfEmpty() async {
    // Check if seeded
    bool isSeeded = _prefs?.getBool('data_seeded') ?? false;

    if (!isSeeded) {
      // 1. Seed user profile
      final user = UserModel(
        id: "EMP-001",
        name: "أحمد محمد",
        role: "مشرف - تشكيل",
        department: "تشكيل",
        avatar: "assets/avatar.png",
      );
      await saveUser(user);

      // Set seeded flag
      await _prefs?.setBool('data_seeded', true);
    }
  }
}
