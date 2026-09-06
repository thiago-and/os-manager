import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/technician.dart';
import '../widgets/empty_state.dart';

class TechnicianListScreen extends StatelessWidget {
  final AppController controller;

  const TechnicianListScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Técnicos')),
        body: controller.technicianList.isEmpty
            ? const EmptyState(icon: Icons.engineering_outlined, message: 'Nenhum técnico cadastrado')
            : ListView.separated(
                padding: const EdgeInsets.all(12), itemCount: controller.technicianList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 7),
                itemBuilder: (context, index) {
                  final technician = controller.technicianList[index];
                  return Card(child: ListTile(
                    leading: CircleAvatar(backgroundColor: technician.isActive ? const Color(0xFFDDF5EA) : const Color(0xFFF1F3F5), child: Icon(Icons.engineering_outlined, color: technician.isActive ? Colors.teal : Colors.grey)),
                    title: Text(technician.name, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(technician.specialty), trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TechnicianDetailScreen(controller: controller, technician: technician))),
                  ));
                },
              ),
        floatingActionButton: FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TechnicianFormScreen(controller: controller))), icon: const Icon(Icons.person_add_alt_1_outlined), label: const Text('Cadastrar')),
      );
}

class TechnicianFormScreen extends StatefulWidget {
  final AppController controller;
  final Technician? technician;

  const TechnicianFormScreen({super.key, required this.controller, this.technician});

  @override
  State<TechnicianFormScreen> createState() => _TechnicianFormScreenState();
}

class _TechnicianFormScreenState extends State<TechnicianFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _contact;
  late final TextEditingController _specialty;
  late bool _active;

  @override
  void initState() {
    super.initState();
    final technician = widget.technician;
    _name = TextEditingController(text: technician?.name ?? '');
    _contact = TextEditingController(text: technician?.contact ?? '');
    _specialty = TextEditingController(text: technician?.specialty ?? '');
    _active = technician?.isActive ?? true;
  }

  @override
  void dispose() { _name.dispose(); _contact.dispose(); _specialty.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.controller.saveTechnician(Technician(id: widget.technician?.id, name: _name.text.trim(), contact: _contact.text.trim(), specialty: _specialty.text.trim(), isActive: _active));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.technician == null ? 'Cadastrar técnico' : 'Editar técnico')),
        body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
          _field(_name, 'Nome completo'), _field(_contact, 'Telefone / contato', keyboardType: TextInputType.phone), _field(_specialty, 'Especialidade'),
          const Text('Situação', style: TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 5),
          SegmentedButton<bool>(segments: const [ButtonSegment(value: true, label: Text('Ativo')), ButtonSegment(value: false, label: Text('Inativo'))], selected: {_active}, onSelectionChanged: (value) => setState(() => _active = value.first)),
        ])),
        bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: FilledButton(onPressed: _save, child: const Text('Salvar')))),
      );

  Widget _field(TextEditingController controller, String label, {TextInputType? keyboardType}) => Padding(padding: const EdgeInsets.only(bottom: 15), child: TextFormField(controller: controller, keyboardType: keyboardType, decoration: InputDecoration(labelText: label), validator: (value) => value == null || value.trim().isEmpty ? 'Campo obrigatório' : null));
}

class TechnicianDetailScreen extends StatelessWidget {
  final AppController controller;
  final Technician technician;

  const TechnicianDetailScreen({super.key, required this.controller, required this.technician});

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Excluir técnico?'), content: const Text('Esta ação não poderá ser desfeita.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Excluir'))]));
    if (confirmed == true) { await controller.deleteTechnician(technician.id!); if (context.mounted) Navigator.pop(context); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Detalhes do técnico'), actions: [IconButton(onPressed: () => _delete(context), icon: const Icon(Icons.delete_outline))]),
        body: ListView(padding: const EdgeInsets.all(16), children: [Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.engineering_outlined, size: 44, color: Color(0xFF1769C2)), const SizedBox(height: 10), Text(technician.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const Divider(height: 28),
          _row('Contato', technician.contact), _row('Especialidade', technician.specialty), _row('Situação', technician.isActive ? 'Ativo' : 'Inativo'),
        ])))],
        ),
        bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TechnicianFormScreen(controller: controller, technician: technician))), icon: const Icon(Icons.edit_outlined), label: const Text('Editar')))),
      );

  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6C7A90))), const SizedBox(height: 3), Text(value)]));
}
