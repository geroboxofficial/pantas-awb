import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantas_awb/providers/awb_provider.dart';

class CreateAWBScreen extends StatefulWidget {
  const CreateAWBScreen({super.key});

  @override
  State<CreateAWBScreen> createState() => _CreateAWBScreenState();
}

class _CreateAWBScreenState extends State<CreateAWBScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedType;
  
  final _senderNameController = TextEditingController();
  final _senderPhoneController = TextEditingController();
  final _senderDepartmentController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientAddressController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _referenceController = TextEditingController();
  final _remarksController = TextEditingController();

  @override
  void dispose() {
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _senderDepartmentController.dispose();
    _recipientNameController.dispose();
    _recipientAddressController.dispose();
    _recipientPhoneController.dispose();
    _referenceController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New AWB'),
      ),
      body: Consumer<AWBProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AWB Type
                  Text(
                    'AWB Type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: 'Select AWB Type',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'A6', child: Text('A6')),
                      DropdownMenuItem(value: '80mm', child: Text('80mm')),
                      DropdownMenuItem(value: '58mm', child: Text('58mm')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedType = value);
                    },
                    validator: (value) {
                      if (value == null) return 'Please select AWB type';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Sender Section
                  Text(
                    'Sender Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _senderNameController,
                    label: 'Sender Name',
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _senderPhoneController,
                    label: 'Sender Phone',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _senderDepartmentController,
                    label: 'Sender Department',
                  ),
                  const SizedBox(height: 24),

                  // Recipient Section
                  Text(
                    'Recipient Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _recipientNameController,
                    label: 'Recipient Name',
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _recipientPhoneController,
                    label: 'Recipient Phone',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _recipientAddressController,
                    label: 'Recipient Address',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Additional Information
                  Text(
                    'Additional Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _referenceController,
                    label: 'Reference Number',
                    validator: (value) => null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _remarksController,
                    label: 'Remarks',
                    maxLines: 3,
                    validator: (value) => null,
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: provider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create AWB'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Error Message
                  if (provider.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        provider.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: false,
      validator: validator,
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<AWBProvider>();
      
      final success = await provider.createAWB(
        type: _selectedType!,
        senderName: _senderNameController.text,
        senderPhone: _senderPhoneController.text,
        senderDepartment: _senderDepartmentController.text,
        recipientName: _recipientNameController.text,
        recipientAddress: _recipientAddressController.text,
        recipientPhone: _recipientPhoneController.text,
        reference: _referenceController.text,
        remarks: _remarksController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AWB created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }
}
