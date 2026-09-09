import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/app_controller.dart';
import '../models/service_order.dart';
import '../services/image_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_chip.dart';

class ServiceOrderListScreen extends StatelessWidget {
  final AppController controller;

  const ServiceOrderListScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Ordens de serviço')),
        body: controller.orderList.isEmpty
            ? const EmptyState(icon: Icons.assignment_outlined, message: 'Nenhuma ordem de serviço cadastrada')
            : ListView.separated(
                padding: const EdgeInsets.all(12), itemCount: controller.orderList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final order = controller.orderList[index];
                  final customer = controller.customerById(order.customerId);
                  return Card(child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceOrderDetailScreen(controller: controller, order: order))),
                    child: Padding(padding: const EdgeInsets.all(13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Expanded(child: Text(order.code, style: const TextStyle(color: Color(0xFF1769C2), fontWeight: FontWeight.bold))), StatusChip.status(status: order.status)]),
                      const SizedBox(height: 8), Text('Cliente: ${customer?.name ?? 'Não encontrado'}'), const SizedBox(height: 3), Text('Equipamento: ${order.equipment}', style: const TextStyle(fontSize: 12, color: Color(0xFF65758B))),
                      const SizedBox(height: 9), Row(children: [StatusChip.priority(priority: order.priority), const Spacer(), const Icon(Icons.chevron_right, color: Color(0xFF9AA7B8))]),
                    ])),
                  ));
                },
              ),
        floatingActionButton: FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceOrderFormScreen(controller: controller))), icon: const Icon(Icons.add), label: const Text('Nova OS')),
      );
}

class ServiceOrderFormScreen extends StatefulWidget {
  final AppController controller;
  final ServiceOrder? order;

  const ServiceOrderFormScreen({super.key, required this.controller, this.order});

  @override
  State<ServiceOrderFormScreen> createState() => _ServiceOrderFormScreenState();
}

class _ServiceOrderFormScreenState extends State<ServiceOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _images = ImageService();
  late final TextEditingController _code;
  late final TextEditingController _equipment;
  late final TextEditingController _problem;
  late final TextEditingController _diagnosis;
  late final TextEditingController _solution;
  late final TextEditingController _labor;
  late final TextEditingController _materials;
  int? _customerId;
  int? _technicianId;
  late Priority _priority;
  late ServiceStatus _status;
  late DateTime _openingDate;
  DateTime? _expectedDate;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    final order = widget.order;
    _code = TextEditingController(text: order?.code ?? '#OS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    _equipment = TextEditingController(text: order?.equipment ?? '');
    _problem = TextEditingController(text: order?.problemDescription ?? '');
    _diagnosis = TextEditingController(text: order?.diagnosis ?? '');
    _solution = TextEditingController(text: order?.solution ?? '');
    _labor = TextEditingController(text: order?.laborValue.toStringAsFixed(2) ?? '0,00');
    _materials = TextEditingController(text: order?.materialValue.toStringAsFixed(2) ?? '0,00');
    _customerId = order?.customerId;
    _technicianId = order?.technicianId;
    _priority = order?.priority ?? Priority.medium;
    _status = order?.status ?? ServiceStatus.open;
    _openingDate = order?.openingDate ?? DateTime.now();
    _expectedDate = order?.expectedDate;
    _imagePath = order?.imagePath;
  }

  @override
  void dispose() { _code.dispose(); _equipment.dispose(); _problem.dispose(); _diagnosis.dispose(); _solution.dispose(); _labor.dispose(); _materials.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<String>(context: context, builder: (sheetContext) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Câmera'), onTap: () => Navigator.pop(sheetContext, 'camera')),
      ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Galeria'), onTap: () => Navigator.pop(sheetContext, 'gallery')),
      ListTile(leading: const Icon(Icons.attach_file_outlined), title: const Text('Selecionar arquivo'), onTap: () => Navigator.pop(sheetContext, 'file')),
    ])));
    final path = switch (source) { 'camera' => await _images.fromCamera(), 'gallery' => await _images.fromGallery(), 'file' => await _images.fromFile(), _ => null };
    if (path != null && mounted) setState(() => _imagePath = path);
  }

  Future<void> _selectDate(bool opening) async {
    final selected = await showDatePicker(context: context, initialDate: opening ? _openingDate : (_expectedDate ?? _openingDate), firstDate: DateTime(2020), lastDate: DateTime(2035));
    if (selected != null) setState(() { if (opening) { _openingDate = selected; } else { _expectedDate = selected; } });
  }

  double _number(String value) => double.tryParse(value.replaceAll('.', '').replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || _customerId == null) {
      if (_customerId == null) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um cliente')));
      return;
    }
    await widget.controller.saveOrder(ServiceOrder(
      id: widget.order?.id, code: _code.text.trim(), customerId: _customerId!, technicianId: _technicianId, equipment: _equipment.text.trim(), problemDescription: _problem.text.trim(), imagePath: _imagePath, priority: _priority, status: _status, openingDate: _openingDate, expectedDate: _expectedDate, diagnosis: _diagnosis.text.trim(), solution: _solution.text.trim(), laborValue: _number(_labor.text), materialValue: _number(_materials.text),
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Scaffold(
      appBar: AppBar(title: Text(widget.order == null ? 'Nova ordem de serviço' : 'Editar ordem de serviço')),
      body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
        _field(_code, 'Número / Código'),
        DropdownButtonFormField<int>(initialValue: _customerId, decoration: const InputDecoration(labelText: 'Cliente'), items: widget.controller.customerList.map((customer) => DropdownMenuItem(value: customer.id, child: Text(customer.name, overflow: TextOverflow.ellipsis))).toList(), onChanged: (value) => setState(() => _customerId = value), validator: (value) => value == null ? 'Selecione um cliente' : null),
        const SizedBox(height: 15), _field(_equipment, 'Equipamento'), _field(_problem, 'Descrição do problema', maxLines: 3),
        OutlinedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.add_a_photo_outlined), label: Text(_imagePath == null ? 'Anexar imagem' : 'Imagem anexada')),
        const SizedBox(height: 15),
        DropdownButtonFormField<Priority>(initialValue: _priority, decoration: const InputDecoration(labelText: 'Prioridade'), items: Priority.values.map((value) => DropdownMenuItem(value: value, child: Text(value.label))).toList(), onChanged: (value) => setState(() => _priority = value!)),
        const SizedBox(height: 15),
        DropdownButtonFormField<int?>(initialValue: _technicianId, decoration: const InputDecoration(labelText: 'Técnico responsável'), items: [const DropdownMenuItem<int?>(value: null, child: Text('Não atribuído')), ...widget.controller.technicianList.map((technician) => DropdownMenuItem<int?>(value: technician.id, child: Text(technician.name)))], onChanged: (value) => setState(() => _technicianId = value)),
        const SizedBox(height: 15),
        Row(children: [Expanded(child: _dateButton('Data de abertura', dateFormat.format(_openingDate), () => _selectDate(true))), const SizedBox(width: 12), Expanded(child: _dateButton('Previsão de conclusão', _expectedDate == null ? 'Selecionar' : dateFormat.format(_expectedDate!), () => _selectDate(false)))]),
        const SizedBox(height: 15),
        DropdownButtonFormField<ServiceStatus>(initialValue: _status, decoration: const InputDecoration(labelText: 'Status'), items: ServiceStatus.values.map((value) => DropdownMenuItem(value: value, child: Text(value.label))).toList(), onChanged: (value) => setState(() => _status = value!)),
        const SizedBox(height: 15), _field(_diagnosis, 'Diagnóstico técnico', maxLines: 3, required: false), _field(_solution, 'Solução aplicada', maxLines: 3, required: false),
        Row(children: [Expanded(child: _field(_labor, 'Mão de obra (R\$)', keyboardType: TextInputType.number)), const SizedBox(width: 12), Expanded(child: _field(_materials, 'Peças/materiais (R\$)', keyboardType: TextInputType.number))]),
      ])),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: FilledButton(onPressed: _save, child: const Text('Salvar')))),
    );
  }

  Widget _field(TextEditingController controller, String label, {int maxLines = 1, TextInputType? keyboardType, bool required = true}) => Padding(padding: const EdgeInsets.only(bottom: 15), child: TextFormField(controller: controller, maxLines: maxLines, keyboardType: keyboardType, decoration: InputDecoration(labelText: label), validator: (value) => required && (value == null || value.trim().isEmpty) ? 'Campo obrigatório' : null));
  Widget _dateButton(String label, String date, VoidCallback onTap) => OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 12), alignment: Alignment.centerLeft), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10)), const SizedBox(height: 3), Text(date, overflow: TextOverflow.ellipsis)]));
}

class ServiceOrderDetailScreen extends StatelessWidget {
  final AppController controller;
  final ServiceOrder order;

  const ServiceOrderDetailScreen({super.key, required this.controller, required this.order});

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Excluir ordem de serviço?'), content: const Text('Esta ação não poderá ser desfeita.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Excluir'))]));
    if (confirmed == true) { await controller.deleteOrder(order.id!); if (context.mounted) Navigator.pop(context); }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final date = DateFormat('dd/MM/yyyy');
    final customer = controller.customerById(order.customerId);
    final technician = controller.technicianById(order.technicianId);
    return Scaffold(
      appBar: AppBar(title: Text(order.code), actions: [IconButton(onPressed: () => _delete(context), icon: const Icon(Icons.delete_outline))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [StatusChip.status(status: order.status), const SizedBox(width: 8), StatusChip.priority(priority: order.priority)]), const SizedBox(height: 15),
        _section('Informações do cliente', [_line('Nome', customer?.name ?? 'Não encontrado'), _line('Telefone', customer?.phone ?? '')]),
        _section('Equipamento e problema', [_line('Equipamento', order.equipment), _line('Problema', order.problemDescription)]),
        if (order.imagePath != null && File(order.imagePath!).existsSync()) Card(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(order.imagePath!), height: 190, width: double.infinity, fit: BoxFit.cover))),
        _section('Atendimento', [_line('Técnico', technician?.name ?? 'Não atribuído'), _line('Abertura', date.format(order.openingDate)), _line('Previsão', order.expectedDate == null ? 'Não informada' : date.format(order.expectedDate!))]),
        _section('Diagnóstico e solução', [_line('Diagnóstico', order.diagnosis.isEmpty ? 'Não informado' : order.diagnosis), _line('Solução', order.solution.isEmpty ? 'Não informada' : order.solution)]),
        _section('Valores', [_line('Mão de obra', currency.format(order.laborValue)), _line('Peças / materiais', currency.format(order.materialValue)), _line('Valor total', currency.format(order.totalValue))]),
      ]),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceOrderFormScreen(controller: controller, order: order))), icon: const Icon(Icons.edit_outlined), label: const Text('Editar')))),
    );
  }

  Widget _section(String title, List<Widget> children) => Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF55708F))), const SizedBox(height: 12), ...children])));
  Widget _line(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6C7A90))), const SizedBox(height: 2), Text(value)]));
}
