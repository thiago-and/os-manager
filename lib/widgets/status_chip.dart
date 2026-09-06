import 'package:flutter/material.dart';

import '../models/service_order.dart';

class StatusChip extends StatelessWidget {
  final ServiceStatus status;
  final Priority? priority;

  const StatusChip.status({super.key, required this.status}) : priority = null;
  const StatusChip.priority({super.key, required this.priority}) : status = ServiceStatus.open;

  Color get _color {
    if (priority != null) {
      return switch (priority!) {
        Priority.low => Colors.blue,
        Priority.medium => Colors.orange,
        Priority.high => Colors.deepOrange,
        Priority.urgent => Colors.red,
      };
    }
    return switch (status) {
      ServiceStatus.open => Colors.blue,
      ServiceStatus.assigned => Colors.indigo,
      ServiceStatus.inProgress => Colors.orange,
      ServiceStatus.waitingPart => Colors.amber.shade800,
      ServiceStatus.completed => Colors.teal,
      ServiceStatus.canceled => Colors.red,
    };
  }

  @override
  Widget build(BuildContext context) {
    final text = priority?.label ?? status.label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: _color.withValues(alpha: .12), borderRadius: BorderRadius.circular(7)),
      child: Text(text, style: TextStyle(fontSize: 10, color: _color, fontWeight: FontWeight.w700)),
    );
  }
}
