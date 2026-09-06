import '../models/technician.dart';
import '../services/database_service.dart';

class TechnicianRepository {
  Future<List<Technician>> getAll() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('technicians', orderBy: 'name');
    return result.map(Technician.fromMap).toList();
  }

  Future<int> save(Technician technician) async {
    final db = await DatabaseService.instance.database;
    final data = technician.toMap()..remove('id');
    if (technician.id == null) return db.insert('technicians', data);
    await db.update('technicians', data, where: 'id = ?', whereArgs: [technician.id]);
    return technician.id!;
  }

  Future<void> delete(int id) async {
    final db = await DatabaseService.instance.database;
    await db.delete('technicians', where: 'id = ?', whereArgs: [id]);
  }
}
