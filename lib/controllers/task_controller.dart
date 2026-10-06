import '../models/task_model.dart';
import '../services/task_service.dart';

class TaskController {
  TaskController(this.service);
  final TaskService service;
  Future<List<TaskModel>> load(String uid) => service.getTasks(uid);
  Future<String> create(String uid, TaskModel task) =>
      service.addTask(uid, task);
  Future<void> update(String uid, TaskModel task) =>
      service.updateTask(uid, task);
  Future<void> delete(String uid, String id) => service.deleteTask(uid, id);
  Future<void> toggle(String uid, TaskModel task) =>
      service.toggleTask(uid, task);
}
