import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/app_controller.dart';
import '../models/equipment.dart';
import '../models/service_order.dart';
import 'equipment_screens.dart';
import 'service_order_detail_screen.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final AppController controller;
  final Equipment equipment;

  const EquipmentDetailScreen({super.key, required this.controller, required this.equipment});

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  void _edit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EquipmentFormScreen(controller: widget.controller, equipment: widget.equipment),
      ),
    );
  }

  void _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Excluir Equipamento'),
        content: const Text('Deseja excluir este equipamento?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.controller.deleteEquipment(widget.equipment.id!);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final currentEq = widget.controller.equipmentList.firstWhere(
          (e) => e.id == widget.equipment.id,
          orElse: () => widget.equipment,
        );

        final customer = widget.controller.customerById(currentEq.customerId);
        
        // Orders for this equipment
        final orders = widget.controller.orderList.where((o) => o.equipmentId == currentEq.id).toList();
        orders.sort((a, b) => b.openingDate.compareTo(a.openingDate));

        return Scaffold(
          appBar: AppBar(
            title: Text('${currentEq.type} ${currentEq.brand}'),
            actions: [
              IconButton(icon: const Icon(Icons.edit_square), onPressed: _edit),
              IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          _getIconForType(currentEq.type),
                          size: 64,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${currentEq.type} ${currentEq.model}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'S/N: ${currentEq.serialNumber}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('ESPECIFICAÇÕES TÉCNICAS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _buildSpecItem('MARCA', currentEq.brand)),
                                  Expanded(child: _buildSpecItem('MODELO', currentEq.model)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: _buildSpecItem('TIPO', currentEq.type)),
                                  Expanded(child: _buildSpecItem('PATRIMÔNIO', currentEq.patrimony)),
                                ],
                              ),
                              if (currentEq.observations.isNotEmpty) ...[
                                const Divider(height: 32),
                                const Text('NOTAS / OBSERVAÇÕES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(currentEq.observations, style: TextStyle(color: Colors.grey.shade800, fontStyle: FontStyle.italic)),
                              ]
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('PROPRIETÁRIO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      const SizedBox(height: 8),
                      if (customer != null)
                        Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              child: Text(customer.name[0].toUpperCase(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(customer.phone),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {}, // Navigate to customer if needed
                          ),
                        ),
                      const SizedBox(height: 24),
                      const Text('HISTÓRICO DE ORDENS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      const SizedBox(height: 8),
                      if (orders.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Nenhuma ordem de serviço vinculada a este equipamento.'),
                        )
                      else
                        Card(
                          child: Column(
                            children: orders.map((o) => _buildOrderRow(context, o)).toList(),
                          ),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildOrderRow(BuildContext context, ServiceOrder order) {
    final date = DateTime.parse(order.openingDate);
    final isLast = order == widget.controller.orderList.where((o) => o.equipmentId == widget.equipment.id).lastOrNull;
    final total = order.laborValue + order.materialValue;

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceOrderDetailScreen(controller: widget.controller, order: order)));
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('OS ${order.code}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: order.status == 'Concluída' ? Colors.green.shade50 : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              order.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: order.status == 'Concluída' ? Colors.green : Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Motivo: ${order.problemDescription}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('Data: ${DateFormat('dd/MM/yyyy').format(date)}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                Text(
                  _currencyFormat.format(total),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ),
          ),
          if (!isLast) const Divider(height: 1),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    type = type.toLowerCase();
    if (type.contains('notebook') || type.contains('laptop')) return Icons.laptop_mac;
    if (type.contains('pc') || type.contains('computador') || type.contains('desktop')) return Icons.desktop_windows;
    if (type.contains('impresso') || type.contains('print')) return Icons.print;
    if (type.contains('celular') || type.contains('smartphone') || type.contains('telefone')) return Icons.smartphone;
    if (type.contains('tablet')) return Icons.tablet_mac;
    return Icons.devices;
  }
}
