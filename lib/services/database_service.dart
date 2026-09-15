import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      // Configura o banco na raiz do projeto
      final dbPath = kDebugMode 
          ? join(Directory.current.path, 'os_manager_v3.db') 
          : 'os_manager_v3.db';
          
      _database = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(version: 1, onCreate: _createDatabase),
      );
    } else {
      _database = await openDatabase(
        join(await getDatabasesPath(), 'os_manager_v3.db'),
        version: 1,
        onCreate: _createDatabase,
      );
    }
    return _database!;
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE technicians(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact TEXT NOT NULL,
        specialty TEXT NOT NULL,
        is_active INTEGER NOT NULL,
        matricula TEXT,
        password TEXT,
        photo_path TEXT
      )
    ''');
    
    // Inserir técnicos para teste
    await db.execute('''
      INSERT INTO technicians (name, contact, specialty, is_active, matricula, password) 
      VALUES ('Marcos Oliveira', '(11) 97766-5544', 'Eletrônica & Hardware', 1, '452018', '123456')
    ''');
    await db.execute('''
      INSERT INTO technicians (name, contact, specialty, is_active, matricula, password) 
      VALUES ('André Santos', '(11) 95544-3322', 'Redes & Infraestrutura', 1, '452022', '123456')
    ''');

    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        document TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
        address TEXT NOT NULL,
        created_at TEXT
      )
    ''');
    
    // Inserir clientes para teste
    await db.execute('''
      INSERT INTO customers (name, document, phone, email, address, created_at) 
      VALUES ('João Silva', '123.456.789-00', '(11) 98765-4321', 'joao.silva@email.com', 'Rua das Flores, 123 - Centro, São Paulo - SP', '2024-01-01T10:00:00')
    ''');
    await db.execute('''
      INSERT INTO customers (name, document, phone, email, address, created_at) 
      VALUES ('Maria Teixeira', '00.123.456/0001-88', '(11) 91234-5678', 'contato@maria.com', 'Av. Paulista, 1000 - Bela Vista', '2024-02-15T14:30:00')
    ''');
    await db.execute('''
      INSERT INTO customers (name, document, phone, email, address, created_at) 
      VALUES ('Ricardo Costa', '456.789.123-11', '(11) 99887-7665', 'ricardo@costa.com', 'Rua Augusta, 500 - Consolação', '2024-03-10T09:15:00')
    ''');

    await db.execute('''
      CREATE TABLE equipments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        serial_number TEXT NOT NULL,
        patrimony TEXT NOT NULL,
        observations TEXT NOT NULL,
        FOREIGN KEY(customer_id) REFERENCES customers(id)
      )
    ''');
    
    // Inserir equipamentos
    await db.execute('''
      INSERT INTO equipments (customer_id, type, brand, model, serial_number, patrimony, observations)
      VALUES (1, 'Notebook', 'Dell', 'Inspiron 15', 'ABC123XYZ', 'PAT-001245', '')
    ''');
    await db.execute('''
      INSERT INTO equipments (customer_id, type, brand, model, serial_number, patrimony, observations)
      VALUES (2, 'Impressora', 'HP', 'Laserjet', 'HP554433', 'PAT-008822', '')
    ''');

    await db.execute('''
      CREATE TABLE service_orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        customer_id INTEGER NOT NULL,
        equipment_id INTEGER,
        technician_id INTEGER,
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
        FOREIGN KEY(equipment_id) REFERENCES equipments(id),
        FOREIGN KEY(technician_id) REFERENCES technicians(id)
      )
    ''');
    
    // OS de teste
    await db.execute('''
      INSERT INTO service_orders (code, customer_id, equipment_id, technician_id, problem_description, priority, status, opening_date, expected_date, labor_value, material_value)
      VALUES ('#1024', 1, 1, 1, 'Notebook não liga e apresenta ruído.', 'Urgente', 'Em Atendimento', '2024-05-22T09:15:00', '25/10/2024', 0, 0)
    ''');
    await db.execute('''
      INSERT INTO service_orders (code, customer_id, equipment_id, technician_id, problem_description, priority, status, opening_date, expected_date, labor_value, material_value)
      VALUES ('#1023', 2, 2, NULL, 'Papel preso.', 'Média', 'Aberta', '2024-05-20T10:15:00', '28/10/2024', 0, 0)
    ''');

    await db.execute('''
      CREATE TABLE os_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        service_order_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        description TEXT NOT NULL,
        user_name TEXT NOT NULL,
        FOREIGN KEY(service_order_id) REFERENCES service_orders(id)
      )
    ''');
    
    await db.execute('''
      INSERT INTO os_history (service_order_id, date, status, description, user_name)
      VALUES (1, '2024-05-22T09:15:00', 'Em Atendimento', 'Status alterado de Aberta para Em Atendimento.', 'Marcos Oliveira')
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
