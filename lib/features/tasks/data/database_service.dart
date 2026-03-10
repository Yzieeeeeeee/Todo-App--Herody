import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:to_do_app_herody/features/tasks/data/task_model.dart';

class DatabaseService {
  static const String _baseUrl =
      'https://to-do-f6e06-default-rtdb.asia-southeast1.firebasedatabase.app';

  final String userId;
  DatabaseService(this.userId);

  String get _tasksUrl => '$_baseUrl/users/$userId/tasks';

  // ✅ Build URL with or without token safely
  Uri _buildUrl(String path) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⚠️ No user logged in — using unauthenticated URL');
      return Uri.parse('$path.json');
    }
    // Use UID directly — works with test mode rules
    return Uri.parse('$path.json');
  }

  // ✅ Get token safely — returns null if not logged in
  Future<String?> _getToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken(true);
    } catch (e) {
      debugPrint('Token error: $e');
      return null;
    }
  }

  // ✅ Build authenticated URL
  Future<Uri> _authUrl(String path) async {
    final token = await _getToken();
    if (token != null) {
      return Uri.parse('$path.json?auth=$token');
    }
    // No token — only works with test mode rules
    debugPrint('⚠️ No token — using open rules');
    return Uri.parse('$path.json');
  }

  // ─────────────────────────────────────────────────────────────
  // 1. FETCH
  // ─────────────────────────────────────────────────────────────
  Future<List<Task>> fetchTasks() async {
    try {
      final url = await _authUrl(_tasksUrl);
      debugPrint('📡 FETCH: $url');

      final response = await http.get(url);
      debugPrint('📡 FETCH status: ${response.statusCode}');
      debugPrint('📡 FETCH body: ${response.body}');

      if (response.statusCode == 200 && response.body != 'null') {
        final decoded = json.decode(response.body);
        if (decoded is! Map) return [];

        final data = Map<String, dynamic>.from(decoded);
        final List<Task> tasks = [];

        data.forEach((key, value) {
          try {
            if (value is Map) {
              tasks.add(Task.fromJson(Map<String, dynamic>.from(value)));
            }
          } catch (e) {
            debugPrint('Skipping bad entry $key: $e');
          }
        });

        tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        debugPrint('✅ Loaded ${tasks.length} tasks');
        return tasks;
      }
      return [];
    } catch (e) {
      debugPrint('❌ fetchTasks error: $e');
      throw 'Failed to fetch tasks: $e';
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 2. ADD
  // ─────────────────────────────────────────────────────────────
  Future<void> addTask(Task task) async {
    try {
      final url = await _authUrl('$_tasksUrl/${task.id}');
      debugPrint('📡 ADD URL: $url');
      debugPrint('📡 ADD BODY: ${json.encode(task.toJson())}');

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(task.toJson()),
      );

      debugPrint('📡 ADD status: ${response.statusCode}');
      debugPrint('📡 ADD response: ${response.body}');

      if (response.statusCode != 200) {
        throw 'Status: ${response.statusCode} — ${response.body}';
      }
    } catch (e) {
      debugPrint('❌ addTask error: $e');
      throw 'Failed to add task: $e';
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 3. UPDATE
  // ─────────────────────────────────────────────────────────────
  Future<void> updateTask(Task task) async {
    try {
      final url = await _authUrl('$_tasksUrl/${task.id}');

      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': task.title,
          'description': task.description,
          'isCompleted': task.isCompleted,
          'priority': task.priority,
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      );

      debugPrint('📡 UPDATE status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw 'Status: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Failed to update task: $e';
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 4. DELETE
  // ─────────────────────────────────────────────────────────────
  Future<void> deleteTask(String taskId) async {
    try {
      final url = await _authUrl('$_tasksUrl/$taskId');

      final response = await http.delete(url);
      debugPrint('📡 DELETE status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw 'Status: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Failed to delete task: $e';
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 5. CREATE user profile
  // ─────────────────────────────────────────────────────────────
  Future<void> createUserProfile({
    required String email,
    required String displayName,
  }) async {
    try {
      final url = await _authUrl('$_baseUrl/users/$userId/profile');

      await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'displayName': displayName,
          'createdAt': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      throw 'Failed to create profile: $e';
    }
  }
}