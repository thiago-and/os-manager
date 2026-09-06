import '../models/customer.dart';
import '../services/database_service.dart';

class CustomerRepository {
  Future<List<Customer>> getAll() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('customers', orderBy: 'name');
    return result.map(Customer.fromMap).toList();
  }

  Future<int> save(Customer customer) async {
    final db = await DatabaseService.instance.database;
    final data = customer.toMap()..remove('id');
    if (customer.id == null) return db.insert('customers', data);
    await db.update('customers', data, where: 'id = ?', whereArgs: [customer.id]);
    return customer.id!;
  }

  Future<void> delete(int id) async {
    final db = await DatabaseService.instance.database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }
}
