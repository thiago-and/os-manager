import 'dart:io';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import '../controllers/app_controller.dart';
import '../models/service_order.dart';
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
      
      bool matchPriority = _selectedPriority == 'Todas' || o.priority == _selectedPriority;
      if (_selectedPriority != 'Todas' && _selectedStatus == 'Todos' && (o.status == 'Concluída' || o.status == 'Cancelada')) {
        matchPriority = false;
      }
      
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
      // 1. Grupo de Status
      int statusWeight(String status) {
        if (status == 'Cancelada') return 3;
        if (status == 'Concluída') return 2;
        return 1;
      }
      final sA = statusWeight(a.status);
      final sB = statusWeight(b.status);
      if (sA != sB) return sA.compareTo(sB);

      // 2. isAtrasada (apenas para ativas)
      if (sA == 1) {
        final aAtrasada = isAtrasada(a);
        final bAtrasada = isAtrasada(b);
        if (aAtrasada && !bAtrasada) return -1;
        if (!aAtrasada && bAtrasada) return 1;
      }

      // 3. Prioridade
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

      // 4. Data mais recente primeiro (DESC)
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
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final customer = widget.controller.customerById(order.customerId);
                final tech = widget.controller.technicianById(order.technicianId);
                final equip = widget.controller.equipmentById(order.equipmentId);

                return _buildOSCard(context, order, customer, tech, equip);
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

  Widget _buildOSCard(BuildContext context, ServiceOrder order, dynamic customer, dynamic tech, dynamic equip) {
    bool isCancel = order.status == 'Cancelada';
    bool isConcluida = order.status == 'Concluída';

    if (isConcluida || isCancel) {
      String completedDate = 'N/D';
      return FutureBuilder(
        future: widget.controller.getOSHistory(order.id!),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final historyList = snapshot.data as List;
            try {
              final last = historyList.lastWhere((h) => h.status == order.status);
              completedDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(last.date));
            } catch (_) {}
          }
          final statusStr = isCancel ? 'CANCELADA' : 'FINALIZADA';
          final color = isCancel ? Colors.red : Colors.green;
          final icon = isCancel ? Icons.cancel : Icons.check_circle;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceOrderDetailScreen(controller: widget.controller, order: order))),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            equip != null ? '${equip.type} ${equip.brand}' : 'Equipamento N/D',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey.shade400,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$statusStr EM $completedDate • OS ${order.code}',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(icon, color: color, size: 16),
                        const SizedBox(width: 4),
                        Text(statusStr, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool isAtrasada = false;
    String dateDisplay = order.expectedDate ?? 'N/D';
    if (order.expectedDate != null) {
      try {
        final p = order.expectedDate!.split('/');
        final exp = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
        if (exp.isBefore(today)) isAtrasada = true;
      } catch (_) {}
    }

    MaterialColor themeColor;
    IconData rightIcon;
    if (order.priority == 'Urgente') {
      themeColor = Colors.red;
      rightIcon = Icons.local_fire_department;
    } else if (order.priority == 'Alta') {
      themeColor = Colors.orange;
      rightIcon = Icons.error;
    } else if (order.priority == 'Média') {
      themeColor = Colors.blue;
      rightIcon = Icons.schedule;
    } else {
      themeColor = Colors.green;
      rightIcon = Icons.schedule;
    }

    String chipText = isAtrasada ? 'ATRASADA' : order.status.toUpperCase();
    Color chipBgColor = isAtrasada ? Colors.red.shade100 : themeColor.shade100;
    Color chipTextColor = isAtrasada ? Colors.red.shade700 : themeColor.shade700;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: themeColor.shade50.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: themeColor.shade100),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceOrderDetailScreen(controller: widget.controller, order: order))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('OS ${order.code}', style: TextStyle(color: themeColor.shade400, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: chipBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(chipText, style: TextStyle(color: chipTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(rightIcon, color: Colors.white, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                equip != null ? '${equip.type} ${equip.brand}' : 'Equipamento N/D',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeColor.shade900),
              ),
              const SizedBox(height: 4),
              Text(
                order.problemDescription,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: themeColor.shade700, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: themeColor.shade100),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (tech != null)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: themeColor.shade100,
                          backgroundImage: tech.photoPath != null ? FileImage(File(tech.photoPath!)) : null,
                          child: tech.photoPath == null ? Text(tech.name[0].toUpperCase(), style: TextStyle(fontSize: 10, color: themeColor.shade700, fontWeight: FontWeight.bold)) : null,
                        ),
                        const SizedBox(width: 8),
                        Text(tech.name.split(' ').take(2).join(' '), style: TextStyle(color: themeColor.shade900, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(Icons.person_off_outlined, size: 16, color: themeColor.shade400),
                        const SizedBox(width: 6),
                        Text('Aguardando Técnico', style: TextStyle(color: themeColor.shade400, fontSize: 12, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('PRAZO', style: TextStyle(color: themeColor.shade400, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(
                        dateDisplay,
                        style: TextStyle(color: themeColor, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServiceOrderFormScreen extends StatefulWidget {
  final AppController controller;
  final ServiceOrder? order;
  final int? initialCustomerId;

  const ServiceOrderFormScreen({super.key, required this.controller, this.order, this.initialCustomerId});

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
  late final TextEditingController _historyNoteController;

  final CurrencyTextInputFormatter _laborFormatter = CurrencyTextInputFormatter.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  );
  
  final CurrencyTextInputFormatter _materialFormatter = CurrencyTextInputFormatter.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  );
  
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
    _selectedCustomerId = widget.order?.customerId ?? widget.initialCustomerId;
    _selectedEquipmentId = widget.order?.equipmentId;
    _selectedTechnicianId = widget.order?.technicianId;
    
    _descController = TextEditingController(text: widget.order?.problemDescription);
    _diagController = TextEditingController(text: widget.order?.diagnosis);
    _solController = TextEditingController(text: widget.order?.solution);
    _laborController = TextEditingController(text: _laborFormatter.formatDouble(widget.order?.laborValue ?? 0));
    _materialController = TextEditingController(text: _materialFormatter.formatDouble(widget.order?.materialValue ?? 0));
    _historyNoteController = TextEditingController();
    
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

    if (_status == 'Atribuída' && _selectedTechnicianId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um técnico para o status Atribuída.')));
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
      laborValue: _laborFormatter.getUnformattedValue().toDouble(),
      materialValue: _materialFormatter.getUnformattedValue().toDouble(),
    );

    try {
      await widget.controller.saveOrder(order, historyNote: _historyNoteController.text);
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
            _buildLabel('NOTA PARA O HISTÓRICO (OPCIONAL)'),
            TextField(
              controller: _historyNoteController,
              decoration: const InputDecoration(
                hintText: 'Ex: Aguardando aprovação do orçamento, cliente avisado...',
              ),
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
              items: widget.controller.technicianList.where((t) => t.isActive || t.id == _selectedTechnicianId).map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
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
                  TextField(
                    controller: _laborController, 
                    keyboardType: TextInputType.number,
                    inputFormatters: [_laborFormatter],
                  ),
                ])),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildLabel('PEÇAS (R\$)'),
                  TextField(
                    controller: _materialController, 
                    keyboardType: TextInputType.number,
                    inputFormatters: [_materialFormatter],
                  ),
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
