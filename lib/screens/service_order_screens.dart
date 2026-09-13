import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/app_controller.dart';
import '../models/service_order.dart';
import '../widgets/status_chip.dart';
import 'service_order_detail_screen.dart';

class ServiceOrderListScreen extends StatefulWidget {
  final AppController controller;

  const ServiceOrderListScreen({super.key, required this.controller});

  @override
  State<ServiceOrderListScreen> createState() => _ServiceOrderListScreenState();
}

class _ServiceOrderListScreenState extends State<ServiceOrderListScreen> {
  String _searchQuery = '';
  String _selectedStatus = 'Todos';
  String _selectedPriority = 'Todas';

  @override
  Widget build(BuildContext context) {
    if (widget.controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final orders = widget.controller.orderList.where((o) {
      final matchSearch = o.code.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchStatus = _selectedStatus == 'Todos' || o.status == _selectedStatus;
      final matchPriority = _selectedPriority == 'Todas' || o.priority == _selectedPriority;
      return matchSearch && matchStatus && matchPriority;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordens de Serviço'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por Nº...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            dropdownColor: Theme.of(context).primaryColor,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                            style: const TextStyle(color: Colors.white),
                            items: ['Todos', 'Aberta', 'Atribuída', 'Em Atendimento', 'Aguardando Peça', 'Concluída', 'Cancelada']
                                .map((e) => DropdownMenuItem(value: e, child: Text('Status: $e'))).toList(),
                            onChanged: (val) => setState(() => _selectedStatus = val!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPriority,
                            dropdownColor: Theme.of(context).primaryColor,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                            style: const TextStyle(color: Colors.white),
                            items: ['Todas', 'Baixa', 'Média', 'Alta', 'Urgente']
                                .map((e) => DropdownMenuItem(value: e, child: Text('Prioridade: $e'))).toList(),
                            onChanged: (val) => setState(() => _selectedPriority = val!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
      ),
      body: orders.isEmpty
          ? const Center(child: Text('Nenhuma OS encontrada.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final customer = widget.controller.customerById(order.customerId);
                final tech = widget.controller.technicianById(order.technicianId);
                final equip = widget.controller.equipmentById(order.equipmentId);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('OS ${order.code}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                            StatusChip(status: order.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(customer?.name ?? 'Cliente Desconhecido', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 16),
                        _buildRow(Icons.laptop, equip != null ? '${equip.type} ${equip.brand}' : 'Equipamento N/D'),
                        const SizedBox(height: 8),
                        _buildRow(Icons.person, tech != null ? 'Técnico: ${tech.name}' : 'Técnico: Não atribuído'),
                        const SizedBox(height: 8),
                        _buildRow(Icons.calendar_today, 'Prazo: ${order.expectedDate ?? "N/D"}'),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: order.priority == 'Urgente' ? Colors.red : (order.priority == 'Alta' ? Colors.orange : Colors.blue),
                                ),
                                const SizedBox(width: 4),
                                Text(order.priority, style: TextStyle(fontWeight: FontWeight.bold, color: order.priority == 'Urgente' ? Colors.red : Colors.grey)),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceOrderDetailScreen(controller: widget.controller, order: order)));
                              },
                              child: const Row(
                                children: [
                                  Text('Detalhes', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Icon(Icons.arrow_forward, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceOrderFormScreen(controller: widget.controller)));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.blueGrey))),
      ],
    );
  }
}

class ServiceOrderFormScreen extends StatefulWidget {
  final AppController controller;
  final ServiceOrder? order;

  const ServiceOrderFormScreen({super.key, required this.controller, this.order});

  @override
  State<ServiceOrderFormScreen> createState() => _ServiceOrderFormScreenState();
}

class _ServiceOrderFormScreenState extends State<ServiceOrderFormScreen> {
  late String _status;
  late String _priority;
  int? _selectedCustomerId;
  int? _selectedEquipmentId;
  int? _selectedTechnicianId;
  
  late final TextEditingController _descController;
  late final TextEditingController _diagController;
  late final TextEditingController _solController;
  late final TextEditingController _laborController;
  late final TextEditingController _materialController;
  
  DateTime _openingDate = DateTime.now();
  DateTime? _expectedDate;

  @override
  void initState() {
    super.initState();
    _status = widget.order?.status ?? 'Aberta';
    _priority = widget.order?.priority ?? 'Média';
    _selectedCustomerId = widget.order?.customerId;
    _selectedEquipmentId = widget.order?.equipmentId;
    _selectedTechnicianId = widget.order?.technicianId;
    
    _descController = TextEditingController(text: widget.order?.problemDescription);
    _diagController = TextEditingController(text: widget.order?.diagnosis);
    _solController = TextEditingController(text: widget.order?.solution);
    _laborController = TextEditingController(text: widget.order?.laborValue.toString() ?? '0.0');
    _materialController = TextEditingController(text: widget.order?.materialValue.toString() ?? '0.0');
    
    if (widget.order != null) {
      try { _openingDate = DateTime.parse(widget.order!.openingDate); } catch (_) {}
      if (widget.order!.expectedDate != null && widget.order!.expectedDate!.isNotEmpty) {
        try {
          final p = widget.order!.expectedDate!.split('/');
          _expectedDate = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
        } catch (_) {}
      }
    }
  }

  void _save() async {
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um cliente.')));
      return;
    }

    final format = DateFormat('dd/MM/yyyy');
    final order = ServiceOrder(
      id: widget.order?.id,
      code: widget.order?.code ?? '#${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      customerId: _selectedCustomerId!,
      equipmentId: _selectedEquipmentId,
      technicianId: _selectedTechnicianId,
      problemDescription: _descController.text,
      priority: _priority,
      status: _status,
      openingDate: _openingDate.toIso8601String(),
      expectedDate: _expectedDate != null ? format.format(_expectedDate!) : null,
      diagnosis: _diagController.text,
      solution: _solController.text,
      laborValue: double.tryParse(_laborController.text) ?? 0,
      materialValue: double.tryParse(_materialController.text) ?? 0,
    );

    try {
      await widget.controller.saveOrder(order);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.order == null ? 'Nova Ordem de Serviço' : 'Editar Ordem'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLabel('STATUS'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Aberta', 'Atribuída', 'Em Atendimento', 'Aguardando Peça', 'Concluída', 'Cancelada'].map((s) {
                final isSel = _status == s;
                return ChoiceChip(
                  label: Text(s),
                  selected: isSel,
                  onSelected: (val) { if (val) setState(() => _status = s); },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _buildLabel('PRIORIDADE'),
            Wrap(
              spacing: 8,
              children: ['Baixa', 'Média', 'Alta', 'Urgente'].map((p) {
                return ChoiceChip(
                  label: Text(p),
                  selected: _priority == p,
                  onSelected: (val) { if (val) setState(() => _priority = p); },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _buildLabel('CLIENTE'),
            DropdownButtonFormField<int>(
              value: _selectedCustomerId,
              decoration: const InputDecoration(hintText: 'Selecione o cliente'),
              items: widget.controller.customerList.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCustomerId = val;
                  _selectedEquipmentId = null; // reset equipment
                });
              },
            ),
            const SizedBox(height: 16),
            _buildLabel('EQUIPAMENTO'),
            DropdownButtonFormField<int>(
              value: _selectedEquipmentId,
              decoration: const InputDecoration(hintText: 'Selecione o equipamento'),
              items: widget.controller.equipmentList.where((e) => e.customerId == _selectedCustomerId).map((e) {
                return DropdownMenuItem(value: e.id, child: Text('${e.type} ${e.brand} ${e.model}'));
              }).toList(),
              onChanged: (val) => setState(() => _selectedEquipmentId = val),
            ),
            const SizedBox(height: 16),
            _buildLabel('TÉCNICO RESPONSÁVEL'),
            DropdownButtonFormField<int>(
              value: _selectedTechnicianId,
              decoration: const InputDecoration(hintText: 'Selecione um técnico'),
              items: widget.controller.technicianList.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
              onChanged: (val) => setState(() => _selectedTechnicianId = val),
            ),
            const SizedBox(height: 16),
            _buildLabel('DESCRIÇÃO DO PROBLEMA'),
            TextField(controller: _descController, maxLines: 4, decoration: const InputDecoration(hintText: 'Relato do cliente...')),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('DATA INÍCIO'),
                      InkWell(
                        onTap: () async {
                          final d = await showDatePicker(context: context, initialDate: _openingDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (d != null) setState(() => _openingDate = d);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(),
                          child: Text(DateFormat('dd/MM/yyyy').format(_openingDate)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('PREVISÃO'),
                      InkWell(
                        onTap: () async {
                          final d = await showDatePicker(context: context, initialDate: _expectedDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (d != null) setState(() => _expectedDate = d);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(),
                          child: Text(_expectedDate != null ? DateFormat('dd/MM/yyyy').format(_expectedDate!) : 'Selecionar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel('DIAGNÓSTICO'),
            TextField(controller: _diagController, maxLines: 3, decoration: const InputDecoration(hintText: 'O que foi identificado?')),
            const SizedBox(height: 16),
            _buildLabel('SOLUÇÃO APLICADA'),
            TextField(controller: _solController, maxLines: 3, decoration: const InputDecoration(hintText: 'O que foi feito?')),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildLabel('MÃO DE OBRA (R\$)'),
                  TextField(controller: _laborController, keyboardType: TextInputType.number),
                ])),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildLabel('PEÇAS (R\$)'),
                  TextField(controller: _materialController, keyboardType: TextInputType.number),
                ])),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              child: Text(widget.order == null ? 'Gerar Ordem de Serviço' : 'Salvar Alterações'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }
}
