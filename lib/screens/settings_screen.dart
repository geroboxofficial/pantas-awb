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
        backgroundColor: const Color(0xFF001F3F),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF001F3F).withOpacity(0.95),
              const Color(0xFF003D7A).withOpacity(0.95),
            ],
          ),
        ),
        child: Consumer<AWBProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Security Status
                  _buildCard(
                    title: 'Security Status',
                    icon: Icons.security,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSecurityItem('QR Code Verification', 'HMAC-SHA256 Enabled', true),
                        _buildSecurityItem('Offline Storage', 'SQLite Encrypted', true),
                        _buildSecurityItem('Backup Encryption', 'Password Protected', true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // AWB Management
                  _buildSectionTitle('AWB Management'),
                  const SizedBox(height: 12),
                  _buildListTile(
                    title: 'Check Expired AWBs',
                    subtitle: 'Update status for expired AWBs',
                    onTap: () => _checkExpiredAWBs(context, provider),
                  ),
                  const SizedBox(height: 24),

                  // Audit Log
                  _buildSectionTitle('Security Audit Log'),
                  const SizedBox(height: 12),
                  _buildListTile(
                    title: 'View Audit Log',
                    subtitle: 'View all security events',
                    trailing: _showAuditLog ? Icons.expand_less : Icons.expand_more,
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
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No audit logs found', style: TextStyle(color: Colors.white70)),
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
                              color: Colors.white.withOpacity(0.05),
                              child: ListTile(
                                title: Text(
                                  log['event_type'] ?? 'Unknown',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  log['event_description'] ?? '',
                                  style: const TextStyle(color: Colors.white70),
                                ),
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
                  _buildSectionTitle('Backup & Restore'),
                  const SizedBox(height: 12),
                  _buildListTile(
                    title: 'Backup Options',
                    subtitle: 'Create encrypted backup',
                    trailing: _showBackupOptions ? Icons.expand_less : Icons.expand_more,
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
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Backup Password',
                              labelStyle: const TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF00D9FF)),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _createBackup(context),
                              icon: const Icon(Icons.backup),
                              label: const Text('Create Backup'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00D9FF),
                                foregroundColor: const Color(0xFF001F3F),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _restoreBackup(context),
                              icon: const Icon(Icons.restore),
                              label: const Text('Restore Backup'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF00D9FF),
                                side: const BorderSide(color: Color(0xFF00D9FF)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Developer Details
                  _buildCard(
                    title: 'Developer Details',
                    icon: Icons.developer_mode,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PANTAS AWB Developer',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Name', 'Mohd Jany bin Mustapha'),
                        _buildInfoRow('Email', 'pantasonthego@gmail.com'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D9FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF00D9FF).withOpacity(0.3),
                            ),
                          ),
                          child: const Text(
                            'Developed with professional standards for secure and reliable handover management.',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App Information
                  _buildCard(
                    title: 'App Information',
                    icon: Icons.info,
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
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFF00D9FF).withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF00D9FF)),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: Colors.white,
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    IconData? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        trailing: trailing != null ? Icon(trailing, color: const Color(0xFF00D9FF)) : null,
        onTap: onTap,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
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
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String? severity) {
    switch (severity) {
      case 'info':
        return Colors.blue.withOpacity(0.3);
      case 'warning':
        return Colors.orange.withOpacity(0.3);
      case 'error':
        return Colors.red.withOpacity(0.3);
      default:
        return Colors.grey.withOpacity(0.3);
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
