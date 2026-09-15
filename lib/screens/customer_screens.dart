import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../controllers/app_controller.dart';
import '../models/customer.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  final AppController controller;

  const CustomerListScreen({super.key, required this.controller});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    if (widget.controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final customers = widget.controller.customerList.where((c) {
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             c.document.contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: customers.isEmpty
          ? const Center(child: Text('Nenhum cliente encontrado.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                final initials = customer.name.isNotEmpty 
                    ? customer.name.trim().split(' ').take(2).map((e) => e[0].toUpperCase()).join() 
                    : 'C';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      radius: 28,
                      child: Text(
                        initials,
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(customer.document, style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 2),
                        Text(customer.phone, style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerDetailScreen(controller: widget.controller, customer: customer),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CustomerFormScreen(controller: widget.controller)),
    );
  }
}

class CustomerFormScreen extends StatefulWidget {
  final AppController controller;
  final Customer? customer;

  const CustomerFormScreen({super.key, required this.controller, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _docController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####', 
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy
  );

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name);
    _docController = TextEditingController(text: widget.customer?.document);
    _phoneController = TextEditingController(text: widget.customer?.phone);
    _emailController = TextEditingController(text: widget.customer?.email);
    _addressController = TextEditingController(text: widget.customer?.address);
  }

  void _save() async {
    final customer = Customer(
      id: widget.customer?.id,
      name: _nameController.text,
      document: _docController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      address: _addressController.text,
      createdAt: widget.customer?.createdAt,
    );

    try {
      await widget.controller.saveCustomer(customer);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString(), style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer == null ? 'Novo Cliente' : 'Editar Cliente'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildField('Nome Completo / Razão Social', _nameController, 'Nome do cliente'),
            const SizedBox(height: 16),
            _buildField('CPF / CNPJ ou Identificação', _docController, 'Documento', formatters: [CpfCnpjFormatter()], keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildField('Telefone', _phoneController, '(00) 00000-0000', formatters: [_phoneFormatter], keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildField('E-mail', _emailController, 'cliente@email.com', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildField('Endereço Completo', _addressController, 'Rua, número, bairro...', maxLines: 3),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              child: Text(widget.customer == null ? 'Salvar Cliente' : 'Atualizar Cliente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, {int maxLines = 1, TextInputType? keyboardType, List<TextInputFormatter>? formatters}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: formatters,
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

class CpfCnpjFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 14) digits = digits.substring(0, 14);
    String formatted = '';
    if (digits.length <= 11) {
       for (int i=0; i<digits.length; i++) {
         formatted += digits[i];
         if (i == 2 || i == 5) formatted += '.';
         if (i == 8) formatted += '-';
       }
    } else {
       for (int i=0; i<digits.length; i++) {
         formatted += digits[i];
         if (i == 1 || i == 4) formatted += '.';
         if (i == 7) formatted += '/';
         if (i == 11) formatted += '-';
       }
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
