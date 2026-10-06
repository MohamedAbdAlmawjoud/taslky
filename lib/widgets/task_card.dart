import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/task_model.dart';
import 'priority_badge.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
  });
  final TaskModel task;
  final VoidCallback onTap, onToggle;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          IconButton(
            onPressed: onToggle,
            icon: Icon(
              task.isCompleted
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: task.isCompleted ? AppColors.accent : AppColors.secondary,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${task.category}  ·  ${task.dueTime ?? 'No time'}',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          PriorityBadge(priority: task.priority),
          const SizedBox(width: 8),
        ],
      ),
    ),
  );
}
