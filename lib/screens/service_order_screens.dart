import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

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
      final customer = widget.controller.customerById(o.customerId);
      final equip = widget.controller.equipmentById(o.equipmentId);
      final tech = widget.controller.technicianById(o.technicianId);

      final q = _searchQuery.toLowerCase();
      final matchSearch = o.code.toLowerCase().contains(q) ||
                          (customer?.name.toLowerCase().contains(q) ?? false) ||
                          (equip?.model.toLowerCase().contains(q) ?? false) ||
                          (equip?.type.toLowerCase().contains(q) ?? false) ||
                          (tech?.name.toLowerCase().contains(q) ?? false);

      final matchStatus = _selectedStatus == 'Todos' || o.status == _selectedStatus;
      final matchPriority = _selectedPriority == 'Todas' || o.priority == _selectedPriority;
      return matchSearch && matchStatus && matchPriority;
    }).toList();

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

    orders.sort((a, b) {
      final aAtrasada = isAtrasada(a);
      final bAtrasada = isAtrasada(b);
      if (aAtrasada && !bAtrasada) return -1;
      if (!aAtrasada && bAtrasada) return 1;

      int prioValue(String p) {
        if (p == 'Urgente') return 4;
        if (p == 'Alta') return 3;
        if (p == 'Média') return 2;
        if (p == 'Baixa') return 1;
        return 0;
      }
      
      final aPrio = prioValue(a.priority);
      final bPrio = prioValue(b.priority);
      if (aPrio != bPrio) return bPrio.compareTo(aPrio);

      DateTime? parseExpected(String? d) {
        if (d == null) return null;
        try {
          final p = d.split('/');
          return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
        } catch (_) { return null; }
      }

      final aExp = parseExpected(a.expectedDate);
      final bExp = parseExpected(b.expectedDate);

      if (aExp != null && bExp != null) return aExp.compareTo(bExp);
      if (aExp != null && bExp == null) return -1;
      if (aExp == null && bExp != null) return 1;

      return b.openingDate.compareTo(a.openingDate);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordens de Serviço'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Nº, Cliente, Equip., Técnico...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedStatus,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blueGrey),
                            style: const TextStyle(color: Colors.black87),
                            items: ['Todos', 'Aberta', 'Atribuída', 'Em Atendimento', 'Aguardando Peça', 'Concluída', 'Cancelada']
                                .map((e) => DropdownMenuItem(value: e, child: Text('Status: $e', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
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
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedPriority,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blueGrey),
                            style: const TextStyle(color: Colors.black87),
                            items: ['Todas', 'Baixa', 'Média', 'Alta', 'Urgente']
                                .map((e) => DropdownMenuItem(value: e, child: Text('Prioridade: $e', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
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
          Expanded(
            child: orders.isEmpty
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
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceOrderDetailScreen(controller: widget.controller, order: order)));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('OS ${order.code}', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 12)),
                              const SizedBox(width: 8),
                              if (order.status != 'Concluída' && order.status != 'Cancelada')
                                StatusChip(status: order.status),
                              const Spacer(),
                              if (order.status == 'Concluída' || order.status == 'Cancelada')
                                StatusChip(status: order.status)
                              else
                                Row(
                                  children: [
                                    Icon(
                                      order.priority == 'Urgente' ? Icons.local_fire_department : Icons.schedule,
                                      size: 14,
                                      color: order.priority == 'Urgente' ? Colors.red : (order.priority == 'Média' ? Colors.orange : (order.priority == 'Alta' ? Colors.orange.shade700 : Colors.grey)),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(order.priority.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: order.priority == 'Urgente' ? Colors.red : (order.priority == 'Média' ? Colors.orange : (order.priority == 'Alta' ? Colors.orange.shade700 : Colors.grey)))),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(equip != null ? '${equip.type} ${equip.brand}' : 'Equipamento N/D', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(order.problemDescription, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              order.status == 'Concluída' || order.status == 'Cancelada'
                              ? FutureBuilder(
                                  future: widget.controller.getOSHistory(order.id!),
                                  builder: (context, snapshot) {
                                    String completedDate = 'N/D';
                                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                      final historyList = snapshot.data as List;
                                      try {
                                        final last = historyList.lastWhere((h) => h.status == order.status);
                                        completedDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(last.date));
                                      } catch (_) {}
                                    }
                                    final isCancel = order.status == 'Cancelada';
                                    return Row(
                                      children: [
                                        Icon(isCancel ? Icons.cancel_outlined : Icons.check, size: 16, color: isCancel ? Colors.red : Colors.green),
                                        const SizedBox(width: 4),
                                        Text('${isCancel ? "Cancelada" : "Finalizada"} em $completedDate', style: TextStyle(fontWeight: FontWeight.bold, color: isCancel ? Colors.red : Colors.green, fontSize: 13)),
                                      ],
                                    );
                                  },
                                )
                              : Row(
                                  children: [
                                    if (tech != null)
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.blue.shade50,
                                            child: Text(tech.name[0].toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(tech.name.split(' ').take(2).join(' '), style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                        ],
                                      )
                                    else
                                      Row(
                                        children: [
                                          Icon(Icons.person_off, size: 16, color: Colors.grey.shade400),
                                          const SizedBox(width: 6),
                                          Text('Sem técnico', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                        ],
                                      ),
                                  ],
                                ),
                              if (order.status == 'Concluída' || order.status == 'Cancelada')
                                InkWell(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceOrderDetailScreen(controller: widget.controller, order: order))),
                                  child: const Text('Ver Detalhes', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14)),
                                )
                              else
                                Builder(
                                  builder: (context) {
                                    Color dateColor = Colors.grey.shade800; // default dark color for contrast
                                    if (order.expectedDate != null) {
                                      try {
                                        final p = order.expectedDate!.split('/');
                                        final date = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
                                        final diff = date.difference(DateTime.now()).inDays;
                                        if (diff < 3) dateColor = Colors.red;
                                      } catch (_) {}
                                    }
                                    return Text(
                                      'Prazo: ${order.expectedDate ?? "N/D"}', 
                                      style: TextStyle(color: dateColor, fontWeight: FontWeight.w600, fontSize: 13)
                                    );
                                  }
                                ),
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

  List<String> _preServiceImages = [];
  List<String> _postServiceImages = [];

  final ImagePicker _picker = ImagePicker();

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
      _preServiceImages = widget.order?.preServiceImages != null ? List.from(widget.order!.preServiceImages!) : [];
      _postServiceImages = widget.order?.postServiceImages != null ? List.from(widget.order!.postServiceImages!) : [];
      
      try { _openingDate = DateTime.parse(widget.order!.openingDate); } catch (_) {}
      if (widget.order!.expectedDate != null && widget.order!.expectedDate!.isNotEmpty) {
        try {
          final p = widget.order!.expectedDate!.split('/');
          _expectedDate = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
        } catch (_) {}
      }
    }
  }

  Future<void> _pickImages(bool isPre) async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isEmpty) return;

    final List<String> savedPaths = [];
    
    Directory destDir;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      destDir = Directory(p.join(Directory.current.path, 'data', 'images'));
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      destDir = Directory(p.join(docDir.path, 'images'));
    }
    
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }

    for (var file in images) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
      final savedImage = await File(file.path).copy(p.join(destDir.path, fileName));
      savedPaths.add(savedImage.path);
    }

    setState(() {
      if (isPre) {
        _preServiceImages.addAll(savedPaths);
      } else {
        _postServiceImages.addAll(savedPaths);
      }
    });
  }

  Widget _buildImageGallery(String label, List<String> images, bool isPre) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...images.map((path) {
                return Stack(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 4,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (isPre) {
                              _preServiceImages.remove(path);
                            } else {
                              _postServiceImages.remove(path);
                            }
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              InkWell(
                onTap: () => _pickImages(isPre),
                child: Container(
                  width: 70,
                  height: 70,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200, width: 2, style: BorderStyle.none),
                    color: Colors.blue.shade50,
                  ),
                  child: Icon(Icons.add_photo_alternate, color: Colors.blue.shade400, size: 30),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
      preServiceImages: _preServiceImages.isNotEmpty ? _preServiceImages : null,
      postServiceImages: _postServiceImages.isNotEmpty ? _postServiceImages : null,
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
              initialValue: _selectedCustomerId,
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
              initialValue: _selectedEquipmentId,
              decoration: const InputDecoration(hintText: 'Selecione o equipamento'),
              items: widget.controller.equipmentList.where((e) => e.customerId == _selectedCustomerId).map((e) {
                return DropdownMenuItem(value: e.id, child: Text('${e.type} ${e.brand} ${e.model}'));
              }).toList(),
              onChanged: (val) => setState(() => _selectedEquipmentId = val),
            ),
            const SizedBox(height: 16),
            _buildLabel('TÉCNICO RESPONSÁVEL'),
            DropdownButtonFormField<int>(
              initialValue: _selectedTechnicianId,
              decoration: const InputDecoration(hintText: 'Selecione um técnico'),
              items: widget.controller.technicianList.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
              onChanged: (val) => setState(() => _selectedTechnicianId = val),
            ),
            const SizedBox(height: 16),
            _buildImageGallery('ANEXAR IMAGENS (PRÉ-ATENDIMENTO)', _preServiceImages, true),
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
            _buildImageGallery('ANEXAR IMAGENS (PÓS-ATENDIMENTO)', _postServiceImages, false),
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
