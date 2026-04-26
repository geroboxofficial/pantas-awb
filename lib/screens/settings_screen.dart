import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantas_awb/providers/awb_provider.dart';
import 'package:pantas_awb/services/pdf_service.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SYSTEM SETTINGS'),
      ),
      body: Consumer<AWBProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, 'SECURITY INFRASTRUCTURE', Icons.security_rounded),
                const SizedBox(height: 16),
                _buildCard(
                  child: Column(
                    children: [
                      _buildSecurityItem(Icons.verified_user_rounded, 'Encryption Protocol', 'AES-256 & SHA-256', true),
                      const Divider(color: Colors.white10),
                      _buildSecurityItem(Icons.storage_rounded, 'Database Integrity', 'Encrypted SQLite', true),
                      const Divider(color: Colors.white10),
                      _buildSecurityItem(Icons.cloud_done_rounded, 'Data Synchronization', 'Offline First Mode', true),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                _buildSectionHeader(context, 'DATA MANAGEMENT', Icons.data_usage_rounded),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  icon: Icons.history_rounded,
                  title: 'Security Audit Log',
                  subtitle: 'View and share system event history',
                  onTap: () => setState(() => _showAuditLog = !_showAuditLog),
                  trailing: Icon(_showAuditLog ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                ),
                if (_showAuditLog) _buildAuditLogList(provider),
                
                const SizedBox(height: 12),
                _buildSettingsTile(
                  icon: Icons.assessment_rounded,
                  title: 'Reports',
                  subtitle: 'Generate and share AWB reports',
                  onTap: () => _showReportOptions(context, provider),
                  trailing: const Icon(Icons.share_rounded),
                ),
                
                const SizedBox(height: 12),
                _buildSettingsTile(
                  icon: Icons.backup_rounded,
                  title: 'Backup & Recovery',
                  subtitle: 'Secure your data locally',
                  onTap: () => setState(() => _showBackupOptions = !_showBackupOptions),
                  trailing: Icon(_showBackupOptions ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                ),
                if (_showBackupOptions) _buildBackupControls(context),
                
                const SizedBox(height: 32),

                _buildSectionHeader(context, 'SYSTEM INFORMATION', Icons.info_outline_rounded),
                const SizedBox(height: 16),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PANTAS AWB ECOSYSTEM',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Developer', 'Mohd Jany bin Mustapha'),
                      _buildInfoRow('Contact', 'pantasonthego@gmail.com'),
                      _buildInfoRow('Version', '2.0.0+PRO'),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                        ),
                        child: const Text(
                          'Developed with professional standards for secure and reliable handover management. Features QR Code verification, printable AWB labels, and comprehensive audit logging.',
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
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

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _buildSecurityItem(IconData icon, String label, String value, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 10, color: Colors.white54)),
              ],
            ),
          ),
          if (active)
            const Icon(Icons.check_circle_rounded, size: 16, color: Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        trailing: trailing,
      ),
    );
  }

  Widget _buildAuditLogList(AWBProvider provider) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: provider.getAuditLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(padding: EdgeInsets.all(20), child: Text('No audit logs available', style: TextStyle(color: Colors.white38)));
        }
        
        final logs = snapshot.data!;
        
        return Column(
          children: [
            // Share button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _shareAuditLog(logs),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('SHARE AUDIT LOG'),
                ),
              ),
            ),
            // Audit log list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length.clamp(0, 20),
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
                  margin: const EdgeInsets.only(top: 8),
                  color: Colors.white.withOpacity(0.02),
                  child: ListTile(
                    dense: true,
                    leading: _getLogIcon(log['event_type'] ?? ''),
                    title: Text(log['event_type'] ?? 'EVENT', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    subtitle: Text(log['event_description'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          log['created_at'].toString().split('T')[0],
                          style: const TextStyle(fontSize: 9, color: Colors.white24),
                        ),
                        Text(
                          log['severity'] ?? 'info',
                          style: TextStyle(
                            fontSize: 8,
                            color: _getSeverityColor(log['severity'] ?? 'info'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBackupControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          TextField(
            controller: _backupPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Encryption Key', hintText: 'Enter secure key'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                  label: const Text('BACKUP'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.cloud_download_rounded, size: 18),
                  label: const Text('RESTORE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white38)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showReportOptions(BuildContext context, AWBProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GENERATE & SHARE REPORT',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 24),
            _buildReportOption(
              icon: Icons.description_rounded,
              title: 'All AWBs Report',
              subtitle: 'Generate report for all airway bills',
              onTap: () {
                Navigator.pop(context);
                _generateAndShareReport(provider, 'All AWBs');
              },
            ),
            const SizedBox(height: 12),
            _buildReportOption(
              icon: Icons.check_circle_rounded,
              title: 'Completed AWBs Report',
              subtitle: 'Report for completed transactions',
              onTap: () {
                Navigator.pop(context);
                _generateAndShareCompletedReport(provider);
              },
            ),
            const SizedBox(height: 12),
            _buildReportOption(
              icon: Icons.schedule_rounded,
              title: 'Active AWBs Report',
              subtitle: 'Report for pending transactions',
              onTap: () {
                Navigator.pop(context);
                _generateAndShareActiveReport(provider);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ),
    );
  }

  Future<void> _generateAndShareReport(AWBProvider provider, String reportName) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating report...'), duration: Duration(seconds: 2)),
      );

      final filePath = await PDFService.generateAWBReport(provider.awbs, reportName);
      
      if (mounted) {
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'PANTAS AWB Report - $reportName',
          text: 'Please find attached the PANTAS AWB Report for $reportName',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    }
  }

  Future<void> _generateAndShareCompletedReport(AWBProvider provider) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating report...'), duration: Duration(seconds: 2)),
      );

      final completedAWBs = provider.awbs.where((awb) => awb.status == 'completed').toList();
      final filePath = await PDFService.generateAWBReport(completedAWBs, 'Completed AWBs');
      
      if (mounted) {
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'PANTAS AWB Report - Completed Transactions',
          text: 'Please find attached the PANTAS AWB Report for completed transactions (${completedAWBs.length} records)',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    }
  }

  Future<void> _generateAndShareActiveReport(AWBProvider provider) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating report...'), duration: Duration(seconds: 2)),
      );

      final activeAWBs = provider.awbs.where((awb) => awb.status == 'created' || awb.status == 'scanned').toList();
      final filePath = await PDFService.generateAWBReport(activeAWBs, 'Active AWBs');
      
      if (mounted) {
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'PANTAS AWB Report - Active Transactions',
          text: 'Please find attached the PANTAS AWB Report for active transactions (${activeAWBs.length} records)',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    }
  }

  Future<void> _shareAuditLog(List<Map<String, dynamic>> logs) async {
    try {
      // Format audit log as text
      final buffer = StringBuffer();
      buffer.writeln('PANTAS AWB - SECURITY AUDIT LOG');
      buffer.writeln('Generated: ${DateTime.now()}');
      buffer.writeln('Total Events: ${logs.length}');
      buffer.writeln('=' * 80);
      buffer.writeln('');

      for (final log in logs) {
        buffer.writeln('Event Type: ${log['event_type']}');
        buffer.writeln('Description: ${log['event_description']}');
        buffer.writeln('Severity: ${log['severity']}');
        buffer.writeln('Timestamp: ${log['created_at']}');
        buffer.writeln('-' * 80);
      }

      await Share.share(
        buffer.toString(),
        subject: 'PANTAS AWB - Security Audit Log',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing audit log: $e')),
        );
      }
    }
  }

  Icon _getLogIcon(String eventType) {
    if (eventType.contains('CREATED')) return const Icon(Icons.add_circle_outline, color: Colors.greenAccent, size: 18);
    if (eventType.contains('UPDATED')) return const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 18);
    if (eventType.contains('COMPLETED')) return const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 18);
    if (eventType.contains('ERROR')) return const Icon(Icons.error_outline, color: Colors.redAccent, size: 18);
    return const Icon(Icons.info_outline, color: Colors.white38, size: 18);
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.redAccent;
      case 'warning':
        return Colors.orangeAccent;
      case 'info':
        return Colors.blueAccent;
      default:
        return Colors.white38;
    }
  }
}
