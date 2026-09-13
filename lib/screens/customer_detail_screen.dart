import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/app_controller.dart';
import '../models/customer.dart';
import '../models/equipment.dart';
import 'customer_screens.dart';
import 'equipment_screens.dart';

class CustomerDetailScreen extends StatelessWidget {
  final AppController controller;
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.controller, required this.customer});

  void _openWhatsApp(String phone) async {
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Abrir WhatsApp para $phone')));
  }

  void _deleteCustomer(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Excluir Cliente'),
        content: const Text('Tem certeza que deseja excluir este cliente? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await controller.deleteCustomer(customer.id!);
        if (context.mounted) Navigator.pop(context);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString(), style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = customer.name.isNotEmpty 
        ? customer.name.trim().split(' ').take(2).map((e) => e[0].toUpperCase()).join() 
        : 'C';

    final customerOrders = controller.orderList.where((o) => o.customerId == customer.id).toList();
    final activeOrders = customerOrders.where((o) => o.status != 'Concluída' && o.status != 'Cancelada').toList();
    final customerEquipments = controller.equipmentList.where((e) => e.customerId == customer.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CustomerFormScreen(controller: controller, customer: customer)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteCustomer(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Theme.of(context).primaryColor,
              height: 40, // extends the blue background
            ),
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoCard(initials),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('TOTAL DE OS', customerOrders.length.toString(), Colors.black)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard('OS ATIVAS', activeOrders.length.toString(), Colors.blue)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('EQUIPAMENTOS VINCULADOS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => EquipmentFormScreen(controller: controller, initialCustomerId: customer.id)));
                          },
                          child: const Text('+ Adicionar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (customerEquipments.isEmpty)
                      const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Nenhum equipamento vinculado.')))
                    else
                      ...customerEquipments.map((e) => _buildEquipmentCard(e)),
                      
                    const SizedBox(height: 24),
                    const Text('HISTÓRICO DE ORDENS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const SizedBox(height: 12),
                    if (customerOrders.isEmpty)
                      const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Nenhuma ordem de serviço.')))
                    else
                      _buildOrdersList(customerOrders),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openWhatsApp(customer.phone),
        backgroundColor: Colors.green,
        child: const Icon(Icons.wechat), // WhatsApp-like icon
      ),
    );
  }

  Widget _buildInfoCard(String initials) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
                  child: Center(
                    child: Text(initials, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (customer.createdAt != null)
                        Text('Cliente desde ${DateFormat('MMM yyyy', 'pt_BR').format(DateTime.parse(customer.createdAt!))}', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildContactRow(Icons.phone, customer.phone),
            const SizedBox(height: 12),
            _buildContactRow(Icons.email, customer.email),
            const SizedBox(height: 12),
            _buildContactRow(Icons.badge, customer.document),
            const SizedBox(height: 12),
            _buildContactRow(Icons.location_on, customer.address),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blueGrey, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade800, fontSize: 15))),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color valueColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade400)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: valueColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentCard(Equipment equipment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
          child: Icon(equipment.type.toLowerCase().contains('notebook') ? Icons.laptop : Icons.print, color: Colors.orange),
        ),
        title: Text('${equipment.type} ${equipment.brand} ${equipment.model}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('S/N: ${equipment.serialNumber}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildOrdersList(List<dynamic> orders) {
    return Card(
      child: Column(
        children: [
          ...orders.take(3).map((order) {
            return ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('OS ${order.code}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  _buildMiniChip(order.status),
                ],
              ),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(order.openingDate))),
            );
          }),
          const Divider(height: 1),
          TextButton(
            onPressed: () {},
            child: const Text('Ver Histórico Completo'),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
