import 'package:flutter/material.dart';

import 'app_views.dart';

class TaskDetailsView extends StatelessWidget {
  const TaskDetailsView({super.key, required this.taskId});
  final String taskId;
  @override
  Widget build(BuildContext context) => TaskDetailPage(id: taskId);
}
