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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SEARCH & REPORTS'),
      ),
      body: Consumer<AWBProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Search & Actions Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (v) {
                        setState(() {});
                        provider.searchAWBs(v);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search AWB, Sender, Recipient...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.searchAWBs('');
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => _showFilters = !_showFilters),
                            icon: Icon(_showFilters ? Icons.close_rounded : Icons.tune_rounded, size: 18),
                            label: Text(_showFilters ? 'CLOSE FILTERS' : 'ADVANCED FILTERS'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: _showFilters ? Colors.redAccent.withOpacity(0.5) : colorScheme.primary.withOpacity(0.3)),
                              foregroundColor: _showFilters ? Colors.redAccent : colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 120,
                          child: ElevatedButton.icon(
                            onPressed: _generateReport,
                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                            label: const Text('REPORT'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Filter Panel
              if (_showFilters)
                _buildFilterPanel(context),

              // Results List
              Expanded(
                child: provider.filteredAWBs.isEmpty
                    ? _buildEmptyResults(context)
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: provider.filteredAWBs.length,
                        itemBuilder: (context, index) {
                          final awb = provider.filteredAWBs[index];
                          return _buildAWBCard(context, awb);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterPanel(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdownFilter(
                  label: 'Status',
                  value: _selectedStatus,
                  items: ['created', 'scanned', 'completed', 'expired'],
                  onChanged: (v) {
                    setState(() => _selectedStatus = v);
                    _applyFilters(context);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownFilter(
                  label: 'Type',
                  value: _selectedType,
                  items: ['A6', '80mm', '58mm'],
                  onChanged: (v) {
                    setState(() => _selectedType = v);
                    _applyFilters(context);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDatePicker(context, true)),
              const SizedBox(width: 16),
              Expanded(child: _buildDatePicker(context, false)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _selectedStatus = null;
                  _selectedType = null;
                  _startDate = null;
                  _endDate = null;
                });
                _applyFilters(context);
              },
              child: const Text('RESET ALL FILTERS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        DropdownButton<String>(
          isExpanded: true,
          value: value,
          underline: Container(height: 1, color: Colors.white10),
          hint: const Text('All', style: TextStyle(fontSize: 12)),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase(), style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context, bool isStart) {
    final date = isStart ? _startDate : _endDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isStart ? 'START DATE' : 'END DATE', style: const TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _selectDate(context, isStart),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null ? DateFormat('dd/MM/yy').format(date) : '--/--/--',
                  style: const TextStyle(fontSize: 12),
                ),
                const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAWBCard(BuildContext context, dynamic awb) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF00D9FF)),
        ),
        title: Text(awb.airwayId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('${awb.senderName} → ${awb.recipientName}', style: const TextStyle(fontSize: 12, color: Colors.white54)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(awb.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getStatusColor(awb.status).withOpacity(0.3)),
          ),
          child: Text(
            awb.status.toUpperCase(),
            style: TextStyle(color: _getStatusColor(awb.status), fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        onTap: () => _showAWBDetails(context, awb),
      ),
    );
  }

  Widget _buildEmptyResults(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 16),
          const Text('No records found matching criteria', style: TextStyle(color: Colors.white24)),
        ],
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

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: const Color(0xFF00D9FF)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
      _applyFilters(context);
    }
  }

  Future<void> _generateReport() async {
    final provider = context.read<AWBProvider>();
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compiling secure report...')));
      final path = await PDFService.generateAWBReport(provider.filteredAWBs, 'PANTAS_REPORT_${DateTime.now().millisecondsSinceEpoch}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report generated: $path'), backgroundColor: Colors.greenAccent));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'created': return const Color(0xFF00D9FF);
      case 'scanned': return Colors.orangeAccent;
      case 'completed': return Colors.greenAccent;
      case 'expired': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  void _showAWBDetails(BuildContext context, dynamic awb) {
    // Reusing the same detail view logic as HomeScreen or navigating to a dedicated detail screen
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TRANSACTION DETAILS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(awb.airwayId, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF00D9FF))),
            const Divider(height: 40, color: Colors.white10),
            Expanded(
              child: ListView(
                children: [
                  _buildDetailItem('Status', awb.status.toUpperCase()),
                  _buildDetailItem('Sender', awb.senderName),
                  _buildDetailItem('Recipient', awb.recipientName),
                  _buildDetailItem('Type', awb.type),
                  _buildDetailItem('Created', awb.createdAt.toString()),
                  _buildDetailItem('Expires', awb.expiresAt.toString()),
                ],
              ),
            ),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE'))),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
