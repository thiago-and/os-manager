import 'package:flutter/material.dart';

import 'controllers/app_controller.dart';
import 'core/app_theme.dart';
import 'screens/customer_screens.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/service_order_screens.dart';
import 'screens/technician_screens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OsManagerApp());
}

class OsManagerApp extends StatefulWidget {
  const OsManagerApp({super.key});

  @override
  State<OsManagerApp> createState() => _OsManagerAppState();
}

class _OsManagerAppState extends State<OsManagerApp> {
  final AppController _controller = AppController();

  @override
  void initState() {
    super.initState();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScope(
        controller: _controller,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'OS Manager',
          theme: AppTheme.theme,
          home: _controller.isLoading
              ? const _LoadingScreen()
              : _controller.isLoggedIn
                  ? MainShell(controller: _controller)
                  : LoginScreen(controller: _controller),
        ),
      );
}

class AppScope extends InheritedNotifier<AppController> {
  final AppController controller;

  const AppScope({super.key, required this.controller, required super.child}) : super(notifier: controller);

  static AppController of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.controller;
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class MainShell extends StatefulWidget {
  final AppController controller;

  const MainShell({super.key, required this.controller});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _logout() {
    widget.controller.isLoggedIn = false;
    widget.controller.notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(controller: widget.controller, showOrders: () => setState(() => _index = 3), logout: _logout),
      CustomerListScreen(controller: widget.controller),
      TechnicianListScreen(controller: widget.controller),
      ServiceOrderListScreen(controller: widget.controller),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Clientes'),
          NavigationDestination(icon: Icon(Icons.engineering_outlined), selectedIcon: Icon(Icons.engineering), label: 'Técnicos'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Ordens'),
        ],
      ),
    );
  }
}
