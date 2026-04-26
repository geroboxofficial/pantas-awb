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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('SECURE SCANNER'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off_rounded, color: Colors.white54);
                  case TorchState.on:
                    return const Icon(Icons.flash_on_rounded, color: Color(0xFF00D9FF));
                  default:
                    return const Icon(Icons.flash_off_rounded, color: Colors.white54);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white54),
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
          // Futuristic Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black.withOpacity(0.5), width: 40),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF00D9FF).withOpacity(0.5), width: 2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                      children: [
                        _buildCorner(0, null, top: true, isLeft: true),
                        _buildCorner(null, 0, top: true, isRight: true),
                        _buildCorner(0, null, bottom: true, isLeft: true),
                        _buildCorner(null, 0, bottom: true, isRight: true),
                        Center(
                          child: Container(
                            width: 200,
                            height: 1,
                            color: const Color(0xFF00D9FF).withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Text(
                      'ALIGN QR CODE WITHIN FRAME',
                      style: TextStyle(color: Color(0xFF00D9FF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Text(
                      'ENCRYPTED HANDOVER PROTOCOL v1.0',
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 8, letterSpacing: 2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Color(0xFF00D9FF))),
            ),
        ],
      ),
    );
  }

  Widget _buildCorner(double? left, double? right, {bool top = false, bool bottom = false, bool isLeft = false, bool isRight = false}) {
    return Positioned(
      top: top ? 0 : null,
      bottom: bottom ? 0 : null,
      left: left,
      right: right,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: top ? const BorderSide(color: Color(0xFF00D9FF), width: 4) : BorderSide.none,
            bottom: bottom ? const BorderSide(color: Color(0xFF00D9FF), width: 4) : BorderSide.none,
            left: isLeft ? const BorderSide(color: Color(0xFF00D9FF), width: 4) : BorderSide.none,
            right: isRight ? const BorderSide(color: Color(0xFF00D9FF), width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isProcessing = true);
        _processQRCode(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _processQRCode(String qrContent) async {
    try {
      final result = QRSecurityService.verifyAndExtractQRData(qrContent);
      if (!result['valid']) {
        _showStatusSheet(false, result['error'] ?? 'Invalid Security Signature');
        return;
      }

      final data = result['data'] as Map<String, dynamic>;
      final airwayId = data['airwayId'] as String?;
      final provider = context.read<AWBProvider>();
      
      // Look for AWB in provider
      final awb = provider.awbs.where((a) => a.airwayId == airwayId).firstOrNull;
      
      if (awb == null) {
        _showStatusSheet(false, 'Consignment record not found in local database');
        return;
      }

      _showHandoverSheet(awb);
    } catch (e) {
      _showStatusSheet(false, 'System Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showStatusSheet(bool success, String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Color(0xFF001F3F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(success ? Icons.check_circle_rounded : Icons.error_rounded, size: 64, color: success ? Colors.greenAccent : Colors.redAccent),
            const SizedBox(height: 24),
            Text(success ? 'VERIFIED' : 'ERROR', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('DISMISS'))),
          ],
        ),
      ),
    );
  }

  void _showHandoverSheet(dynamic awb) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Color(0xFF001F3F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CONSIGNMENT VERIFIED', style: TextStyle(color: Color(0xFF00D9FF), fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(awb.airwayId, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const Divider(height: 40, color: Colors.white10),
            _buildInfoRow('Sender', awb.senderName),
            _buildInfoRow('Recipient', awb.recipientName),
            _buildInfoRow('Current Status', awb.status.toUpperCase()),
            const SizedBox(height: 32),
            const Text('CONFIRM HANDOVER TRANSACTION?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL'))),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _completeHandover(awb);
                      Navigator.pop(context);
                    },
                    child: const Text('CONFIRM'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _completeHandover(dynamic awb) async {
    final provider = context.read<AWBProvider>();
    final success = await provider.updateAWBStatus(awb.airwayId, 'completed');
    if (mounted) {
      _showStatusSheet(success, success ? 'Handover transaction completed and logged.' : 'Failed to update transaction status.');
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
