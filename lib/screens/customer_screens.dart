import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/customer.dart';
import '../widgets/empty_state.dart';

class CustomerListScreen extends StatelessWidget {
  final AppController controller;

  const CustomerListScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Clientes')),
        body: controller.customerList.isEmpty
            ? const EmptyState(icon: Icons.people_outline, message: 'Nenhum cliente cadastrado')
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: controller.customerList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 7),
                itemBuilder: (context, index) {
                  final customer = controller.customerList[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                      title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(customer.phone),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDetailScreen(controller: controller, customer: customer))),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerFormScreen(controller: controller))),
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Cadastrar'),
        ),
      );
}

class CustomerFormScreen extends StatefulWidget {
  final AppController controller;
  final Customer? customer;

  const CustomerFormScreen({super.key, required this.controller, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _document;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    _name = TextEditingController(text: customer?.name ?? '');
    _document = TextEditingController(text: customer?.document ?? '');
    _phone = TextEditingController(text: customer?.phone ?? '');
    _email = TextEditingController(text: customer?.email ?? '');
    _address = TextEditingController(text: customer?.address ?? '');
  }

  @override
  void dispose() {
    _name.dispose(); _document.dispose(); _phone.dispose(); _email.dispose(); _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.controller.saveCustomer(Customer(
      id: widget.customer?.id, name: _name.text.trim(), document: _document.text.trim(), phone: _phone.text.trim(), email: _email.text.trim(), address: _address.text.trim(),
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.customer == null ? 'Cadastrar cliente' : 'Editar cliente')),
        body: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            _field(_name, 'Nome completo / Razão social'),
            _field(_document, 'CPF/CNPJ ou identificação'),
            _field(_phone, 'Telefone', keyboardType: TextInputType.phone),
            _field(_email, 'E-mail', keyboardType: TextInputType.emailAddress, required: false),
            _field(_address, 'Endereço', maxLines: 3),
          ]),
        ),
        bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: FilledButton(onPressed: _save, child: const Text('Salvar')))),
      );

  Widget _field(TextEditingController controller, String label, {TextInputType? keyboardType, int maxLines = 1, bool required = true}) => Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: TextFormField(
          controller: controller, keyboardType: keyboardType, maxLines: maxLines,
          decoration: InputDecoration(labelText: label),
          validator: (value) => required && (value == null || value.trim().isEmpty) ? 'Campo obrigatório' : null,
        ),
      );
}

class CustomerDetailScreen extends StatelessWidget {
  final AppController controller;
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.controller, required this.customer});

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Excluir cliente?'), content: const Text('Esta ação não poderá ser desfeita.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Excluir'))],
    ));
    if (confirmed == true) {
      await controller.deleteCustomer(customer.id!);
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Detalhes do cliente'), actions: [IconButton(onPressed: () => _delete(context), icon: const Icon(Icons.delete_outline))]),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.person_outline, size: 44, color: Color(0xFF1769C2)), const SizedBox(height: 10),
            Text(customer.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const Divider(height: 28),
            _row('CPF/CNPJ', customer.document), _row('Telefone', customer.phone), _row('E-mail', customer.email), _row('Endereço', customer.address),
          ]))),
        ]),
        bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: FilledButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerFormScreen(controller: controller, customer: customer))), icon: const Icon(Icons.edit_outlined), label: const Text('Editar'),
        ))),
      );

  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6C7A90))), const SizedBox(height: 3), Text(value)]));
}
