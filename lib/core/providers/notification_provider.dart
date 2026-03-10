import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:to_do_app_herody/features/tasks/data/task_model.dart';

// ── Notification types ────────────────────────────────────────────
enum NotifType {
  // Performance
  allTasksDone,
  greatProgress,
  halfwayThere,
  justStarted,
  // Reminders
  highPriorityPending,
  alarmOverdue,
  alarmUpcoming,
  // Analysis
  productivityTip,
  streakAchieved,
  idleWarning,
  taskAdded,
  taskCompleted,
  taskDeleted,
  alarmSet,
  alarmCancelled,
}

extension NotifTypeExtension on NotifType {
  String get label {
    switch (this) {
      case NotifType.allTasksDone:
        return 'All Done!';
      case NotifType.greatProgress:
        return 'Great Progress';
      case NotifType.halfwayThere:
        return 'Halfway There';
      case NotifType.justStarted:
        return 'Getting Started';
      case NotifType.highPriorityPending:
        return 'High Priority';
      case NotifType.alarmOverdue:
        return 'Overdue';
      case NotifType.alarmUpcoming:
        return 'Upcoming';
      case NotifType.productivityTip:
        return 'Tip';
      case NotifType.streakAchieved:
        return 'Streak!';
      case NotifType.idleWarning:
        return 'Reminder';
      case NotifType.taskAdded:
        return 'Task Added';
      case NotifType.taskCompleted:
        return 'Completed';
      case NotifType.taskDeleted:
        return 'Deleted';
      case NotifType.alarmSet:
        return 'Alarm Set';
      case NotifType.alarmCancelled:
        return 'Alarm Off';
    }
  }

  String get emoji {
    switch (this) {
      case NotifType.allTasksDone:
        return '🎉';
      case NotifType.greatProgress:
        return '🔥';
      case NotifType.halfwayThere:
        return '💪';
      case NotifType.justStarted:
        return '🚀';
      case NotifType.highPriorityPending:
        return '🔴';
      case NotifType.alarmOverdue:
        return '⚠️';
      case NotifType.alarmUpcoming:
        return '⏰';
      case NotifType.productivityTip:
        return '💡';
      case NotifType.streakAchieved:
        return '⭐';
      case NotifType.idleWarning:
        return '👋';
      case NotifType.taskAdded:
        return '✅';
      case NotifType.taskCompleted:
        return '🎊';
      case NotifType.taskDeleted:
        return '🗑️';
      case NotifType.alarmSet:
        return '⏰';
      case NotifType.alarmCancelled:
        return '🔕';
    }
  }

  // Color category for UI
  NotifCategory get category {
    switch (this) {
      case NotifType.allTasksDone:
      case NotifType.greatProgress:
      case NotifType.halfwayThere:
      case NotifType.streakAchieved:
      case NotifType.justStarted:
        return NotifCategory.performance;
      case NotifType.highPriorityPending:
      case NotifType.alarmOverdue:
      case NotifType.alarmUpcoming:
      case NotifType.idleWarning:
        return NotifCategory.reminder;
      case NotifType.productivityTip:
        return NotifCategory.tip;
      case NotifType.taskAdded:
      case NotifType.taskCompleted:
      case NotifType.taskDeleted:
      case NotifType.alarmSet:
      case NotifType.alarmCancelled:
        return NotifCategory.activity;
    }
  }
}

enum NotifCategory { performance, reminder, tip, activity }

extension NotifCategoryExtension on NotifCategory {
  String get label {
    switch (this) {
      case NotifCategory.performance:
        return 'Performance';
      case NotifCategory.reminder:
        return 'Reminder';
      case NotifCategory.tip:
        return 'Tip';
      case NotifCategory.activity:
        return 'Activity';
    }
  }
}

// ── Single notification entry ─────────────────────────────────────
class NotificationEntry {
  final String id;
  final String taskId;
  final String taskTitle;
  final String message;
  final DateTime time;
  final NotifType type;
  bool isRead;

  NotificationEntry({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
  });
}

// ── Provider ──────────────────────────────────────────────────────
class NotificationProvider with ChangeNotifier {
  final List<NotificationEntry> _entries = [];

  // Tracks last analysis state to avoid duplicate smart notifs
  double _lastAnalyzedPercentage = -1;
  int _lastTaskCount = -1;
  int _completedSessionCount = 0; // tasks completed this session
  DateTime? _lastActivityTime;
  Timer? _idleTimer;

  // ── Getters ───────────────────────────────────────────────────
  List<NotificationEntry> get entries =>
      List.unmodifiable(_entries.reversed.toList());

  List<NotificationEntry> get performanceEntries => entries
      .where((e) => e.type.category == NotifCategory.performance)
      .toList();

  List<NotificationEntry> get reminderEntries =>
      entries.where((e) => e.type.category == NotifCategory.reminder).toList();

  List<NotificationEntry> get activityEntries =>
      entries.where((e) => e.type.category == NotifCategory.activity).toList();

  int get unreadCount => _entries.where((e) => !e.isRead).length;
  int get totalCount => _entries.length;

  // ── Add a manual entry ────────────────────────────────────────
  void add({
    required String taskId,
    required String taskTitle,
    required String message,
    required NotifType type,
  }) {
    _entries.add(
      NotificationEntry(
        id: '${DateTime.now().millisecondsSinceEpoch}_${_entries.length}',
        taskId: taskId,
        taskTitle: taskTitle,
        message: message,
        time: DateTime.now(),
        type: type,
      ),
    );
    _lastActivityTime = DateTime.now();
    _resetIdleTimer();
    notifyListeners();
  }

  // ── SMART ANALYSIS — called by TaskProvider on every change ───
  void analyzePerformance(List<Task> tasks) {
    if (tasks.isEmpty) return;

    final total = tasks.length;
    final completed = tasks.where((t) => t.isCompleted).length;
    final percentage = completed / total;
    final highPending = tasks
        .where((t) => t.priority == 'high' && !t.isCompleted)
        .toList();
    final overdue = tasks
        .where(
          (t) =>
              t.alarmTime != null &&
              t.alarmTime!.isBefore(DateTime.now()) &&
              !t.isCompleted,
        )
        .toList();
    final upcoming = tasks
        .where(
          (t) =>
              t.alarmTime != null &&
              t.alarmTime!.isAfter(DateTime.now()) &&
              t.alarmTime!.difference(DateTime.now()).inMinutes <= 30 &&
              !t.isCompleted,
        )
        .toList();

    // ── Completion milestone notifications ──────────────────────
    if (percentage == 1.0 && _lastAnalyzedPercentage != 1.0 && total > 0) {
      _addSmart(
        taskTitle: 'All Tasks Complete!',
        message:
            '🎉 Amazing! You completed all $total tasks. You\'re on fire today!',
        type: NotifType.allTasksDone,
      );
    } else if (percentage >= 0.75 &&
        _lastAnalyzedPercentage < 0.75 &&
        _lastAnalyzedPercentage >= 0) {
      _addSmart(
        taskTitle: 'Great Progress',
        message:
            '🔥 ${(percentage * 100).toInt()}% done! Only ${total - completed} task${total - completed == 1 ? '' : 's'} left.',
        type: NotifType.greatProgress,
      );
    } else if (percentage >= 0.5 &&
        _lastAnalyzedPercentage < 0.5 &&
        _lastAnalyzedPercentage >= 0) {
      _addSmart(
        taskTitle: 'Halfway There!',
        message:
            '💪 You\'ve completed $completed of $total tasks. Keep the momentum!',
        type: NotifType.halfwayThere,
      );
    }

    // ── Session streak ──────────────────────────────────────────
    if (_completedSessionCount > 0 && _completedSessionCount % 3 == 0) {
      _addSmart(
        taskTitle: '$_completedSessionCount Tasks Done This Session!',
        message:
            '⭐ You\'ve completed $_completedSessionCount tasks in a row. You\'re in the zone!',
        type: NotifType.streakAchieved,
      );
    }

    // ── High priority reminder ──────────────────────────────────
    if (highPending.isNotEmpty &&
        _lastTaskCount != total &&
        !_hasRecentNotif(NotifType.highPriorityPending, minutes: 10)) {
      final names = highPending.take(2).map((t) => '"${t.title}"').join(', ');
      _addSmart(
        taskTitle: 'High Priority Tasks Pending',
        message:
            '🔴 ${highPending.length} high-priority task${highPending.length == 1 ? '' : 's'} need attention: $names',
        type: NotifType.highPriorityPending,
      );
    }

    // ── Overdue alarms ──────────────────────────────────────────
    for (final task in overdue) {
      if (!_hasRecentNotifForTask(
        task.id,
        NotifType.alarmOverdue,
        minutes: 30,
      )) {
        _addSmart(
          taskId: task.id,
          taskTitle: task.title,
          message:
              '⚠️ "${task.title}" was due ${_timeAgo(task.alarmTime!)} and is still pending.',
          type: NotifType.alarmOverdue,
        );
      }
    }

    // ── Upcoming alarms (within 30 min) ────────────────────────
    for (final task in upcoming) {
      if (!_hasRecentNotifForTask(
        task.id,
        NotifType.alarmUpcoming,
        minutes: 25,
      )) {
        final mins = task.alarmTime!.difference(DateTime.now()).inMinutes;
        _addSmart(
          taskId: task.id,
          taskTitle: task.title,
          message:
              '⏰ "${task.title}" is due in $mins minute${mins == 1 ? '' : 's'}!',
          type: NotifType.alarmUpcoming,
        );
      }
    }

    // ── Productivity tips based on patterns ────────────────────
    _maybeAddProductivityTip(tasks, completed, total, percentage);

    _lastAnalyzedPercentage = percentage;
    _lastTaskCount = total;
  }

  // ── Productivity tips ─────────────────────────────────────────
  void _maybeAddProductivityTip(
    List<Task> tasks,
    int completed,
    int total,
    double percentage,
  ) {
    if (_hasRecentNotif(NotifType.productivityTip, minutes: 30)) return;

    final highCount = tasks
        .where((t) => t.priority == 'high' && !t.isCompleted)
        .length;
    final noAlarmCount = tasks
        .where((t) => t.alarmTime == null && !t.isCompleted)
        .length;
    final pendingCount = total - completed;

    if (highCount >= 3) {
      _addSmart(
        taskTitle: 'Productivity Tip',
        message:
            '💡 You have $highCount high-priority tasks. Consider tackling them first thing — high priority tasks get 3x more done when handled early.',
        type: NotifType.productivityTip,
      );
    } else if (noAlarmCount >= 5) {
      _addSmart(
        taskTitle: 'Productivity Tip',
        message:
            '💡 $noAlarmCount tasks have no alarm set. Adding reminders increases completion rate by up to 40%.',
        type: NotifType.productivityTip,
      );
    } else if (percentage == 0 && pendingCount >= 4) {
      _addSmart(
        taskTitle: 'Getting Started Tip',
        message:
            '💡 Start with your smallest task first — completing it builds momentum to tackle the rest.',
        type: NotifType.productivityTip,
      );
    }
  }

  // ── Idle reminder ─────────────────────────────────────────────
  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(minutes: 15), () {
      if (_lastTaskCount > 0) {
        final pending =
            _lastTaskCount - (_lastAnalyzedPercentage * _lastTaskCount).round();
        if (pending > 0) {
          _addSmart(
            taskTitle: 'Still Working?',
            message:
                '👋 You\'ve been inactive for 15 minutes. You still have $pending task${pending == 1 ? '' : 's'} pending!',
            type: NotifType.idleWarning,
          );
        }
      }
    });
  }

  // ── Track completed tasks per session ────────────────────────
  void onTaskCompleted() {
    _completedSessionCount++;
  }

  // ── Internal helpers ─────────────────────────────────────────
  void _addSmart({
    String taskId = '',
    required String taskTitle,
    required String message,
    required NotifType type,
  }) {
    _entries.add(
      NotificationEntry(
        id: '${DateTime.now().millisecondsSinceEpoch}_${_entries.length}',
        taskId: taskId,
        taskTitle: taskTitle,
        message: message,
        time: DateTime.now(),
        type: type,
        isRead: false,
      ),
    );
    notifyListeners();
  }

  bool _hasRecentNotif(NotifType type, {required int minutes}) {
    final cutoff = DateTime.now().subtract(Duration(minutes: minutes));
    return _entries.any((e) => e.type == type && e.time.isAfter(cutoff));
  }

  bool _hasRecentNotifForTask(
    String taskId,
    NotifType type, {
    required int minutes,
  }) {
    final cutoff = DateTime.now().subtract(Duration(minutes: minutes));
    return _entries.any(
      (e) => e.taskId == taskId && e.type == type && e.time.isAfter(cutoff),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ── Public controls ───────────────────────────────────────────
  void markAllRead() {
    for (final e in _entries) {
      e.isRead = true;
    }
    notifyListeners();
  }

  void markRead(String id) {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx != -1) _entries[idx].isRead = true;
    notifyListeners();
  }

  void clearAll() {
    _entries.clear();
    _lastAnalyzedPercentage = -1;
    _lastTaskCount = -1;
    _completedSessionCount = 0;
    notifyListeners();
  }

  void removeEntry(String id) {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void resetSession() {
    _completedSessionCount = 0;
    _lastAnalyzedPercentage = -1;
    _lastTaskCount = -1;
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }
}
