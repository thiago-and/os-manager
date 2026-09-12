import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Aberta':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue;
        break;
      case 'Atribuída':
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple;
        break;
      case 'Em Atendimento':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        break;
      case 'Aguardando Peça':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange;
        break;
      case 'Concluída':
        bgColor = Colors.green.shade50;
        textColor = Colors.green;
        break;
      case 'Cancelada':
        bgColor = Colors.red.shade50;
        textColor = Colors.red;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
