import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:pantas_awb/providers/awb_provider.dart';
import 'package:pantas_awb/services/qr_security_service.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_off),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.camera_rear),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _handleDetection,
          ),
          // Overlay
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.green,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Position QR code within frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _isProcessing = true;
        _processQRCode(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _processQRCode(String qrContent) async {
    try {
      // Verify QR signature
      final result = QRSecurityService.verifyAndExtractQRData(qrContent);

      if (!result['valid']) {
        if (mounted) {
          _showErrorDialog(result['error'] ?? 'Invalid QR code');
        }
        _isProcessing = false;
        return;
      }

      final data = result['data'] as Map<String, dynamic>;
      final airwayId = data['airwayId'] as String?;

      if (airwayId == null) {
        if (mounted) {
          _showErrorDialog('Invalid AWB ID in QR code');
        }
        _isProcessing = false;
        return;
      }

      // Get AWB from database
      final provider = context.read<AWBProvider>();
      final awb = await provider.awbs.isEmpty
          ? null
          : provider.awbs
              .where((a) => a.airwayId == airwayId)
              .firstOrNull;

      if (awb == null) {
        if (mounted) {
          _showErrorDialog('AWB not found: $airwayId');
        }
        _isProcessing = false;
        return;
      }

      // Show handover confirmation
      if (mounted) {
        _showHandoverDialog(awb);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error: $e');
      }
    } finally {
      _isProcessing = false;
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHandoverDialog(dynamic awb) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Handover'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('AWB Details:'),
              const SizedBox(height: 12),
              _buildDetailRow('AWB ID', awb.airwayId),
              _buildDetailRow('Sender', awb.senderName),
              _buildDetailRow('Recipient', awb.recipientName),
              _buildDetailRow('Status', awb.status),
              const SizedBox(height: 16),
              const Text('Confirm handover to recipient?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _completeHandover(awb);
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeHandover(dynamic awb) async {
    try {
      final provider = context.read<AWBProvider>();
      
      // Update status to scanned first
      await provider.updateAWBStatus(awb.airwayId, 'scanned');

      // Record handover timestamp
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Handover recorded successfully'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
