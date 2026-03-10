class Task {
  final String id;
  String title;
  String description;
  bool isCompleted;
  String priority; // 'low' | 'medium' | 'high'
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime? alarmTime;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.priority = 'medium',
    required this.createdAt,
    required this.updatedAt,
    this.alarmTime,
  });

  // ── Convert Task → JSON (to send to Firebase) ────────────────
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'isCompleted': isCompleted,
    'priority': priority,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'alarmTime': alarmTime?.toIso8601String(),
  };

  // ── Convert JSON → Task (received from Firebase) ─────────────
  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    isCompleted: json['isCompleted'] ?? false,
    priority: json['priority'] ?? 'medium',
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    alarmTime: json['alarmTime'] != null
        ? DateTime.tryParse(json['alarmTime'])
        : null,
  );

  // ── Copy with modified fields ─────────────────────────────────
  Task copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    String? priority,
    DateTime? updatedAt,
    DateTime? alarmTime,
    bool clearAlarm = false,
  }) => Task(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    isCompleted: isCompleted ?? this.isCompleted,
    priority: priority ?? this.priority,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    alarmTime: clearAlarm ? null : (alarmTime ?? this.alarmTime),
  );
}
