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
            status: order.status,
            description: 'Ordem de serviço gerada.',
            userName: loggedUserName,
          );
          await txn.insert('os_history', history.toMap()..remove('id'));
        } else {
          // Check for status change to validate transition and generate history
          final oldResult = await txn.query('service_orders', columns: ['status'], where: 'id = ?', whereArgs: [order.id]);
          if (oldResult.isNotEmpty) {
            final oldStatus = oldResult.first['status'] as String;
            if (oldStatus != order.status) {
              _validateStatusTransition(oldStatus, order.status);
              
              String desc = 'Status alterado de $oldStatus para ${order.status}.';
              if (order.status == 'Aguardando Peça' && order.diagnosis != null && order.diagnosis!.isNotEmpty) {
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

  void _validateStatusTransition(String oldStatus, String newStatus) {
    // Exemplo de bloqueio: Não pode ir de Cancelada para Concluída
    if (oldStatus == 'Cancelada' && newStatus == 'Concluída') {
      throw 'Transição inválida: Não é possível concluir uma ordem cancelada.';
    }
    if (oldStatus == 'Concluída' && newStatus == 'Aguardando Peça') {
      throw 'Transição inválida: A OS já foi concluída.';
    }
  }

  Future<void> delete(int id) async {
    try {
      final db = await DatabaseService.instance.database;
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
