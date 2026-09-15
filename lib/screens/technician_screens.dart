import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../controllers/app_controller.dart';
import '../models/technician.dart';

class TechnicianListScreen extends StatefulWidget {
  final AppController controller;

  const TechnicianListScreen({super.key, required this.controller});

  @override
  State<TechnicianListScreen> createState() => _TechnicianListScreenState();
}

class _TechnicianListScreenState extends State<TechnicianListScreen> {
  int _selectedTabIndex = 0; // 0: Todos, 1: Disponíveis, 2: Inativos
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    if (widget.controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final technicians = widget.controller.technicianList.where((t) {
      bool tabMatch = true;
      if (_selectedTabIndex == 1) tabMatch = t.isActive;
      if (_selectedTabIndex == 2) tabMatch = !t.isActive;

      bool searchMatch = t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                         t.specialty.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                         (t.matricula?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      return tabMatch && searchMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Técnicos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor, // Light gray
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildTab('Todos', 0),
                const SizedBox(width: 8),
                _buildTab('Ativos', 1),
                const SizedBox(width: 8),
                _buildTab('Inativos', 2),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por nome, especialidade...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: technicians.isEmpty
                ? const Center(child: Text('Nenhum técnico encontrado.'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: technicians.length,
              itemBuilder: (context, index) {
                final tech = technicians[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                tech.name[0].toUpperCase(),
                                style: const TextStyle(fontSize: 24, color: Colors.blue),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tech.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  Text('Matrícula: ${tech.matricula ?? "N/D"}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(tech.specialty, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: tech.isActive ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tech.isActive ? 'ATIVO' : 'INATIVO',
                                style: TextStyle(
                                  color: tech.isActive ? Colors.green : Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Expanded(child: Text(tech.contact, style: TextStyle(color: Colors.grey.shade700))),
                            IconButton(
                              icon: const Icon(Icons.edit_square, color: Colors.blue),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showForm(context, tech),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _delete(context, tech),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showForm(BuildContext context, Technician? tech) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TechnicianFormScreen(controller: widget.controller, technician: tech)),
    );
  }

  void _delete(BuildContext context, Technician tech) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Excluir Técnico'),
        content: const Text('Deseja excluir este técnico?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.controller.deleteTechnician(tech.id!);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }
}

class TechnicianFormScreen extends StatefulWidget {
  final AppController controller;
  final Technician? technician;

  const TechnicianFormScreen({super.key, required this.controller, this.technician});

  @override
  State<TechnicianFormScreen> createState() => _TechnicianFormScreenState();
}

class _TechnicianFormScreenState extends State<TechnicianFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _matriculaController;
  late final TextEditingController _passwordController;
  bool _isActive = true;

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####', 
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy
  );

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.technician?.name);
    _contactController = TextEditingController(text: widget.technician?.contact);
    _specialtyController = TextEditingController(text: widget.technician?.specialty);
    _matriculaController = TextEditingController(
      text: widget.technician?.matricula ?? DateTime.now().millisecondsSinceEpoch.toString().substring(7)
    );
    _passwordController = TextEditingController();
    _isActive = widget.technician?.isActive ?? true;
  }

  void _save() async {
    final tech = Technician(
      id: widget.technician?.id,
      name: _nameController.text,
      contact: _contactController.text,
      specialty: _specialtyController.text,
      isActive: _isActive,
      matricula: _matriculaController.text,
      password: _passwordController.text.isNotEmpty ? _passwordController.text : widget.technician?.password,
    );

    try {
      await widget.controller.saveTechnician(tech);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.technician == null ? 'Novo Técnico' : 'Editar Técnico'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(Icons.camera_alt, size: 32, color: Colors.blue),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('Foto do Profissional', style: TextStyle(color: Colors.grey))),
            const SizedBox(height: 24),

            _buildField('Nome Completo', _nameController, 'Nome do técnico'),
            const SizedBox(height: 16),
            _buildField('Contato (Telefone/WhatsApp)', _contactController, '(00) 00000-0000', formatters: [_phoneFormatter], keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildField('Especialidade', _specialtyController, 'Ex: Eletrotécnica'),
            const SizedBox(height: 16),
            _buildField('Matrícula (Login)', _matriculaController, 'Digite a matrícula', keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            if (widget.technician == null)
              _buildField('Senha de Acesso', _passwordController, 'Digite a senha', obscureText: true),
            
            const SizedBox(height: 16),
            const Text('Situação do Técnico', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isActive = true),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isActive ? Colors.green.shade50 : Colors.white,
                        border: Border.all(color: _isActive ? Colors.green : Colors.grey.shade300, width: _isActive ? 2 : 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle, color: _isActive ? Colors.green : Colors.grey),
                          const SizedBox(height: 8),
                          Text('Ativo', style: TextStyle(fontWeight: FontWeight.bold, color: _isActive ? Colors.green : Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isActive = false),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: !_isActive ? Colors.red.shade50 : Colors.white,
                        border: Border.all(color: !_isActive ? Colors.red : Colors.grey.shade300, width: !_isActive ? 2 : 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.cancel, color: !_isActive ? Colors.red : Colors.grey),
                          const SizedBox(height: 8),
                          Text('Inativo', style: TextStyle(fontWeight: FontWeight.bold, color: !_isActive ? Colors.red : Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              child: Text(widget.technician == null ? 'Cadastrar Técnico' : 'Atualizar Técnico'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, {bool obscureText = false, List<TextInputFormatter>? formatters, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          inputFormatters: formatters,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
