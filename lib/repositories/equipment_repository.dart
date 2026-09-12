import '../models/equipment.dart';
import '../services/database_service.dart';

class EquipmentRepository {
  Future<List<Equipment>> getAll() async {
    try {
      final db = await DatabaseService.instance.database;
      final result = await db.query('equipments', orderBy: 'type');
      return result.map(Equipment.fromMap).toList();
    } catch (e) {
      throw 'Não foi possível carregar a lista de equipamentos.';
    }
  }

  Future<List<Equipment>> getByCustomerId(int customerId) async {
    try {
      final db = await DatabaseService.instance.database;
      final result = await db.query('equipments', where: 'customer_id = ?', whereArgs: [customerId], orderBy: 'type');
      return result.map(Equipment.fromMap).toList();
    } catch (e) {
      throw 'Não foi possível carregar os equipamentos do cliente.';
    }
  }

  Future<int> save(Equipment equipment) async {
    try {
      if (equipment.type.trim().isEmpty) throw 'O tipo de equipamento é obrigatório.';
      if (equipment.brand.trim().isEmpty) throw 'A marca é obrigatória.';
      if (equipment.model.trim().isEmpty) throw 'O modelo é obrigatório.';

      final db = await DatabaseService.instance.database;
      final data = equipment.toMap()..remove('id');
      
      if (equipment.id == null) {
        return await db.insert('equipments', data);
      }
      
      await db.update('equipments', data, where: 'id = ?', whereArgs: [equipment.id]);
      return equipment.id!;
    } catch (e) {
      if (e is String) rethrow;
      throw 'Ocorreu um erro ao salvar os dados do equipamento.';
    }
  }

  Future<void> delete(int id) async {
    try {
      final db = await DatabaseService.instance.database;
      
      final osResult = await db.rawQuery('SELECT COUNT(*) FROM service_orders WHERE equipment_id = ?', [id]);
      final osCount = osResult.isNotEmpty ? osResult.first.values.first as int : 0;
      if (osCount > 0) {
        throw 'Não é possível excluir este equipamento pois existem ordens de serviço vinculadas a ele.';
      }
      
      await db.delete('equipments', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      if (e is String) rethrow;
      throw 'Não foi possível excluir o equipamento.';
    }
  }
}
