import '../models/technician.dart';
import '../services/database_service.dart';

class TechnicianRepository {
  Future<List<Technician>> getAll() async {
    try {
      final db = await DatabaseService.instance.database;
      final result = await db.query('technicians', orderBy: 'name');
      return result.map(Technician.fromMap).toList();
    } catch (e) {
      throw 'Não foi possível carregar a lista de técnicos.';
    }
  }

  Future<int> save(Technician technician) async {
    try {
      if (technician.name.trim().isEmpty) throw 'O nome do técnico é obrigatório.';
      if (technician.contact.trim().length < 8) throw 'O contato informado é inválido.';
      if (technician.specialty.trim().isEmpty) throw 'A especialidade é obrigatória.';

      final db = await DatabaseService.instance.database;

      final existingList = await db.query('technicians', where: 'matricula = ?', whereArgs: [technician.matricula]);
      if (existingList.isNotEmpty) {
        final existing = existingList.first;
        if (technician.id == null || existing['id'] != technician.id) {
          throw 'Já existe um técnico cadastrado com esta matrícula.';
        }
      }
      
      if (technician.id != null && !technician.isActive) {
        final activeOSResult = await db.rawQuery(
          "SELECT COUNT(*) FROM service_orders WHERE technician_id = ? AND status NOT IN ('Concluída', 'Cancelada')",
          [technician.id]
        );
        final activeOSCount = activeOSResult.isNotEmpty ? activeOSResult.first.values.first as int : 0;
        if (activeOSCount > 0) {
          throw 'Não é possível inativar este técnico pois ele possui ordens de serviço em andamento.';
        }
      }

      final data = technician.toMap()..remove('id');
      
      if (technician.id == null) {
        return await db.insert('technicians', data);
      }
      
      await db.update('technicians', data, where: 'id = ?', whereArgs: [technician.id]);
      return technician.id!;
    } catch (e) {
      if (e is String) rethrow;
      throw 'Ocorreu um erro ao salvar os dados do técnico.';
    }
  }

  Future<void> delete(int id) async {
    try {
      final db = await DatabaseService.instance.database;
      
      final osResult = await db.rawQuery('SELECT COUNT(*) FROM service_orders WHERE technician_id = ?', [id]);
      final osCount = osResult.isNotEmpty ? osResult.first.values.first as int : 0;
      if (osCount > 0) {
        throw 'Não é possível excluir este técnico pois existem ordens de serviço atribuídas a ele.';
      }
      
      await db.delete('technicians', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      if (e is String) rethrow;
      throw 'Não foi possível excluir o técnico.';
    }
  }
}
