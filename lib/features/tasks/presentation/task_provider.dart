import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:to_do_app_herody/features/tasks/data/task_model.dart';
import 'package:to_do_app_herody/features/tasks/data/database_service.dart';
import '../../../core/providers/notification_provider.dart';

enum TaskStatus { initial, loading, loaded, error }

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  TaskStatus _status = TaskStatus.initial;
  String? _errorMessage;
  DatabaseService? _dbService;
  String? _currentUserId;
  bool _isFetching = false;

  // ── Countdown timer — ticks every second ─────────────────────
  Timer? _countdownTimer;

  // ── Notification provider reference ──────────────────────────
  NotificationProvider? _notifProvider;

  void setNotifProvider(NotificationProvider p) {
    _notifProvider = p;
  }

  // ── Getters ───────────────────────────────────────────────────
  List<Task> get tasks => _tasks;
  TaskStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == TaskStatus.loading && _tasks.isEmpty;

  List<Task> get pendingTasks => _tasks.where((t) => !t.isCompleted).toList();
  List<Task> get completedTasks => _tasks.where((t) => t.isCompleted).toList();
  List<Task> get highPriorityTasks =>
      _tasks.where((t) => t.priority == 'high' && !t.isCompleted).toList();

  int get totalTasks => _tasks.length;
  int get completedCount => completedTasks.length;
  int get pendingCount => pendingTasks.length;
  double get completionPercentage =>
      _tasks.isEmpty ? 0.0 : completedCount / totalTasks;

  // ── Countdown helpers ─────────────────────────────────────────
  String? getCountdown(Task task) {
    if (task.alarmTime == null || task.isCompleted) return null;
    final diff = task.alarmTime!.difference(DateTime.now());
    if (diff.isNegative) return 'Overdue';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${_pad(s)}s';
    if (m > 0) return '${m}m ${_pad(s)}s';
    return '${_pad(s)}s';
  }

  String _pad(int v) => v.toString().padLeft(2, '0');

  bool isAlarmOverdue(Task task) {
    if (task.alarmTime == null || task.isCompleted) return false;
    return task.alarmTime!.isBefore(DateTime.now());
  }

  // ─────────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────────
  Future<void> init(String userId) async {
    if (_currentUserId == userId &&
        (_status == TaskStatus.loaded || _status == TaskStatus.loading)) {
      debugPrint('TaskProvider: skipping init — already loaded for $userId');
      return;
    }

    debugPrint('TaskProvider: fresh init for $userId');
    _currentUserId = userId;
    _dbService = DatabaseService(userId);
    _notifProvider?.resetSession();
    await fetchTasks();
    _startCountdownTimer();
  }

  // ─────────────────────────────────────────────────────────────
  // COUNTDOWN TIMER
  // ─────────────────────────────────────────────────────────────
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final hasAlarms = _tasks.any(
        (t) => t.alarmTime != null && !t.isCompleted,
      );
      if (hasAlarms) notifyListeners();
    });
  }

  // ─────────────────────────────────────────────────────────────
  // CLEAR
  // ─────────────────────────────────────────────────────────────
  void clear() {
    _countdownTimer?.cancel();
    _tasks = [];
    _status = TaskStatus.initial;
    _errorMessage = null;
    _currentUserId = null;
    _dbService = null;
    _isFetching = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // FETCH
  // ─────────────────────────────────────────────────────────────
  Future<void> fetchTasks() async {
    if (_dbService == null) return;
    if (_isFetching) return;

    _isFetching = true;
    try {
      if (_tasks.isEmpty) {
        _status = TaskStatus.loading;
        notifyListeners();
      }
      final fetched = await _dbService!.fetchTasks();
      _tasks = fetched;
      _status = TaskStatus.loaded;
      notifyListeners();

      // Analyse after fetch
      _notifProvider?.analyzePerformance(_tasks);

      debugPrint('TaskProvider: fetched ${_tasks.length} tasks ✅');
    } catch (e) {
      _setError(e.toString());
    } finally {
      _isFetching = false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ADD
  // ─────────────────────────────────────────────────────────────
  Future<bool> addTask({
    required String title,
    String description = '',
    String priority = 'medium',
    DateTime? alarmTime,
  }) async {
    if (_dbService == null) return false;

    final now = DateTime.now();
    final task = Task(
      id: const Uuid().v4(),
      title: title.trim(),
      description: description.trim(),
      priority: priority,
      createdAt: now,
      updatedAt: now,
      alarmTime: alarmTime,
    );

    _tasks.insert(0, task);
    _status = TaskStatus.loaded;
    notifyListeners();

    // Activity log
    _notifProvider?.add(
      taskId: task.id,
      taskTitle: task.title,
      message: '"${task.title}" added to your tasks',
      type: NotifType.taskAdded,
    );

    if (alarmTime != null) {
      _notifProvider?.add(
        taskId: task.id,
        taskTitle: task.title,
        message: 'Alarm set for ${_formatTime(alarmTime)}',
        type: NotifType.alarmSet,
      );
    }

    // Re-analyse after add
    _notifProvider?.analyzePerformance(_tasks);

    try {
      await _dbService!.addTask(task);
      return true;
    } catch (e) {
      _tasks.removeWhere((t) => t.id == task.id);
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────────────────────
  Future<bool> updateTask({
    required String taskId,
    required String title,
    String description = '',
    String priority = 'medium',
    DateTime? alarmTime,
    bool clearAlarm = false,
  }) async {
    if (_dbService == null) return false;

    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return false;

    final oldTask = _tasks[index];
    final updatedTask = oldTask.copyWith(
      title: title.trim(),
      description: description.trim(),
      priority: priority,
      updatedAt: DateTime.now(),
      alarmTime: alarmTime,
      clearAlarm: clearAlarm,
    );

    _tasks[index] = updatedTask;
    notifyListeners();

    if (clearAlarm && oldTask.alarmTime != null) {
      _notifProvider?.add(
        taskId: taskId,
        taskTitle: updatedTask.title,
        message: 'Alarm removed from "${updatedTask.title}"',
        type: NotifType.alarmCancelled,
      );
    } else if (alarmTime != null) {
      _notifProvider?.add(
        taskId: taskId,
        taskTitle: updatedTask.title,
        message: 'Alarm updated to ${_formatTime(alarmTime)}',
        type: NotifType.alarmSet,
      );
    }

    _notifProvider?.analyzePerformance(_tasks);

    try {
      await _dbService!.updateTask(updatedTask);
      return true;
    } catch (e) {
      _tasks[index] = oldTask;
      notifyListeners();
      _setError('Failed to update: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // TOGGLE COMPLETE
  // ─────────────────────────────────────────────────────────────
  Future<void> toggleComplete(String taskId) async {
    if (_dbService == null) return;

    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final oldTask = _tasks[index];
    final nowCompleted = !oldTask.isCompleted;

    _tasks[index] = oldTask.copyWith(
      isCompleted: nowCompleted,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    if (nowCompleted) {
      _notifProvider?.onTaskCompleted();
      _notifProvider?.add(
        taskId: taskId,
        taskTitle: oldTask.title,
        message: '"${oldTask.title}" marked as complete 🎊',
        type: NotifType.taskCompleted,
      );
    }

    // Re-analyse every toggle — catches milestones
    _notifProvider?.analyzePerformance(_tasks);

    try {
      await _dbService!.updateTask(_tasks[index]);
    } catch (e) {
      _tasks[index] = oldTask;
      notifyListeners();
      _setError('Failed to toggle: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────────────
  Future<bool> deleteTask(String taskId) async {
    if (_dbService == null) return false;

    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return false;

    final deletedTask = _tasks[index];
    _tasks.removeAt(index);
    notifyListeners();

    _notifProvider?.add(
      taskId: taskId,
      taskTitle: deletedTask.title,
      message: '"${deletedTask.title}" was deleted',
      type: NotifType.taskDeleted,
    );

    _notifProvider?.analyzePerformance(_tasks);

    try {
      await _dbService!.deleteTask(taskId);
      return true;
    } catch (e) {
      _tasks.insert(index, deletedTask);
      notifyListeners();
      _setError('Failed to delete: $e');
      return false;
    }
  }

  // ── Set alarm ─────────────────────────────────────────────────
  Future<void> setAlarm(String taskId, DateTime alarmTime) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = _tasks[index].copyWith(
      alarmTime: alarmTime,
      updatedAt: DateTime.now(),
    );
    _tasks[index] = task;
    notifyListeners();

    _notifProvider?.add(
      taskId: taskId,
      taskTitle: task.title,
      message: 'Alarm set for ${_formatTime(alarmTime)}',
      type: NotifType.alarmSet,
    );

    _notifProvider?.analyzePerformance(_tasks);

    try {
      await _dbService!.updateTask(task);
    } catch (_) {}
  }

  // ── Remove alarm ──────────────────────────────────────────────
  Future<void> removeAlarm(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = _tasks[index].copyWith(
      clearAlarm: true,
      updatedAt: DateTime.now(),
    );
    _tasks[index] = task;
    notifyListeners();

    _notifProvider?.add(
      taskId: taskId,
      taskTitle: task.title,
      message: 'Alarm removed from "${task.title}"',
      type: NotifType.alarmCancelled,
    );

    try {
      await _dbService!.updateTask(task);
    } catch (_) {}
  }

  // ── Helpers ───────────────────────────────────────────────────
  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm, ${dt.day}/${dt.month}/${dt.year}';
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = TaskStatus.error;
    _isFetching = false;
    notifyListeners();
    debugPrint('TaskProvider ERROR: $message');
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
