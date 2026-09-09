import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      final directory = await getApplicationDocumentsDirectory();
      _database = await databaseFactoryFfi.openDatabase(
        join(directory.path, 'os_manager.db'),
        options: OpenDatabaseOptions(version: 1, onCreate: _createDatabase),
      );
    } else {
      _database = await openDatabase(
        join(await getDatabasesPath(), 'os_manager.db'),
        version: 1,
        onCreate: _createDatabase,
      );
    }
    return _database!;
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        document TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
        address TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE technicians(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact TEXT NOT NULL,
        specialty TEXT NOT NULL,
        is_active INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE service_orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        customer_id INTEGER NOT NULL,
        technician_id INTEGER,
        equipment TEXT NOT NULL,
        problem_description TEXT NOT NULL,
        image_path TEXT,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        opening_date TEXT NOT NULL,
        expected_date TEXT,
        diagnosis TEXT,
        solution TEXT,
        labor_value REAL NOT NULL,
        material_value REAL NOT NULL,
        FOREIGN KEY(customer_id) REFERENCES customers(id),
        FOREIGN KEY(technician_id) REFERENCES technicians(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE used_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        service_order_id INTEGER NOT NULL,
        description TEXT NOT NULL,
        value REAL NOT NULL,
        FOREIGN KEY(service_order_id) REFERENCES service_orders(id)
      )
    ''');
  }
}
