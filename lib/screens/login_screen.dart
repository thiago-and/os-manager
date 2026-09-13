import 'package:flutter/material.dart';
import '../controllers/app_controller.dart';

class LoginScreen extends StatefulWidget {
  final AppController controller;

  const LoginScreen({super.key, required this.controller});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _matriculaController = TextEditingController(text: '452018');
  final _passwordController = TextEditingController(text: '123456');

  void _login() {
    widget.controller.login(_matriculaController.text, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.build_circle, size: 80, color: Color(0xFF2962FF)),
                const SizedBox(height: 16),
                const Text(
                  'OS Manager',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2962FF),
                  ),
                ),
                const SizedBox(height: 48),
                if (widget.controller.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      widget.controller.errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                const Text('Matrícula', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _matriculaController,
                  decoration: const InputDecoration(
                    hintText: 'Digite sua matrícula',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Senha', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Digite sua senha',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: widget.controller.isLoading ? null : _login,
                  child: widget.controller.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Entrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
