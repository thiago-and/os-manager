import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: color.withValues(alpha: .14),
                    child: Icon(icon, size: 17, color: color),
                  ),
                ),
                const Spacer(),
                Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF6C7A90))),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );
}
