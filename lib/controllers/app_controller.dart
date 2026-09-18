import 'package:flutter/foundation.dart';

import '../models/customer.dart';
import '../models/equipment.dart';
import '../models/os_history.dart';
import '../models/service_order.dart';
import '../models/technician.dart';
import '../repositories/auth_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/equipment_repository.dart';
import '../repositories/service_order_repository.dart';
import '../repositories/technician_repository.dart';

class AppController extends ChangeNotifier {
  final _auth = AuthRepository();
  final _customers = CustomerRepository();
  final _equipments = EquipmentRepository();
  final _technicians = TechnicianRepository();
  final _orders = ServiceOrderRepository();

  Technician? currentUser;
  List<Customer> customerList = [];
  List<Equipment> equipmentList = [];
  List<Technician> technicianList = [];
  List<ServiceOrder> orderList = [];

  bool isLoading = true;
  bool isLoggedIn = false;
  String? errorMessage;

  Future<void> initialize() async {
    await refresh();
  }

  Future<void> refresh() async {
    if (!isLoggedIn) {
      isLoading = false;
      notifyListeners();
      return;
    }
    
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      customerList = await _customers.getAll();
      equipmentList = await _equipments.getAll();
      technicianList = await _technicians.getAll();
      orderList = await _orders.getAll();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String matricula, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final user = await _auth.login(matricula, password);
      if (user != null) {
        currentUser = user;
        isLoggedIn = true;
        await refresh();
      } else {
        errorMessage = 'Matrícula ou senha incorretos.';
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    currentUser = null;
    isLoggedIn = false;
    customerList.clear();
    equipmentList.clear();
    technicianList.clear();
    orderList.clear();
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
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

  Future<void> saveEquipment(Equipment equipment) async {
    await _equipments.save(equipment);
    await refresh();
  }

  Future<void> deleteEquipment(int id) async {
    await _equipments.delete(id);
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
    if (currentUser == null) throw 'Usuário não logado.';
    await _orders.save(order, loggedUserName: currentUser!.name);
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

  Equipment? equipmentById(int? id) {
    if (id == null) return null;
    for (final equipment in equipmentList) {
      if (equipment.id == id) return equipment;
    }
    return null;
  }

  Technician? technicianById(int? id) {
    for (final technician in technicianList) {
      if (technician.id == id) return technician;
    }
    return null;
  }

  Future<List<OSHistory>> getOSHistory(int orderId) async {
    return await _orders.getHistory(orderId);
  }

  DashboardMetrics get metrics => DashboardMetrics(orderList);
}

class DashboardMetrics {
  final List<ServiceOrder> orders;

  DashboardMetrics(this.orders);

  int get total => orders.length;
  int count(String status) => orders.where((order) => order.status == status).length;
  int get urgent => orders.where((order) => order.priority == 'Urgente' && order.status != 'Concluída' && order.status != 'Cancelada').length;
  
  int get overdue {
    int count = 0;
    final now = DateTime.now();
    for (final order in orders) {
      if (order.expectedDate != null && order.status != 'Concluída' && order.status != 'Cancelada') {
        try {
          final parts = order.expectedDate!.split('/');
          if (parts.length == 3) {
            final expected = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
            if (expected.isBefore(DateTime(now.year, now.month, now.day))) {
              count++;
            }
          }
        } catch (_) {}
      }
    }
    return count;
  }

  double get estimatedValue => orders.fold(0.0, (sum, order) => sum + order.laborValue + order.materialValue);
}
