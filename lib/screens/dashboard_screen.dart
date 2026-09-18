import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/app_controller.dart';
import '../core/app_theme.dart';
import '../models/service_order.dart';
import 'main_navigation.dart';
import 'service_order_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  final AppController controller;

  const DashboardScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final metrics = controller.metrics;
        final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
        final userName = controller.currentUser?.name ?? 'Técnico';

        // Calculate delayed/urgent OS
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        bool isAtrasada(ServiceOrder o) {
          if (o.status == 'Concluída' || o.status == 'Cancelada') return false;
          if (o.expectedDate == null) return false;
          try {
            final p = o.expectedDate!.split('/');
            final exp = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
            return exp.isBefore(today);
          } catch (_) { return false; }
        }

        final attentionOrders = controller.orderList.where((o) {
          final atrasada = isAtrasada(o);
          final urgente = o.priority == 'Urgente' && o.status != 'Concluída' && o.status != 'Cancelada';
          final aguardando = o.status == 'Aguardando Peça';
          return atrasada || urgente || aguardando;
        }).toList();

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, userName),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.2,
                          children: [
                            _buildMiniCard('FINANCEIRO', currency.format(metrics.estimatedValue), Icons.attach_money, Colors.green),
                            _buildMiniCard('TOTAL', metrics.total.toString(), Icons.list_alt, Colors.blue),
                            _buildMiniCard('ABERTAS', metrics.count('Aberta').toString(), Icons.folder, Colors.indigo),
                            _buildMiniCard('EM ATEND.', metrics.count('Em Atendimento').toString(), Icons.manage_accounts, Colors.blue),
                            _buildMiniCard('AGUARD. PEÇAS', metrics.count('Aguardando Peça').toString(), Icons.settings, Colors.orange),
                            _buildMiniCard('CONCLUÍDAS', metrics.count('Concluída').toString(), Icons.check_circle, Colors.green),
                            _buildMiniCard('URGENTES', metrics.urgent.toString(), Icons.local_fire_department, Colors.red),
                            _buildMiniCard('ATRASADAS', metrics.overdue.toString(), Icons.schedule, Colors.orange),
                          ],
                        ),
                        if (attentionOrders.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning, color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Atenção Necessária (${attentionOrders.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  final state = context.findAncestorStateOfType<MainNavigationState>();
                                  state?.setTab(2); // Go to OS tab
                                },
                                child: const Text('Ver todas'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...attentionOrders.take(3).map((o) => _buildAttentionCard(context, o)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.build, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OS Manager',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Olá, $userName',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: controller.logout,
            icon: const Icon(Icons.logout, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.2)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(String title, String value, IconData icon, MaterialColor color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.shade50, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(title, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttentionCard(BuildContext context, ServiceOrder order) {
    final customer = controller.customerById(order.customerId);
    final tech = controller.technicianById(order.technicianId);
    final equip = controller.equipmentById(order.equipmentId);
    
    // Check if delayed
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool atrasada = false;
    int diasAtraso = 0;
    
    if (order.expectedDate != null && order.status != 'Concluída' && order.status != 'Cancelada') {
      try {
        final p = order.expectedDate!.split('/');
        final exp = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
        if (exp.isBefore(today)) {
          atrasada = true;
          diasAtraso = today.difference(exp).inDays;
        }
      } catch (_) {}
    }

    Color barColor = Colors.orange;
    String? delayText;
    
    if (atrasada) {
      barColor = Colors.red;
      delayText = 'ATRASADA HÁ $diasAtraso DIA${diasAtraso > 1 ? "S" : ""}';
    } else if (order.priority == 'Urgente') {
      barColor = Colors.red;
    } else if (order.status == 'Aguardando Peça') {
      barColor = Colors.orange;
    } else {
      barColor = Colors.blue;
    }

    Color statusColor;
    String statusText = order.status.toUpperCase();
    if (statusText == 'EM ATENDIMENTO') statusText = 'EM CURSO';

    switch (order.status) {
      case 'Aberta': statusColor = Colors.blue; break;
      case 'Atribuída': statusColor = Colors.purple; break;
      case 'Em Atendimento': statusColor = Colors.orange.shade700; break;
      case 'Aguardando Peça': statusColor = Colors.deepOrange; break;
      default: statusColor = Colors.grey.shade700;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceOrderDetailScreen(controller: controller, order: order)));
          },
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 6, color: barColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(equip != null ? '${equip.type} ${equip.brand}' : 'Equipamento N/D', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                                  const SizedBox(height: 4),
                                  Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('OS ${order.code}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade500)),
                                const SizedBox(height: 4),
                                Text(order.priority, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: order.priority == 'Urgente' ? Colors.red : (order.priority == 'Alta' ? Colors.orange.shade700 : Colors.blue))),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: Color(0xFFEEEEEE)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                if (tech != null) ...[
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.blue.shade50,
                                    child: Text(tech.name[0].toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(tech.name.split(' ').take(2).join(' '), style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 12)),
                                ] else ...[
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.grey.shade100,
                                    child: const Icon(Icons.person, size: 14, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Sem técnico', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 12)),
                                ]
                              ],
                            ),
                            Text(delayText ?? 'Prazo: ${order.expectedDate != null ? order.expectedDate!.replaceAll('-', '/') : "N/D"}', style: TextStyle(color: delayText != null ? Colors.red : Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
