import '../models/service_order.dart';
import '../services/database_service.dart';

class ServiceOrderRepository {
  Future<List<ServiceOrder>> getAll() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('service_orders', orderBy: 'opening_date DESC');
    return result.map(ServiceOrder.fromMap).toList();
  }

  Future<int> save(ServiceOrder order) async {
    final db = await DatabaseService.instance.database;
    final data = order.toMap()..remove('id');
    if (order.id == null) return db.insert('service_orders', data);
    await db.update('service_orders', data, where: 'id = ?', whereArgs: [order.id]);
    return order.id!;
  }

  Future<void> delete(int id) async {
    final db = await DatabaseService.instance.database;
    await db.delete('used_items', where: 'service_order_id = ?', whereArgs: [id]);
    await db.delete('service_orders', where: 'id = ?', whereArgs: [id]);
  }
}
