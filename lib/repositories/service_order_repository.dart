import '../models/service_order.dart';
import '../models/os_history.dart';
import '../services/database_service.dart';

class ServiceOrderRepository {
  Future<List<ServiceOrder>> getAll() async {
    try {
      final db = await DatabaseService.instance.database;
      final result = await db.query('service_orders', orderBy: 'opening_date DESC');
      return result.map(ServiceOrder.fromMap).toList();
    } catch (e) {
      throw 'Não foi possível carregar a lista de ordens de serviço.';
    }
  }

  Future<List<OSHistory>> getHistory(int serviceOrderId) async {
    try {
      final db = await DatabaseService.instance.database;
      final result = await db.query('os_history', where: 'service_order_id = ?', whereArgs: [serviceOrderId], orderBy: 'date DESC');
      return result.map(OSHistory.fromMap).toList();
    } catch (e) {
      throw 'Não foi possível carregar o histórico desta ordem de serviço.';
    }
  }

  Future<int> save(ServiceOrder order, {required String loggedUserName}) async {
    try {
      if (order.problemDescription.trim().isEmpty) throw 'A descrição do problema é obrigatória.';
      if (order.laborValue < 0 || order.materialValue < 0) throw 'Os valores não podem ser negativos.';

      final db = await DatabaseService.instance.database;
      final data = order.toMap()..remove('id');
      
      return await db.transaction((txn) async {
        int orderId = order.id ?? 0;
        
        if (order.id == null) {
          orderId = await txn.insert('service_orders', data);
          
          final history = OSHistory(
            serviceOrderId: orderId,
            date: DateTime.now().toIso8601String(),
            status: 'Aberta',
            description: 'Ordem de serviço gerada.',
            userName: loggedUserName,
          );
          await txn.insert('os_history', history.toMap()..remove('id'));

          if (order.status != 'Aberta' || order.technicianId != null) {
            final assignmentHistory = OSHistory(
              serviceOrderId: orderId,
              date: DateTime.now().add(const Duration(seconds: 1)).toIso8601String(),
              status: order.status == 'Aberta' && order.technicianId != null ? 'Atribuída' : order.status,
              description: order.technicianId != null ? 'Técnico atribuído à OS.' : 'Status alterado para ${order.status}.',
              userName: loggedUserName,
            );
            await txn.insert('os_history', assignmentHistory.toMap()..remove('id'));
          }
        } else {
          // Check for status change to validate transition and generate history
          final oldResult = await txn.query('service_orders', columns: ['status', 'technician_id'], where: 'id = ?', whereArgs: [order.id]);
          if (oldResult.isNotEmpty) {
            final oldStatus = oldResult.first['status'] as String;
            final oldTechId = oldResult.first['technician_id'] as int?;

            bool techChanged = oldTechId != order.technicianId && order.technicianId != null;

            if (oldStatus != order.status) {
              _validateStatusTransition(oldStatus, order.status, order);
              
              String desc = 'Status alterado de $oldStatus para ${order.status}.';
              if (techChanged || (order.status == 'Atribuída' && oldStatus == 'Aberta')) {
                desc += ' Técnico designado para o atendimento.';
              } else if (order.status == 'Aguardando Peça' && order.diagnosis != null && order.diagnosis!.isNotEmpty) {
                desc += ' Diagnóstico: ${order.diagnosis}';
              } else if (order.status == 'Concluída' && order.solution != null && order.solution!.isNotEmpty) {
                desc += ' Solução: ${order.solution}';
              }

              final history = OSHistory(
                serviceOrderId: orderId,
                date: DateTime.now().toIso8601String(),
                status: order.status,
                description: desc,
                userName: loggedUserName,
              );
              await txn.insert('os_history', history.toMap()..remove('id'));
            } else if (techChanged) {
              final history = OSHistory(
                serviceOrderId: orderId,
                date: DateTime.now().toIso8601String(),
                status: order.status,
                description: 'Técnico designado para o atendimento.',
                userName: loggedUserName,
              );
              await txn.insert('os_history', history.toMap()..remove('id'));
            }
          }
          
          await txn.update('service_orders', data, where: 'id = ?', whereArgs: [order.id]);
        }
        
        return orderId;
      });
    } catch (e) {
      if (e is String) rethrow;
      throw 'Ocorreu um erro ao salvar a ordem de serviço.';
    }
  }

  void _validateStatusTransition(String oldStatus, String newStatus, ServiceOrder order) {
    if (oldStatus == 'Cancelada' && newStatus == 'Concluída') {
      throw 'Transição inválida: Não é possível concluir uma ordem cancelada.';
    }
    if (oldStatus == 'Concluída' && newStatus == 'Aguardando Peça') {
      throw 'Transição inválida: A OS já foi concluída.';
    }
    if (newStatus == 'Atribuída' && order.technicianId == null) {
      throw 'Transição inválida: Para mudar para Atribuída, um técnico deve estar selecionado.';
    }
    if (newStatus == 'Aguardando Peça') {
      if (order.diagnosis == null || order.diagnosis!.trim().isEmpty) {
        throw 'Transição inválida: É necessário informar um diagnóstico para colocar a OS em Aguardando Peça.';
      }
    }
    if (newStatus == 'Concluída') {
      if (oldStatus != 'Em Atendimento' && oldStatus != 'Aguardando Peça') {
        throw 'Transição inválida: Só é possível concluir uma OS que esteja Em Atendimento ou Aguardando Peça.';
      }
      if (order.diagnosis == null || order.diagnosis!.trim().isEmpty) {
        throw 'Transição inválida: É necessário preencher o registro de diagnóstico antes de concluir.';
      }
      if (order.solution == null || order.solution!.trim().isEmpty) {
        throw 'Transição inválida: É necessário preencher o registro de solução antes de concluir.';
      }
    }
  }

  Future<void> delete(int id) async {
    try {
      final db = await DatabaseService.instance.database;
      final result = await db.query('service_orders', columns: ['status'], where: 'id = ?', whereArgs: [id]);
      if (result.isNotEmpty) {
        final status = result.first['status'] as String;
        if (status != 'Aberta' && status != 'Cancelada') {
          throw 'Somente ordens de serviço com status Aberta ou Cancelada podem ser excluídas.';
        }
      }
      await db.transaction((txn) async {
        await txn.delete('used_items', where: 'service_order_id = ?', whereArgs: [id]);
        await txn.delete('os_history', where: 'service_order_id = ?', whereArgs: [id]);
        await txn.delete('service_orders', where: 'id = ?', whereArgs: [id]);
      });
    } catch (e) {
      throw 'Não foi possível excluir a ordem de serviço.';
    }
  }
}
