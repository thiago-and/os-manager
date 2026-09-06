import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: const Color(0xFF9AA7B8)),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: Color(0xFF65758B))),
          ],
        ),
      );
}
