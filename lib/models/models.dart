import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String role;
  final String department;
  final String? avatar; // Can be asset path or base64 data URL
  final String? password;

  UserModel({
    required this.id,
    required this.name,
    required this.role,
    required this.department,
    this.avatar,
    this.password,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? role,
    String? department,
    String? avatar,
    String? password,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      department: department ?? this.department,
      avatar: avatar ?? this.avatar,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'department': department,
      'avatar': avatar,
      'password': password,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      department: map['department'] ?? '',
      avatar: map['avatar'],
      password: map['password'],
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) => UserModel.fromMap(json.decode(source));
}

class TransferModel {
  final String id;
  final String date;
  final String project;
  final String version;
  final String jo;
  final String part;
  final int qty;
  final String fromDept;
  final String toDept;
  final String status; // 'تم الاستلام', 'قيد الانتظار', 'مرفوضة'
  final String notes;
  final String? imageUrl; // For optional image upload
  final String senderName;
  final String receiverName;

  TransferModel({
    required this.id,
    required this.date,
    required this.project,
    required this.version,
    required this.jo,
    required this.part,
    required this.qty,
    required this.fromDept,
    required this.toDept,
    required this.status,
    required this.notes,
    this.imageUrl,
    required this.senderName,
    required this.receiverName,
  });

  TransferModel copyWith({
    String? id,
    String? date,
    String? project,
    String? version,
    String? jo,
    String? part,
    int? qty,
    String? fromDept,
    String? toDept,
    String? status,
    String? notes,
    String? imageUrl,
    String? senderName,
    String? receiverName,
  }) {
    return TransferModel(
      id: id ?? this.id,
      date: date ?? this.date,
      project: project ?? this.project,
      version: version ?? this.version,
      jo: jo ?? this.jo,
      part: part ?? this.part,
      qty: qty ?? this.qty,
      fromDept: fromDept ?? this.fromDept,
      toDept: toDept ?? this.toDept,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      senderName: senderName ?? this.senderName,
      receiverName: receiverName ?? this.receiverName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'project': project,
      'version': version,
      'jo': jo,
      'part': part,
      'qty': qty,
      'fromDept': fromDept,
      'toDept': toDept,
      'status': status,
      'notes': notes,
      'imageUrl': imageUrl,
      'senderName': senderName,
      'receiverName': receiverName,
    };
  }

  factory TransferModel.fromMap(Map<String, dynamic> map) {
    return TransferModel(
      id: map['id'] ?? '',
      date: map['date'] ?? '',
      project: map['project'] ?? '',
      version: map['version'] ?? '',
      jo: map['jo'] ?? '',
      part: map['part'] ?? '',
      qty: map['qty']?.toInt() ?? 0,
      fromDept: map['fromDept'] ?? '',
      toDept: map['toDept'] ?? '',
      status: map['status'] ?? '',
      notes: map['notes'] ?? '',
      imageUrl: map['imageUrl'],
      senderName: map['senderName'] ?? 'أحمد محمد',
      receiverName: map['receiverName'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory TransferModel.fromJson(String source) => TransferModel.fromMap(json.decode(source));
}

class NotificationModel {
  final String id;
  final String sender;
  final String senderDept;
  final String time; // e.g. "منذ 10 دقائق", "الآن"
  final String project;
  final String version;
  final String part;
  final String jo;
  final int qty;
  final String status; // 'pending', 'accepted', 'rejected'
  final String type; // 'transfer'
  final String transferId;
  final String toDept; // target department

  NotificationModel({
    required this.id,
    required this.sender,
    required this.senderDept,
    required this.time,
    required this.project,
    required this.version,
    required this.part,
    required this.jo,
    required this.qty,
    required this.status,
    required this.type,
    required this.transferId,
    required this.toDept,
  });

  NotificationModel copyWith({
    String? id,
    String? sender,
    String? senderDept,
    String? time,
    String? project,
    String? version,
    String? part,
    String? jo,
    int? qty,
    String? status,
    String? type,
    String? transferId,
    String? toDept,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      senderDept: senderDept ?? this.senderDept,
      time: time ?? this.time,
      project: project ?? this.project,
      version: version ?? this.version,
      part: part ?? this.part,
      jo: jo ?? this.jo,
      qty: qty ?? this.qty,
      status: status ?? this.status,
      type: type ?? this.type,
      transferId: transferId ?? this.transferId,
      toDept: toDept ?? this.toDept,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'senderDept': senderDept,
      'time': time,
      'project': project,
      'version': version,
      'part': part,
      'jo': jo,
      'qty': qty,
      'status': status,
      'type': type,
      'transferId': transferId,
      'toDept': toDept,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      sender: map['sender'] ?? '',
      senderDept: map['senderDept'] ?? '',
      time: map['time'] ?? '',
      project: map['project'] ?? '',
      version: map['version'] ?? '',
      part: map['part'] ?? '',
      jo: map['jo'] ?? '',
      qty: map['qty']?.toInt() ?? 0,
      status: map['status'] ?? '',
      type: map['type'] ?? '',
      transferId: map['transferId'] ?? '',
      toDept: map['toDept'] ?? map['receiverDept'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory NotificationModel.fromJson(String source) => NotificationModel.fromMap(json.decode(source));
}

class JobOrderModel {
  final String jo;
  final String part;
  final int required;
  final int delivered;

  JobOrderModel({
    required this.jo,
    required this.part,
    required this.required,
    required this.delivered,
  });

  JobOrderModel copyWith({
    String? jo,
    String? part,
    int? required,
    int? delivered,
  }) {
    return JobOrderModel(
      jo: jo ?? this.jo,
      part: part ?? this.part,
      required: required ?? this.required,
      delivered: delivered ?? this.delivered,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jo': jo,
      'part': part,
      'required': required,
      'delivered': delivered,
    };
  }

  factory JobOrderModel.fromMap(Map<String, dynamic> map) {
    return JobOrderModel(
      jo: map['jo'] ?? '',
      part: map['part'] ?? '',
      required: map['required']?.toInt() ?? 0,
      delivered: map['delivered']?.toInt() ?? 0,
    );
  }
}

class ProjectModel {
  final String id;
  final String name;
  final String version;
  final String lastUpdate;
  final List<JobOrderModel> jobOrders;

  ProjectModel({
    required this.id,
    required this.name,
    required this.version,
    required this.lastUpdate,
    required this.jobOrders,
  });

  ProjectModel copyWith({
    String? id,
    String? name,
    String? version,
    String? lastUpdate,
    List<JobOrderModel>? jobOrders,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      jobOrders: jobOrders ?? this.jobOrders,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'lastUpdate': lastUpdate,
      'jobOrders': jobOrders.map((x) => x.toMap()).toList(),
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      version: map['version'] ?? '',
      lastUpdate: map['lastUpdate'] ?? '',
      jobOrders: List<JobOrderModel>.from(
        (map['jobOrders'] as List<dynamic>?)?.map((x) => JobOrderModel.fromMap(x as Map<String, dynamic>)) ?? const [],
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory ProjectModel.fromJson(String source) => ProjectModel.fromMap(json.decode(source));
}
