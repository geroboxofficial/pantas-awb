import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantas_awb/providers/awb_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AWBProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 32),
            const SizedBox(width: 12),
            const Text('PANTAS AWB', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF001F3F),
        foregroundColor: Colors.white,
      ),
      body: Consumer<AWBProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Action Buttons
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.person_add_alt_1,
                      label: 'FASA 1: Profile',
                      color: const Color(0xFF00D9FF),
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.note_add_outlined,
                      label: 'FASA 2: Create AWB',
                      color: Colors.blueAccent,
                      onTap: () => Navigator.pushNamed(context, '/create'),
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.qr_code_scanner,
                      label: 'FASA 3/4: Scan',
                      color: Colors.purpleAccent,
                      onTap: () => Navigator.pushNamed(context, '/scan'),
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.assessment_outlined,
                      label: 'FASA 5: Report',
                      color: Colors.greenAccent,
                      onTap: () => Navigator.pushNamed(context, '/search'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Statistics
                Text(
                  'Statistics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildStatCard(
                      label: 'Total',
                      value: provider.statistics['total'].toString(),
                      color: Colors.blue,
                    ),
                    _buildStatCard(
                      label: 'Active',
                      value: provider.statistics['active'].toString(),
                      color: Colors.green,
                    ),
                    _buildStatCard(
                      label: 'Completed',
                      value: provider.statistics['completed'].toString(),
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent AWBs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent AWBs',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/search'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (provider.awbs.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No AWBs yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/create'),
                            icon: const Icon(Icons.add),
                            label: const Text('Create First AWB'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.awbs.take(5).length,
                    itemBuilder: (context, index) {
                      final awb = provider.awbs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(awb.airwayId),
                          subtitle: Text('${awb.senderName} → ${awb.recipientName}'),
                          trailing: Chip(
                            label: Text(awb.status),
                            backgroundColor: _getStatusColor(awb.status),
                          ),
                          onTap: () {
                            // Show AWB details
                            _showAWBDetails(context, awb);
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'created':
        return Colors.blue;
      case 'scanned':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showAWBDetails(BuildContext context, dynamic awb) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('AWB: ${awb.airwayId}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type', awb.type),
              _buildDetailRow('Sender', awb.senderName),
              _buildDetailRow('Recipient', awb.recipientName),
              _buildDetailRow('Status', awb.status),
              _buildDetailRow('Created', awb.createdAt.toString().split('.')[0]),
              _buildDetailRow('Expires', awb.expiresAt.toString().split('.')[0]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
