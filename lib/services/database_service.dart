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
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: _createDatabase,
        ),
      );
    } else {
      _database = await openDatabase(
        join(await getDatabasesPath(), 'os_manager_v3.db'),
        version: 2,
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
    await db.execute("INSERT INTO technicians (name, contact, specialty, is_active, matricula, password) VALUES ('Marcos Oliveira', '(11) 97766-5544', 'Eletrônica', 1, '452018', '123456')");
    await db.execute("INSERT INTO technicians (name, contact, specialty, is_active, matricula, password) VALUES ('André Santos', '(11) 95544-3322', 'Redes', 1, '452022', '123456')");
    await db.execute("INSERT INTO technicians (name, contact, specialty, is_active, matricula, password) VALUES ('Joana Silva', '(11) 99988-7766', 'Software', 1, '452023', '123456')");
    await db.execute("INSERT INTO technicians (name, contact, specialty, is_active, matricula, password) VALUES ('Técnico Inativo', '(11) 00000-0000', 'Geral', 0, '452024', '123456')");

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
    await db.execute("INSERT INTO customers (name, document, phone, email, address, created_at) VALUES ('Empresa Alpha', '00.123.456/0001-88', '(11) 91234-5678', 'contato@alpha.com', 'Av. Paulista, 1000', '2026-02-15T14:30:00')");
    await db.execute("INSERT INTO customers (name, document, phone, email, address, created_at) VALUES ('João Silva', '123.456.789-00', '(11) 98765-4321', 'joao.silva@email.com', 'Rua das Flores, 123', '2026-01-01T10:00:00')");
    await db.execute("INSERT INTO customers (name, document, phone, email, address, created_at) VALUES ('Maria Teixeira', '456.789.123-11', '(11) 99887-7665', 'maria@email.com', 'Rua Augusta, 500', '2026-07-10T09:15:00')");

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
    await db.execute("INSERT INTO equipments (customer_id, type, brand, model, serial_number, patrimony, observations) VALUES (1, 'Servidor', 'Dell', 'PowerEdge', 'SRV001', 'PAT-001', '')");
    await db.execute("INSERT INTO equipments (customer_id, type, brand, model, serial_number, patrimony, observations) VALUES (1, 'Switch', 'Cisco', 'Catalyst', 'SW001', 'PAT-002', '')");
    await db.execute("INSERT INTO equipments (customer_id, type, brand, model, serial_number, patrimony, observations) VALUES (2, 'Notebook', 'Lenovo', 'ThinkPad', 'NB001', 'PAT-003', '')");
    await db.execute("INSERT INTO equipments (customer_id, type, brand, model, serial_number, patrimony, observations) VALUES (2, 'Monitor', 'LG', 'Ultrawide', 'MN001', 'PAT-004', '')");
    await db.execute("INSERT INTO equipments (customer_id, type, brand, model, serial_number, patrimony, observations) VALUES (3, 'Impressora', 'HP', 'LaserJet', 'PR001', 'PAT-005', '')");

    await db.execute('''
      CREATE TABLE service_orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        customer_id INTEGER NOT NULL,
        equipment_id INTEGER,
        technician_id INTEGER,
        problem_description TEXT NOT NULL,
        image_path TEXT,
        pre_service_images TEXT,
        post_service_images TEXT,
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
    
    // OS de teste - 10 variações
    // 1: Urgente, Em Atendimento, Atrasada
    await db.execute("INSERT INTO service_orders (code, customer_id, equipment_id, technician_id, problem_description, priority, status, opening_date, expected_date, labor_value, material_value) VALUES ('#1001', 1, 1, 1, 'Servidor não inicia o SO.', 'Urgente', 'Em Atendimento', '2026-09-01T09:00:00', '10/09/2026', 150.0, 0)");
    
    // 2: Aberta, Sem técnico, Média, No prazo
    await db.execute("INSERT INTO service_orders (code, customer_id, equipment_id, technician_id, problem_description, priority, status, opening_date, expected_date, labor_value, material_value) VALUES ('#1002', 2, 3, NULL, 'Notebook muito lento.', 'Média', 'Aberta', '2026-09-20T10:00:00', '25/12/2026', 0, 0)");
    
    // 3: Aguardando Peça, Urgente, Atrasada
    await db.execute("INSERT INTO service_orders (code, customer_id, equipment_id, technician_id, problem_description, priority, status, opening_date, expected_date, labor_value, material_value) VALUES ('#1003', 3, 5, 2, 'Impressora atolando papel constantemente.', 'Urgente', 'Aguardando Peça', '2026-09-10T14:00:00', '15/09/2026', 50.0, 120.0)");
    
    // 4: Concluída, Alta
    await db.execute("INSERT INTO service_orders (code, customer_id, equipment_id, technician_id, problem_description, priority, status, opening_date, expected_date, diagnosis, solution, labor_value, material_value) VALUES ('#1004', 1, 2, 2, 'Portas do switch falhando.', 'Alta', 'Concluída', '2026-08-01T08:00:00', '05/08/2026', 'Módulo queimado.', 'Troca de módulo.', 200.0, 500.0)");
    
    // 5: Cancelada, Baixa
    await db.execute("INSERT INTO service_orders (code, customer_id, equipment_id, technician_id, problem_description, priority, status, opening_date, expected_date, labor_value, material_value) VALUES ('#1005', 2, 4, 3, 'Monitor piscando.', 'Baixa', 'Cancelada', '2026-09-15T11:00:00', '20/09/2026', 0, 0)");
    
    // 6: Atribuída, Alta, No Prazo
    await db.execute("INSERT INTO service_orders (code, customer_id, equipment_id, technician_id, problem_description, priority, status, opening_date, expected_date, labor_value, material_value) VALUES ('#1006', 3, 5, 1, 'Manutenção preventiva da impressora.', 'Alta', 'Atribuída', '2026-09-21T09:00:00', '30/12/2026', 0, 0)");
    
    // 7: Aberta, Sem técnico, Urgente, Atrasada (Cenário crítico)
    await db.execute("INSERT INTO service_orders (code, customer_id, equipment_id, technician_id, problem_description, priority, status, opening_date, expected_date, labor_value, material_value) VALUES ('#1007', 1, 1, NULL, 'Servidor emitindo bipes e desligando.', 'Urgente', 'Aberta', '2026-09-05T08:00:00', '06/09/2026', 0, 0)");

    // 8: Em Atendimento, Baixa, No Prazo
    await db.execute("INSERT INTO service_orders (code, customer_id, equipment_id, technician_id, problem_description, priority, status, opening_date, expected_date, labor_value, material_value) VALUES ('#1008', 2, 3, 3, 'Limpeza do notebook.', 'Baixa', 'Em Atendimento', '2026-09-22T10:00:00', '20/12/2026', 80.0, 0)");

    // 9: Aguardando Peça, Média, No Prazo
    await db.execute("INSERT INTO service_orders (code, customer_id, equipment_id, technician_id, problem_description, priority, status, opening_date, expected_date, labor_value, material_value) VALUES ('#1009', 2, 4, 1, 'Troca da tela do monitor.', 'Média', 'Aguardando Peça', '2026-09-20T11:00:00', '15/12/2026', 100.0, 350.0)");

    // 10: Concluída, Baixa
    await db.execute("INSERT INTO service_orders (code, customer_id, equipment_id, technician_id, problem_description, priority, status, opening_date, expected_date, diagnosis, solution, labor_value, material_value) VALUES ('#1010', 3, 5, 2, 'Configuração de rede na impressora.', 'Baixa', 'Concluída', '2026-07-01T14:00:00', '02/07/2026', 'Desconfigurada.', 'IP fixado.', 50.0, 0)");

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
    
    // OS 1 History (Em Atendimento)
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (1, '2026-09-01T09:00:00', 'Aberta', 'Ordem de serviço criada.', 'Sistema')");
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (1, '2026-09-01T10:30:00', 'Atribuída', 'Técnico Marcos Oliveira designado.', 'Sistema')");
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (1, '2026-09-02T08:15:00', 'Em Atendimento', 'Iniciada análise do servidor.', 'Marcos Oliveira')");

    // OS 3 History (Aguardando Peça)
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (3, '2026-09-10T14:00:00', 'Aberta', 'Ordem de serviço criada.', 'Sistema')");
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (3, '2026-09-10T14:30:00', 'Atribuída', 'Técnico André Santos designado.', 'Sistema')");
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (3, '2026-09-11T09:00:00', 'Em Atendimento', 'Iniciada desmontagem da impressora.', 'André Santos')");
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (3, '2026-09-11T11:45:00', 'Aguardando Peça', 'Necessário kit de roletes novos.', 'André Santos')");

    // OS 4 History (Concluída)
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (4, '2026-08-01T08:00:00', 'Aberta', 'Ordem de serviço criada.', 'Sistema')");
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (4, '2026-08-01T09:15:00', 'Atribuída', 'Técnico André Santos designado.', 'Sistema')");
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (4, '2026-08-02T10:00:00', 'Em Atendimento', 'Análise das portas do switch.', 'André Santos')");
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (4, '2026-08-05T09:15:00', 'Concluída', 'Troca de módulo realizada com sucesso. OS finalizada.', 'André Santos')");

    // OS 5 History (Cancelada)
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (5, '2026-09-15T11:00:00', 'Aberta', 'Ordem de serviço criada.', 'Sistema')");
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (5, '2026-09-15T11:30:00', 'Atribuída', 'Técnico Joana Silva designada.', 'Sistema')");
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (5, '2026-09-16T14:20:00', 'Cancelada', 'Cliente informou que o monitor voltou a funcionar sozinho.', 'Joana Silva')");

    // OS 6 History (Atribuída)
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (6, '2026-09-21T09:00:00', 'Aberta', 'Ordem de serviço criada.', 'Sistema')");
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (6, '2026-09-21T10:15:00', 'Atribuída', 'Técnico Marcos Oliveira designado.', 'Sistema')");

    // OS 8 History (Em Atendimento)
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (8, '2026-09-22T10:00:00', 'Aberta', 'Ordem de serviço criada.', 'Sistema')");
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (8, '2026-09-22T11:00:00', 'Atribuída', 'Técnico Joana Silva designada.', 'Sistema')");
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (8, '2026-09-23T14:00:00', 'Em Atendimento', 'Iniciada limpeza interna.', 'Joana Silva')");

    // OS 9 History (Aguardando Peça)
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (9, '2026-09-20T11:00:00', 'Aberta', 'Ordem de serviço criada.', 'Sistema')");
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (9, '2026-09-20T11:30:00', 'Atribuída', 'Técnico Marcos Oliveira designado.', 'Sistema')");
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (9, '2026-09-21T09:00:00', 'Em Atendimento', 'Desmontagem do monitor iniciada.', 'Marcos Oliveira')");
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (9, '2026-09-21T10:30:00', 'Aguardando Peça', 'Aguardando chegada da tela nova.', 'Marcos Oliveira')");

    // OS 10 History (Concluída)
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (10, '2026-07-01T14:00:00', 'Aberta', 'Ordem de serviço criada.', 'Sistema')");
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (10, '2026-07-01T14:45:00', 'Atribuída', 'Técnico André Santos designado.', 'Sistema')");
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (10, '2026-07-02T08:30:00', 'Em Atendimento', 'Verificação das configurações IP.', 'André Santos')");
    await db.execute("INSERT INTO os_history (service_order_id, date, status, description, user_name) VALUES (10, '2026-07-02T10:00:00', 'Concluída', 'Rede configurada. IP fixado.', 'André Santos')");

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
