import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../controllers/app_controller.dart';
import '../models/service_order.dart';
import '../models/os_history.dart';
import '../widgets/status_chip.dart';
import 'service_order_screens.dart';
import 'equipment_detail_screen.dart';

class ServiceOrderDetailScreen extends StatefulWidget {
  final AppController controller;
  final ServiceOrder order;

  const ServiceOrderDetailScreen({super.key, required this.controller, required this.order});

  @override
  State<ServiceOrderDetailScreen> createState() => _ServiceOrderDetailScreenState();
}

class _ServiceOrderDetailScreenState extends State<ServiceOrderDetailScreen> {
  List<OSHistory> _history = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      _history = await widget.controller.getOSHistory(widget.order.id!);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  void _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Excluir OS'),
        content: const Text('Tem certeza que deseja excluir esta Ordem de Serviço?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.controller.deleteOrder(widget.order.id!);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _generateAndSharePdf(ServiceOrder currentOrder, var customer, var equip, var tech) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text('Ordem de Servico - OS ${currentOrder.code}', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 16),
              pw.Text('Status: ${currentOrder.status}', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Prioridade: ${currentOrder.priority}', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Data Prevista: ${currentOrder.expectedDate ?? "N/D"}', style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 24),
              pw.Text('Cliente: ${customer?.name ?? "N/D"}', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Equipamento: ${equip != null ? "${equip.type} ${equip.brand}" : "N/D"} (S/N: ${equip?.serialNumber ?? "N/D"})', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Tecnico: ${tech?.name ?? "N/D"}', style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 24),
              pw.Text('Problema Relatado:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text(currentOrder.problemDescription, style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 16),
              pw.Text('Diagnostico / Solucao:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text(currentOrder.diagnosis ?? "N/D", style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 24),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Valor Mao de Obra: R\$ ${currentOrder.laborValue.toStringAsFixed(2)}'),
                  pw.Text('Valor Material: R\$ ${currentOrder.materialValue.toStringAsFixed(2)}'),
                ]
              ),
              pw.Divider(),
              pw.Text('Total: R\$ ${(currentOrder.laborValue + currentOrder.materialValue).toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
            ]
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: 'OS_${currentOrder.code}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        // Obter a OS atualizada da lista, se possível
        final currentOrder = widget.controller.orderList.firstWhere(
          (o) => o.id == widget.order.id,
          orElse: () => widget.order,
        );

        final customer = widget.controller.customerById(currentOrder.customerId);
        final tech = widget.controller.technicianById(currentOrder.technicianId);
        final equip = widget.controller.equipmentById(currentOrder.equipmentId);

        return Scaffold(
          appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OS ${currentOrder.code}'),
            StatusChip(status: currentOrder.status),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.print), onPressed: () => _generateAndSharePdf(currentOrder, customer, equip, tech)),
          IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(color: Theme.of(context).primaryColor, height: 20),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniCard(
                            'PRIORIDADE', 
                            currentOrder.priority, 
                            Icons.flag, 
                            _getPriorityColor(currentOrder.priority)
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMiniCard(
                            'PREVISÃO', 
                            currentOrder.expectedDate ?? 'N/D', 
                            Icons.calendar_today, 
                            _getDateColor(currentOrder.expectedDate, currentOrder.status)
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Informações Gerais', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                if (equip != null)
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => EquipmentDetailScreen(controller: widget.controller, equipment: equip)));
                                    },
                                    child: const Text('Ver Equipamento'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(Icons.person, 'CLIENTE', customer?.name ?? 'N/D', customer?.phone),
                            const Divider(height: 24),
                            _buildInfoRow(Icons.laptop_mac, 'EQUIPAMENTO', equip != null ? '${equip.type} ${equip.brand}' : 'N/D', equip != null ? 'S/N: ${equip.serialNumber}' : null),
                            const Divider(height: 24),
                            _buildInfoRow(Icons.engineering, 'TÉCNICO ATRIBUÍDO', tech?.name ?? 'N/D', null),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('RELATO DO PROBLEMA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                            const SizedBox(height: 8),
                            Text(currentOrder.problemDescription, style: const TextStyle(height: 1.5)),
                            if (currentOrder.preServiceImages != null && currentOrder.preServiceImages!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text('IMAGENS PRÉ-ATENDIMENTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 4),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: currentOrder.preServiceImages!.map((path) => Container(
                                    width: 80, height: 80, margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover)),
                                  )).toList(),
                                ),
                              ),
                            ],
                            
                            if (currentOrder.diagnosis != null && currentOrder.diagnosis!.isNotEmpty) ...[
                              const Divider(height: 24),
                              const Text('DIAGNÓSTICO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                              const SizedBox(height: 8),
                              Text(currentOrder.diagnosis!, style: const TextStyle(height: 1.5)),
                            ],
                            
                            if (currentOrder.solution != null && currentOrder.solution!.isNotEmpty) ...[
                              const Divider(height: 24),
                              const Text('SOLUÇÃO APLICADA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                              const SizedBox(height: 8),
                              Text(currentOrder.solution!, style: const TextStyle(height: 1.5)),
                            ],

                            if (currentOrder.postServiceImages != null && currentOrder.postServiceImages!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text('IMAGENS PÓS-ATENDIMENTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 4),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: currentOrder.postServiceImages!.map((path) => Container(
                                    width: 80, height: 80, margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover)),
                                  )).toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('HISTÓRICO DE EVOLUÇÃO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const SizedBox(height: 16),
                    if (_loadingHistory)
                      const Center(child: CircularProgressIndicator())
                    else if (_history.isEmpty)
                      const Text('Nenhum histórico disponível.')
                    else
                      ..._history.map((h) => _buildTimelineItem(h)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceOrderFormScreen(controller: widget.controller, order: currentOrder)))
                .then((_) => _loadHistory()); // reload history when coming back
            },
            icon: const Icon(Icons.edit_square),
            label: const Text('Editar Ordem de Serviço'),
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildMiniCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade400)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, String? subValue) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.blue),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (subValue != null) Text(subValue, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgente': return Colors.red;
      case 'Alta': return Colors.orange;
      case 'Média': return Colors.amber;
      case 'Baixa': return Colors.green;
      default: return Colors.blue;
    }
  }

  Color _getDateColor(String? expectedDate, String status) {
    if (status == 'Concluída' || status == 'Cancelada' || expectedDate == null) return Colors.blue;
    try {
      final p = expectedDate.split('/');
      final exp = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final diff = exp.difference(today).inDays;
      if (diff < 0) return Colors.red;
      if (diff <= 3) return Colors.red.shade300;
      return Colors.blue;
    } catch (_) {
      return Colors.blue;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Aberta': return Colors.blueGrey;
      case 'Atribuída': return Colors.indigo;
      case 'Em Atendimento': return Colors.blue;
      case 'Aguardando Peça': return Colors.orange;
      case 'Concluída': return Colors.green;
      case 'Cancelada': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildTimelineItem(OSHistory h) {
    final date = DateTime.tryParse(h.date) ?? DateTime.now();
    final fmtDate = DateFormat('dd/MM, HH:mm').format(date);
    final statusColor = _getStatusColor(h.status);
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: Colors.grey.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(h.status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(fmtDate, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(h.description),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text('Por: ${h.userName}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
