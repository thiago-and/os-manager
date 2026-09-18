import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';

import 'controllers/app_controller.dart';
import 'core/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(405, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

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
