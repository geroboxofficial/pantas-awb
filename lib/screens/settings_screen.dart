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
                  subtitle: 'View system event history',
                  onTap: () => setState(() => _showAuditLog = !_showAuditLog),
                  trailing: Icon(_showAuditLog ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                ),
                if (_showAuditLog) _buildAuditLogList(provider),
                
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
                      _buildInfoRow('Version', '1.0.0+PRO'),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                        ),
                        child: const Text(
                          'Developed with professional standards for secure and reliable handover management.',
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
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length.clamp(0, 10),
          itemBuilder: (context, index) {
            final log = snapshot.data![index];
            return Card(
              margin: const EdgeInsets.only(top: 8),
              color: Colors.white.withOpacity(0.02),
              child: ListTile(
                dense: true,
                title: Text(log['event_type'] ?? 'EVENT', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                subtitle: Text(log['event_description'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.white54)),
                trailing: Text(
                  log['created_at'].toString().split('T')[0],
                  style: const TextStyle(fontSize: 9, color: Colors.white24),
                ),
              ),
            );
          },
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
}
