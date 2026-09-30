import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://192.168.1.9:8000/api';
      }
    } catch (_) {}
    return 'http://localhost:8000/api';
  }

  static Future<Map<String, dynamic>?> getAppConfig() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/config'));
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("ApiService: getAppConfig error: $e");
    }
    return null;
  }

  static Future<UserModel?> getUserById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$id'));
      if (response.statusCode == 200) {
        return UserModel.fromJson(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      debugPrint("ApiService: getUserById error: $e");
    }
    return null;
  }

  static Future<UserModel?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode({'username': username, 'password': password}),
      );
      if (response.statusCode == 200) {
        return UserModel.fromJson(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      debugPrint("ApiService: login error: $e");
    }
    return null;
  }

  static Future<void> saveUser(UserModel user) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: user.toJson(),
      );
    } catch (e) {
      debugPrint("ApiService: saveUser error: $e");
    }
  }

  static Future<List<ProjectModel>> getProjects() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/projects'));
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(response.bodyBytes));
        return list.map((item) => ProjectModel.fromMap(item)).toList();
      }
    } catch (e) {
      debugPrint("ApiService: getProjects error: $e");
    }
    return [];
  }

  static Future<void> saveProject(ProjectModel project) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/projects'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: project.toJson(),
      );
    } catch (e) {
      debugPrint("ApiService: saveProject error: $e");
    }
  }

  static Future<List<TransferModel>> getTransfers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/transfers'));
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(response.bodyBytes));
        return list.map((item) => TransferModel.fromMap(item)).toList();
      }
    } catch (e) {
      debugPrint("ApiService: getTransfers error: $e");
    }
    return [];
  }

  static Future<void> saveTransfer(TransferModel transfer) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/transfers'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: transfer.toJson(),
      );
    } catch (e) {
      debugPrint("ApiService: saveTransfer error: $e");
    }
  }

  static Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/notifications'));
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(response.bodyBytes));
        return list.map((item) => NotificationModel.fromMap(item)).toList();
      }
    } catch (e) {
      debugPrint("ApiService: getNotifications error: $e");
    }
    return [];
  }

  static Future<void> saveNotification(NotificationModel notification) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/notifications'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: notification.toJson(),
      );
    } catch (e) {
      debugPrint("ApiService: saveNotification error: $e");
    }
  }

  static Future<NotificationModel?> acceptNotification(String notifId, String receiverName) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$notifId/accept?receiver_name=${Uri.encodeQueryComponent(receiverName)}'),
      );
      if (response.statusCode == 200) {
        return NotificationModel.fromJson(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      debugPrint("ApiService: acceptNotification error: $e");
    }
    return null;
  }

  static Future<NotificationModel?> rejectNotification(String notifId, String receiverName) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$notifId/reject?receiver_name=${Uri.encodeQueryComponent(receiverName)}'),
      );
      if (response.statusCode == 200) {
        return NotificationModel.fromJson(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      debugPrint("ApiService: rejectNotification error: $e");
    }
    return null;
  }
}
