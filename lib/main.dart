import 'package:flutter/material.dart';

import 'controllers/app_controller.dart';
import 'core/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController();
  await controller.initialize();
  runApp(OSManagerApp(controller: controller));
}

class OSManagerApp extends StatelessWidget {
  final AppController controller;

  const OSManagerApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'OS Manager',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: controller.isLoggedIn
              ? MainNavigation(controller: controller)
              : LoginScreen(controller: controller),
        );
      }
    );
  }
}
