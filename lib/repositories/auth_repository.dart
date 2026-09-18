import '../models/technician.dart';
import '../services/database_service.dart';

class AuthRepository {
  Future<Technician?> login(String matricula, String password) async {
    try {
      if (matricula.trim().isEmpty || password.trim().isEmpty) {
        throw 'Matrícula e senha são obrigatórias.';
      }

      final db = await DatabaseService.instance.database;
      final result = await db.query(
        'technicians',
        where: 'matricula = ? AND password = ?',
        whereArgs: [matricula, password],
      );

      if (result.isNotEmpty) {
        final technician = Technician.fromMap(result.first);
        if (!technician.isActive) {
          throw 'Este usuário está inativo e não pode acessar o sistema.';
        }
        return technician;
      }
      return null;
    } catch (e) {
      if (e is String) rethrow;
      throw 'Erro ao tentar realizar o login. Tente novamente mais tarde.';
    }
  }
}
