import 'package:flutter/foundation.dart';

import '../controllers/task_controller.dart';
import '../models/task_model.dart';
import '../services/reminder_service.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider(this.controller, {ReminderService? reminderService})
    : _reminders = reminderService ?? ReminderService();
  final TaskController controller;
  final ReminderService _reminders;
  List<TaskModel> tasks = [];
  bool loading = false;
  String? error;
  String? reminderError;
  String query = '';
  String filter = 'All';
  String? categoryFilter, priorityFilter;
  String? _uid;
  List<TaskModel> get filteredTasks => tasks.where((task) {
    final q = query.trim().toLowerCase();
    final matchesQuery =
        q.isEmpty ||
        task.title.toLowerCase().contains(q) ||
        task.description.toLowerCase().contains(q) ||
        task.category.toLowerCase().contains(q);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = task.dueDate == null
        ? null
        : DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
    final matchesFilter = switch (filter) {
      'Today' => due == today,
      'Upcoming' => due != null && due.isAfter(today) && !task.isCompleted,
      'Completed' => task.isCompleted,
      _ => true,
    };
    return matchesQuery &&
        matchesFilter &&
        (categoryFilter == null || task.category == categoryFilter) &&
        (priorityFilter == null || task.priority == priorityFilter);
  }).toList();
  Future<void> loadTasks(String uid) async {
    _uid = uid;
    loading = true;
    error = null;
    notifyListeners();
    try {
      tasks = await controller.load(uid);
      await _syncReminders();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _uid = null;
    tasks = [];
    error = null;
    loading = false;
    notifyListeners();
    _cancelReminders();
  }

  Future<void> _cancelReminders() async {
    try {
      await _reminders.cancelAll();
    } catch (e) {
      reminderError = e.toString();
      notifyListeners();
    }
  }

  Future<bool> requestReminderPermission() async {
    try {
      reminderError = null;
      final granted = await _reminders.requestPermission();
      if (!granted) {
        reminderError =
            'Allow notifications in device settings to use reminders.';
      }
      notifyListeners();
      return granted;
    } catch (e) {
      reminderError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> _syncReminders() async {
    try {
      reminderError = null;
      await _reminders.syncTasks(tasks);
    } catch (e) {
      reminderError = e.toString();
    }
  }

  Future<void> createTask(TaskModel task) async {
    final uid = _requireUid();
    error = null;
    try {
      final id = await controller.create(uid, task);
      final savedTask = task.copyWith(id: id);
      tasks = [savedTask, ...tasks];
      await _syncReminders();
      notifyListeners();
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<void> updateTask(TaskModel task) async {
    final uid = _requireUid();
    error = null;
    try {
      await controller.update(uid, task);
      tasks = tasks.map((t) => t.id == task.id ? task : t).toList();
      await _syncReminders();
      notifyListeners();
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    final uid = _requireUid();
    error = null;
    try {
      await controller.delete(uid, id);
      tasks = tasks.where((t) => t.id != id).toList();
      await _syncReminders();
      notifyListeners();
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<void> toggleTask(TaskModel task) async {
    final uid = _requireUid();
    final changed = task.copyWith(isCompleted: !task.isCompleted);
    tasks = tasks.map((t) => t.id == task.id ? changed : t).toList();
    notifyListeners();
    try {
      await controller.toggle(uid, task);
      await _syncReminders();
      notifyListeners();
    } catch (e) {
      tasks = tasks.map((t) => t.id == task.id ? task : t).toList();
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  String _requireUid() =>
      _uid ?? (throw StateError('Sign in before editing tasks.'));
  void search(String value) {
    query = value;
    notifyListeners();
  }

  void selectFilter(String value) {
    filter = value;
    notifyListeners();
  }

  void selectCategory(String? value) {
    categoryFilter = value;
    notifyListeners();
  }

  void selectPriority(String? value) {
    priorityFilter = value;
    notifyListeners();
  }
}
