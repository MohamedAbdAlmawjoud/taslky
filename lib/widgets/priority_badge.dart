import 'package:flutter/material.dart';

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});
  final String priority;
  @override
  Widget build(BuildContext context) {
    final color = priority == 'High'
        ? const Color(0xFFB94732)
        : priority == 'Low'
        ? const Color(0xFF66765C)
        : const Color(0xFF9A7341);
    return Text(
      priority,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    );
  }
}
