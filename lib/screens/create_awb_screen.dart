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
  void initState() {
    super.initState();
    // Pre-fill sender info from profile if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<AWBProvider>().userProfile;
      if (profile != null) {
        setState(() {
          _senderNameController.text = profile.name;
          _senderPhoneController.text = profile.phone;
          _senderDepartmentController.text = profile.department;
        });
      }
    });
  }

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NEW CONSIGNMENT'),
      ),
      body: Consumer<AWBProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, 'SERVICE CONFIGURATION', Icons.settings_suggest_rounded),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    dropdownColor: colorScheme.surface,
                    decoration: const InputDecoration(
                      labelText: 'Print Format',
                      prefixIcon: Icon(Icons.print_rounded, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'A6', child: Text('A6 Standard')),
                      DropdownMenuItem(value: '80mm', child: Text('80mm Thermal')),
                      DropdownMenuItem(value: '58mm', child: Text('58mm Thermal')),
                    ],
                    onChanged: (value) => setState(() => _selectedType = value),
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 32),

                  _buildSectionHeader(context, 'SENDER INFORMATION', Icons.person_rounded),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _senderNameController,
                    label: 'Full Name',
                    icon: Icons.person_outline_rounded,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _senderPhoneController,
                          label: 'Contact No',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _senderDepartmentController,
                          label: 'Department',
                          icon: Icons.business_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  _buildSectionHeader(context, 'RECIPIENT INFORMATION', Icons.local_shipping_rounded),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _recipientNameController,
                    label: 'Recipient Name',
                    icon: Icons.person_pin_circle_outlined,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _recipientPhoneController,
                    label: 'Contact No',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _recipientAddressController,
                    label: 'Delivery Address',
                    icon: Icons.location_on_outlined,
                    maxLines: 3,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 32),

                  _buildSectionHeader(context, 'REFERENCE & REMARKS', Icons.info_outline_rounded),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _referenceController,
                    label: 'Reference Number',
                    icon: Icons.tag_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _remarksController,
                    label: 'Additional Remarks',
                    icon: Icons.comment_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: provider.isLoading ? null : _submitForm,
                    child: provider.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('GENERATE AIRWAY BILL'),
                  ),
                  
                  if (provider.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        provider.error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        alignLabelWithHint: maxLines > 1,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final success = await context.read<AWBProvider>().createAWB(
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
          const SnackBar(content: Text('AWB generated successfully'), backgroundColor: Colors.greenAccent),
        );
        Navigator.pop(context);
      }
    }
  }
}
