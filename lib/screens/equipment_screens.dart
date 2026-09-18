import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/equipment.dart';
import 'equipment_detail_screen.dart';

class EquipmentListScreen extends StatefulWidget {
  final AppController controller;

  const EquipmentListScreen({super.key, required this.controller});

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (widget.controller.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final equipments = widget.controller.equipmentList.where((e) {
          final customer = widget.controller.customerById(e.customerId);
          final q = _searchQuery.toLowerCase();
          return e.model.toLowerCase().contains(q) ||
                 e.serialNumber.toLowerCase().contains(q) ||
                 e.patrimony.toLowerCase().contains(q) ||
                 (customer?.name.toLowerCase().contains(q) ?? false);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Equipamentos'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por cliente, modelo, série ou patrimônio...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              Expanded(
                child: equipments.isEmpty
                    ? const Center(child: Text('Nenhum equipamento encontrado.'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                        itemCount: equipments.length,
                        itemBuilder: (context, index) {
                          final equipment = equipments[index];
                          final customer = widget.controller.customerById(equipment.customerId);

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EquipmentDetailScreen(controller: widget.controller, equipment: equipment),
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${equipment.type} ${equipment.model}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                          child: Text(equipment.brand.toUpperCase(), style: TextStyle(color: Colors.grey.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            children: [
                                              _buildInfoRow(Icons.person, 'Cliente: ${customer?.name ?? "N/D"}'),
                                              const SizedBox(height: 8),
                                              _buildInfoRow(Icons.barcode_reader, 'S/N: ${equipment.serialNumber}'),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              _buildInfoRow(Icons.local_offer, 'Tipo: ${equipment.type}'),
                                              const SizedBox(height: 8),
                                              _buildInfoRow(Icons.domain, 'Pat: ${equipment.patrimony}'),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right, color: Colors.grey),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showForm(context, null),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 12), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  void _showForm(BuildContext context, Equipment? eq) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EquipmentFormScreen(controller: widget.controller, equipment: eq)),
    );
  }
}

class EquipmentFormScreen extends StatefulWidget {
  final AppController controller;
  final Equipment? equipment;
  final int? initialCustomerId;

  const EquipmentFormScreen({super.key, required this.controller, this.equipment, this.initialCustomerId});

  @override
  State<EquipmentFormScreen> createState() => _EquipmentFormScreenState();
}

class _EquipmentFormScreenState extends State<EquipmentFormScreen> {
  int? _selectedCustomerId;
  late final TextEditingController _typeController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _serialController;
  late final TextEditingController _patrimonyController;
  late final TextEditingController _obsController;

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.equipment?.customerId ?? widget.initialCustomerId;
    _typeController = TextEditingController(text: widget.equipment?.type);
    _brandController = TextEditingController(text: widget.equipment?.brand);
    _modelController = TextEditingController(text: widget.equipment?.model);
    _serialController = TextEditingController(text: widget.equipment?.serialNumber);
    _patrimonyController = TextEditingController(
      text: widget.equipment?.patrimony ?? 'PAT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'
    );
    _obsController = TextEditingController(text: widget.equipment?.observations);
  }

  void _save() async {
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um cliente.')));
      return;
    }

    final eq = Equipment(
      id: widget.equipment?.id,
      customerId: _selectedCustomerId!,
      type: _typeController.text,
      brand: _brandController.text,
      model: _modelController.text,
      serialNumber: _serialController.text,
      patrimony: _patrimonyController.text,
      observations: _obsController.text,
    );

    try {
      await widget.controller.saveEquipment(eq);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.equipment == null ? 'Novo Equipamento' : 'Editar Equipamento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('CLIENTE VINCULADO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _selectedCustomerId,
              decoration: const InputDecoration(hintText: 'Selecione o cliente'),
              items: widget.controller.customerList.map((c) {
                return DropdownMenuItem(value: c.id, child: Text(c.name));
              }).toList(),
              onChanged: (val) => setState(() => _selectedCustomerId = val),
            ),
            const SizedBox(height: 16),
            _buildField('TIPO DE EQUIPAMENTO', _typeController, 'Ex: Notebook, Impressora'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildField('MARCA', _brandController, 'Ex: Dell')),
                const SizedBox(width: 16),
                Expanded(child: _buildField('MODELO', _modelController, 'Ex: Inspiron 15')),
              ],
            ),
            const SizedBox(height: 16),
            _buildField('NÚMERO DE SÉRIE', _serialController, 'S/N'),
            const SizedBox(height: 16),
            _buildField('PATRIMÔNIO', _patrimonyController, 'Código de controle'),
            const SizedBox(height: 16),
            _buildField('OBSERVAÇÕES', _obsController, 'Detalhes adicionais...', maxLines: 4),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              child: Text(widget.equipment == null ? 'Cadastrar Equipamento' : 'Atualizar Equipamento'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
