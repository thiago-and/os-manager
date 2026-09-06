import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/app_controller.dart';
import '../models/service_order.dart';
import '../widgets/metric_card.dart';

class DashboardScreen extends StatelessWidget {
  final AppController controller;
  final VoidCallback showOrders;
  final VoidCallback logout;

  const DashboardScreen({super.key, required this.controller, required this.showOrders, required this.logout});

  @override
  Widget build(BuildContext context) {
    final metrics = controller.metrics;
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final items = [
      ('Total de OS', '${metrics.total}', Icons.description_outlined, Colors.blue),
      ('Abertas', '${metrics.count(ServiceStatus.open)}', Icons.lock_open_outlined, Colors.green),
      ('Em atendimento', '${metrics.count(ServiceStatus.inProgress)}', Icons.bolt_outlined, Colors.orange),
      ('Aguardando peça', '${metrics.count(ServiceStatus.waitingPart)}', Icons.inventory_2_outlined, Colors.amber.shade800),
      ('Concluídas', '${metrics.count(ServiceStatus.completed)}', Icons.task_alt_outlined, Colors.teal),
      ('Urgentes', '${metrics.urgent}', Icons.warning_amber_rounded, Colors.red),
      ('Atrasadas', '${metrics.overdue}', Icons.timer_outlined, Colors.red.shade400),
      ('Valor estimado', currency.format(metrics.estimatedValue), Icons.attach_money_rounded, Colors.purple),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Olá, ${controller.currentUser}'),
          const Text('Técnico de Campo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal)),
        ]),
        actions: [IconButton(onPressed: logout, icon: const Icon(Icons.logout_outlined), tooltip: 'Sair')],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Suas estatísticas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.25),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return MetricCard(title: item.$1, value: item.$2, icon: item.$3, color: item.$4, onTap: showOrders);
              },
            ),
          ),
        ]),
      ),
    );
  }
}
