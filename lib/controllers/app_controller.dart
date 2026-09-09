import 'package:flutter/foundation.dart';

import '../models/customer.dart';
import '../models/service_order.dart';
import '../models/technician.dart';
import '../repositories/customer_repository.dart';
import '../repositories/service_order_repository.dart';
import '../repositories/technician_repository.dart';

class AppController extends ChangeNotifier {
  final _customers = CustomerRepository();
  final _technicians = TechnicianRepository();
  final _orders = ServiceOrderRepository();

  List<Customer> customerList = [];
  List<Technician> technicianList = [];
  List<ServiceOrder> orderList = [];
  bool isLoading = true;
  bool isLoggedIn = false;
  String currentUser = 'João Silva';

  Future<void> initialize() async {
    await _seedDatabase();
    await refresh();
  }

  Future<void> refresh() async {
    isLoading = true;
    notifyListeners();
    customerList = await _customers.getAll();
    technicianList = await _technicians.getAll();
    orderList = await _orders.getAll();
    isLoading = false;
    notifyListeners();
  }

  Future<void> saveCustomer(Customer customer) async {
    await _customers.save(customer);
    await refresh();
  }

  Future<void> deleteCustomer(int id) async {
    await _customers.delete(id);
    await refresh();
  }

  Future<void> saveTechnician(Technician technician) async {
    await _technicians.save(technician);
    await refresh();
  }

  Future<void> deleteTechnician(int id) async {
    await _technicians.delete(id);
    await refresh();
  }

  Future<void> saveOrder(ServiceOrder order) async {
    await _orders.save(order);
    await refresh();
  }

  Future<void> deleteOrder(int id) async {
    await _orders.delete(id);
    await refresh();
  }

  Customer? customerById(int id) {
    for (final customer in customerList) {
      if (customer.id == id) return customer;
    }
    return null;
  }

  Technician? technicianById(int? id) {
    for (final technician in technicianList) {
      if (technician.id == id) return technician;
    }
    return null;
  }

  DashboardMetrics get metrics => DashboardMetrics(orderList);

  void login(String registration) {
    currentUser = registration;
    isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    isLoggedIn = false;
    notifyListeners();
  }

  Future<void> _seedDatabase() async {
    if ((await _customers.getAll()).isNotEmpty) return;
    final pauloId = await _customers.save(const Customer(
      name: 'Padaria Pão de Mel',
      document: '12.345.678/0001-00',
      phone: '(11) 98888-7777',
      email: 'contato@paodemel.com',
      address: 'Rua das Flores, 120 - Centro',
    ));
    final carlosId = await _customers.save(const Customer(
      name: 'Carlos Eduardo Santos',
      document: '123.456.789-00',
      phone: '(11) 97777-2222',
      email: 'carlos@email.com',
      address: 'Av. Paulista, 800 - São Paulo',
    ));
    final joaoId = await _technicians.save(const Technician(
      name: 'João Silva',
      contact: '(11) 98888-8888',
      specialty: 'Eletrotécnica',
      isActive: true,
    ));
    final anaId = await _technicians.save(const Technician(
      name: 'Ana Costa',
      contact: '(11) 96666-4444',
      specialty: 'Climatização',
      isActive: true,
    ));
    await _orders.save(ServiceOrder(
      code: '#OS-2024-0087',
      customerId: pauloId,
      technicianId: joaoId,
      equipment: 'Forno Industrial Turbinado',
      problemDescription: 'Forno desliga após atingir 180°C.',
      priority: Priority.high,
      status: ServiceStatus.inProgress,
      openingDate: DateTime.now().subtract(const Duration(days: 2)),
      expectedDate: DateTime.now().add(const Duration(days: 2)),
      diagnosis: 'Sensor de temperatura com falha intermitente.',
      solution: 'Substituição do sensor realizada.',
      laborValue: 350,
      materialValue: 120,
    ));
    await _orders.save(ServiceOrder(
      code: '#OS-2024-0086',
      customerId: carlosId,
      technicianId: anaId,
      equipment: 'Ar Condicionado Split',
      problemDescription: 'Equipamento não está resfriando.',
      priority: Priority.medium,
      status: ServiceStatus.waitingPart,
      openingDate: DateTime.now().subtract(const Duration(days: 4)),
      expectedDate: DateTime.now().add(const Duration(days: 3)),
      diagnosis: 'Placa de controle danificada.',
      solution: '',
      laborValue: 180,
      materialValue: 0,
    ));
  }
}

class DashboardMetrics {
  final List<ServiceOrder> orders;

  DashboardMetrics(this.orders);

  int get total => orders.length;
  int count(ServiceStatus status) => orders.where((order) => order.status == status).length;
  int get urgent => orders.where((order) => order.priority == Priority.urgent).length;
  int get overdue => orders
      .where((order) =>
          order.expectedDate != null &&
          order.expectedDate!.isBefore(DateTime.now()) &&
          order.status != ServiceStatus.completed &&
          order.status != ServiceStatus.canceled)
      .length;
  double get estimatedValue => orders.fold(0, (sum, order) => sum + order.totalValue);
}
