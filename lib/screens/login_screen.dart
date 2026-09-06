import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';

class LoginScreen extends StatefulWidget {
  final AppController controller;

  const LoginScreen({super.key, required this.controller});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _registrationController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _registrationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.controller.currentUser = _registrationController.text.trim();
    widget.controller.isLoggedIn = true;
    widget.controller.notifyListeners();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.build_circle_rounded, size: 68, color: Color(0xFF1769C2)),
                      const SizedBox(height: 16),
                      const Text('OS Manager', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1769C2))),
                      const SizedBox(height: 5),
                      const Text('Gestão de Ordens de Serviço', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6C7A90))),
                      const SizedBox(height: 48),
                      const Text('Matrícula', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 7),
                      TextFormField(
                        controller: _registrationController,
                        decoration: const InputDecoration(hintText: 'Digite sua matrícula'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Informe sua matrícula' : null,
                      ),
                      const SizedBox(height: 18),
                      const Text('Senha', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 7),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Digite sua senha',
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Informe sua senha' : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(onPressed: () {}, child: const Text('Esqueceu a senha?')),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(onPressed: _login, child: const Padding(padding: EdgeInsets.symmetric(vertical: 13), child: Text('Entrar'))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
