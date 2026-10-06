import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'Personal',
    this.priority = 'Medium',
    this.isCompleted = false,
    this.dueDate,
    this.dueTime,
    this.reminder = false,
    this.createdAt,
    this.updatedAt,
  });
  final String id, title, description, category, priority;
  final bool isCompleted, reminder;
  final DateTime? dueDate, createdAt, updatedAt;
  final String? dueTime;
  factory TaskModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    DateTime? date(Object? x) => x is Timestamp ? x.toDate() : null;
    return TaskModel(
      id: doc.id,
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      category: d['category'] as String? ?? 'Personal',
      priority: d['priority'] as String? ?? 'Medium',
      isCompleted: d['isCompleted'] as bool? ?? false,
      dueDate: date(d['dueDate']),
      dueTime: d['dueTime'] as String?,
      reminder: d['reminder'] as bool? ?? false,
      createdAt: date(d['createdAt']),
      updatedAt: date(d['updatedAt']),
    );
  }
  Map<String, dynamic> toFirestore({bool includeCreated = false}) => {
    'title': title.trim(),
    'description': description.trim(),
    'category': category,
    'priority': priority,
    'isCompleted': isCompleted,
    'dueDate': dueDate == null ? null : Timestamp.fromDate(dueDate!),
    'dueTime': dueTime,
    'reminder': reminder,
    'updatedAt': FieldValue.serverTimestamp(),
    if (includeCreated) 'createdAt': FieldValue.serverTimestamp(),
  };
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? priority,
    bool? isCompleted,
    DateTime? dueDate,
    String? dueTime,
    bool? reminder,
  }) => TaskModel(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    category: category ?? this.category,
    priority: priority ?? this.priority,
    isCompleted: isCompleted ?? this.isCompleted,
    dueDate: dueDate ?? this.dueDate,
    dueTime: dueTime ?? this.dueTime,
    reminder: reminder ?? this.reminder,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
