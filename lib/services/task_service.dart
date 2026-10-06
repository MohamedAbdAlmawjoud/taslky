import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task_model.dart';

class TaskService {
  TaskService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> _tasks(String uid) =>
      _db.collection('users').doc(uid).collection('tasks');
  Future<List<TaskModel>> getTasks(String uid) async =>
      (await _tasks(uid).orderBy('createdAt', descending: true).get()).docs
          .map(TaskModel.fromFirestore)
          .toList();
  Future<String> addTask(String uid, TaskModel task) async {
    final ref = _tasks(uid).doc();
    await ref.set(task.toFirestore(includeCreated: true));
    return ref.id;
  }

  Future<void> updateTask(String uid, TaskModel task) =>
      _tasks(uid).doc(task.id).update(task.toFirestore());
  Future<void> deleteTask(String uid, String id) =>
      _tasks(uid).doc(id).delete();
  Future<void> toggleTask(String uid, TaskModel task) => _tasks(uid)
      .doc(task.id)
      .update({
        'isCompleted': !task.isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
