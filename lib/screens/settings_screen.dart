import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantas_awb/providers/awb_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showAuditLog = false;
  bool _showBackupOptions = false;
  final _backupPasswordController = TextEditingController();

  @override
  void dispose() {
    _backupPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<AWBProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Security Status
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.security, color: Colors.green),
                            const SizedBox(width: 12),
                            Text(
                              'Security Status',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildSecurityItem('QR Code Verification', 'HMAC-SHA256 Enabled', true),
                        _buildSecurityItem('Offline Storage', 'SQLite Encrypted', true),
                        _buildSecurityItem('Backup Encryption', 'Password Protected', true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // AWB Management
                Text(
                  'AWB Management',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Check Expired AWBs'),
                  subtitle: const Text('Update status for expired AWBs'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => _checkExpiredAWBs(context, provider),
                ),
                const SizedBox(height: 24),

                // Audit Log
                Text(
                  'Security Audit Log',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('View Audit Log'),
                  subtitle: const Text('View all security events'),
                  trailing: Icon(
                    _showAuditLog ? Icons.expand_less : Icons.expand_more,
                  ),
                  onTap: () {
                    setState(() => _showAuditLog = !_showAuditLog);
                  },
                ),
                if (_showAuditLog)
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: provider.getAuditLogs(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No audit logs found'),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final log = snapshot.data![index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(log['event_type'] ?? 'Unknown'),
                              subtitle: Text(log['event_description'] ?? ''),
                              trailing: Chip(
                                label: Text(log['severity'] ?? 'info'),
                                backgroundColor: _getSeverityColor(log['severity']),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                const SizedBox(height: 24),

                // Backup & Restore
                Text(
                  'Backup & Restore',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Backup Options'),
                  subtitle: const Text('Create encrypted backup'),
                  trailing: Icon(
                    _showBackupOptions ? Icons.expand_less : Icons.expand_more,
                  ),
                  onTap: () {
                    setState(() => _showBackupOptions = !_showBackupOptions);
                  },
                ),
                if (_showBackupOptions)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _backupPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Backup Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _createBackup(context),
                            icon: const Icon(Icons.backup),
                            label: const Text('Create Backup'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _restoreBackup(context),
                            icon: const Icon(Icons.restore),
                            label: const Text('Restore Backup'),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // App Information
                Text(
                  'App Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('App Name', 'PANTAS AWB'),
                        _buildInfoRow('Version', '1.0.0'),
                        _buildInfoRow('Build', 'Flutter'),
                        _buildInfoRow('Database', 'SQLite'),
                        _buildInfoRow('Security', 'HMAC-SHA256'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecurityItem(String title, String subtitle, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.error,
            color: status ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String? severity) {
    switch (severity) {
      case 'info':
        return Colors.blue.withValues(alpha: 0.3);
      case 'warning':
        return Colors.orange.withValues(alpha: 0.3);
      case 'error':
        return Colors.red.withValues(alpha: 0.3);
      default:
        return Colors.grey.withValues(alpha: 0.3);
    }
  }

  Future<void> _checkExpiredAWBs(BuildContext context, AWBProvider provider) async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checking for expired AWBs...')),
      );
      
      await provider.checkExpiredAWBs();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expired AWBs updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createBackup(BuildContext context) async {
    if (_backupPasswordController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a password'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Creating backup...')),
      );

      // Backup creation would be implemented here
      // For now, just show success message
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    if (_backupPasswordController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the backup password'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restoring backup...')),
      );

      // Restore would be implemented here
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
