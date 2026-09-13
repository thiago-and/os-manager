import 'package:flutter/material.dart';
import '../controllers/app_controller.dart';
import 'dashboard_screen.dart';
import 'customer_screens.dart';
import 'technician_screens.dart';
import 'service_order_screens.dart';
import 'equipment_screens.dart';

class MainNavigation extends StatefulWidget {
  final AppController controller;

  const MainNavigation({super.key, required this.controller});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    DashboardScreen(controller: widget.controller),
    CustomerListScreen(controller: widget.controller),
    ServiceOrderListScreen(controller: widget.controller),
    TechnicianListScreen(controller: widget.controller),
    EquipmentListScreen(controller: widget.controller),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'OS'),
          BottomNavigationBarItem(icon: Icon(Icons.engineering), label: 'Técnicos'),
          BottomNavigationBarItem(icon: Icon(Icons.laptop_chromebook), label: 'Equip.'),
        ],
      ),
    );
  }
}
