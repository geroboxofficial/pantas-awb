import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantas_awb/providers/awb_provider.dart';
import 'package:pantas_awb/services/pdf_service.dart';
import 'package:intl/intl.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Filter'),
      ),
      body: Consumer<AWBProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by AWB ID, sender, recipient...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.searchAWBs('');
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {});
                        provider.searchAWBs(value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() => _showFilters = !_showFilters);
                            },
                            icon: const Icon(Icons.filter_list),
                            label: const Text('Filters'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _generateReport,
                          icon: const Icon(Icons.file_download),
                          label: const Text('PDF'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Filters
              if (_showFilters)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Filter
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedStatus,
                        hint: const Text('All Status'),
                        items: const [
                          DropdownMenuItem(value: 'created', child: Text('Created')),
                          DropdownMenuItem(value: 'scanned', child: Text('Scanned')),
                          DropdownMenuItem(value: 'completed', child: Text('Completed')),
                          DropdownMenuItem(value: 'expired', child: Text('Expired')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedStatus = value);
                          _applyFilters(context);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Type Filter
                      Text(
                        'Type',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedType,
                        hint: const Text('All Types'),
                        items: const [
                          DropdownMenuItem(value: 'A6', child: Text('A6')),
                          DropdownMenuItem(value: '80mm', child: Text('80mm')),
                          DropdownMenuItem(value: '58mm', child: Text('58mm')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedType = value);
                          _applyFilters(context);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date Range
                      Text(
                        'Date Range',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, true),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _startDate != null
                                      ? DateFormat('yyyy-MM-dd').format(_startDate!)
                                      : 'Start Date',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, false),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _endDate != null
                                      ? DateFormat('yyyy-MM-dd').format(_endDate!)
                                      : 'End Date',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _applyFilters(context),
                          child: const Text('Apply Filters'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

              // Results
              Expanded(
                child: provider.filteredAWBs.isEmpty
                    ? Center(
                        child: Text(
                          'No AWBs found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provider.filteredAWBs.length,
                        itemBuilder: (context, index) {
                          final awb = provider.filteredAWBs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(awb.airwayId),
                              subtitle: Text(
                                '${awb.senderName} → ${awb.recipientName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Chip(
                                label: Text(awb.status),
                                backgroundColor: _getStatusColor(awb.status),
                              ),
                              onTap: () => _showAWBDetails(context, awb),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _applyFilters(BuildContext context) {
    context.read<AWBProvider>().filterAWBs(
      status: _selectedStatus,
      type: _selectedType,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _generateReport() async {
    final provider = context.read<AWBProvider>();
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF report...')),
      );

      final filePath = await PDFService.generateAWBReport(
        provider.filteredAWBs,
        'PANTAS AWB Report',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved: $filePath'),
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
