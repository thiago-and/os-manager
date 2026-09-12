import '../models/customer.dart';
import '../services/database_service.dart';

class CustomerRepository {
  Future<List<Customer>> getAll() async {
    try {
      final db = await DatabaseService.instance.database;
      final result = await db.query('customers', orderBy: 'name');
      return result.map(Customer.fromMap).toList();
    } catch (e) {
      throw 'Não foi possível carregar a lista de clientes.';
    }
  }

  Future<int> save(Customer customer) async {
    try {
      if (customer.name.trim().isEmpty) throw 'O nome do cliente é obrigatório.';
      if (customer.document.trim().isEmpty) throw 'O documento é obrigatório.';
      if (customer.phone.trim().length < 8) throw 'O telefone informado é inválido.';
      if (!customer.email.contains('@')) throw 'O e-mail informado é inválido.';

      final db = await DatabaseService.instance.database;
      final data = customer.toMap()..remove('id');
      
      if (customer.id == null) {
        data['created_at'] = DateTime.now().toIso8601String();
        return await db.insert('customers', data);
      }
      
      await db.update('customers', data, where: 'id = ?', whereArgs: [customer.id]);
      return customer.id!;
    } catch (e) {
      if (e is String) rethrow;
      throw 'Ocorreu um erro ao salvar os dados do cliente.';
    }
  }

  Future<void> delete(int id) async {
    try {
      final db = await DatabaseService.instance.database;
      
      final osResult = await db.rawQuery('SELECT COUNT(*) FROM service_orders WHERE customer_id = ?', [id]);
      final osCount = osResult.isNotEmpty ? osResult.first.values.first as int : 0;
      if (osCount > 0) {
        throw 'Não é possível excluir este cliente pois existem ordens de serviço vinculadas a ele.';
      }
      
      final equipResult = await db.rawQuery('SELECT COUNT(*) FROM equipments WHERE customer_id = ?', [id]);
      final equipCount = equipResult.isNotEmpty ? equipResult.first.values.first as int : 0;
      if (equipCount > 0) {
        throw 'Não é possível excluir este cliente pois existem equipamentos vinculados a ele.';
      }

      await db.delete('customers', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      if (e is String) rethrow;
      throw 'Não foi possível excluir o cliente.';
    }
  }
}
