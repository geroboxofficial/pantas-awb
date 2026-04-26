import 'package:flutter/material.dart';
import 'package:pantas_awb/models/awb_model.dart';
import 'package:pantas_awb/services/database_service.dart';
import 'package:pantas_awb/services/qr_security_service.dart';

class AWBProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<AWB> _awbs = [];
  List<AWB> _filteredAWBs = [];
  Map<String, int> _statistics = {
    'total': 0,
    'active': 0,
    'completed': 0,
    'expired': 0,
  };
  bool _isLoading = false;
  String? _error;

  // Getters
  List<AWB> get awbs => _awbs;
  List<AWB> get filteredAWBs => _filteredAWBs;
  Map<String, int> get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await loadAWBs();
      await loadStatistics();
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load all AWBs
  Future<void> loadAWBs() async {
    try {
      _awbs = await _dbService.getAllAWBs();
      _filteredAWBs = _awbs;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load AWBs: $e';
      notifyListeners();
    }
  }

  // Create new AWB
  Future<bool> createAWB({
    required String type,
    required String senderName,
    required String senderPhone,
    required String senderDepartment,
    required String recipientName,
    required String recipientAddress,
    required String recipientPhone,
    required String reference,
    required String remarks,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final airwayId = QRSecurityService.generateAWBId();
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 7));

      // Create QR data
      final qrData = {
        'airwayId': airwayId,
        'type': type,
        'senderName': senderName,
        'recipientName': recipientName,
        'createdAt': now.toIso8601String(),
      };

      final secureQR = QRSecurityService.createSecureQRData(qrData);

      final awb = AWB(
        airwayId: airwayId,
        type: type,
        senderName: senderName,
        senderPhone: senderPhone,
        senderDepartment: senderDepartment,
        recipientName: recipientName,
        recipientAddress: recipientAddress,
        recipientPhone: recipientPhone,
        reference: reference,
        remarks: remarks,
        createdAt: now,
        updatedAt: now,
        expiresAt: expiresAt,
        qrSignature: secureQR['signature'],
      );

      await _dbService.insertAWB(awb);
      await _dbService.logSecurityEvent(
        'AWB_CREATED',
        'AWB $airwayId created',
        'info',
      );

      await loadAWBs();
      await loadStatistics();
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create AWB: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Search AWBs
  Future<void> searchAWBs(String query) async {
    try {
      if (query.isEmpty) {
        _filteredAWBs = _awbs;
      } else {
        _filteredAWBs = await _dbService.searchAWBs(query);
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Search failed: $e';
      notifyListeners();
    }
  }

  // Filter AWBs
  Future<void> filterAWBs({
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _filteredAWBs = await _dbService.filterAWBs(
        status: status,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Filter failed: $e';
      notifyListeners();
    }
  }

  // Update AWB status
  Future<bool> updateAWBStatus(String airwayId, String newStatus) async {
    try {
      final awb = await _dbService.getAWBById(airwayId);
      if (awb != null) {
        final updatedAWB = AWB(
          id: awb.id,
          airwayId: awb.airwayId,
          type: awb.type,
          senderName: awb.senderName,
          senderPhone: awb.senderPhone,
          senderDepartment: awb.senderDepartment,
          recipientName: awb.recipientName,
          recipientAddress: awb.recipientAddress,
          recipientPhone: awb.recipientPhone,
          reference: awb.reference,
          remarks: awb.remarks,
          status: newStatus,
          createdAt: awb.createdAt,
          updatedAt: DateTime.now(),
          expiresAt: awb.expiresAt,
          validityExtensionCount: awb.validityExtensionCount,
          qrSignature: awb.qrSignature,
        );

        await _dbService.updateAWB(updatedAWB);
        await _dbService.logSecurityEvent(
          'AWB_STATUS_UPDATED',
          'AWB $airwayId status changed to $newStatus',
          'info',
        );

        await loadAWBs();
        _error = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to update status: $e';
      notifyListeners();
      return false;
    }
  }

  // Extend validity
  Future<bool> extendValidity(String airwayId) async {
    try {
      final awb = await _dbService.getAWBById(airwayId);
      if (awb != null && awb.canExtendValidity) {
        final updatedAWB = AWB(
          id: awb.id,
          airwayId: awb.airwayId,
          type: awb.type,
          senderName: awb.senderName,
          senderPhone: awb.senderPhone,
          senderDepartment: awb.senderDepartment,
          recipientName: awb.recipientName,
          recipientAddress: awb.recipientAddress,
          recipientPhone: awb.recipientPhone,
          reference: awb.reference,
          remarks: awb.remarks,
          status: awb.status,
          createdAt: awb.createdAt,
          updatedAt: DateTime.now(),
          expiresAt: awb.expiresAt.add(const Duration(days: 7)),
          validityExtensionCount: awb.validityExtensionCount + 1,
          qrSignature: awb.qrSignature,
        );

        await _dbService.updateAWB(updatedAWB);
        await _dbService.logSecurityEvent(
          'AWB_VALIDITY_EXTENDED',
          'AWB $airwayId validity extended (${updatedAWB.validityExtensionCount}/2)',
          'info',
        );

        await loadAWBs();
        _error = null;
        notifyListeners();
        return true;
      }
      _error = 'Cannot extend validity: maximum extensions reached or AWB not found';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to extend validity: $e';
      notifyListeners();
      return false;
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    try {
      _statistics = await _dbService.getStatistics();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load statistics: $e';
      notifyListeners();
    }
  }

  // Check expired AWBs
  Future<void> checkExpiredAWBs() async {
    try {
      for (var awb in _awbs) {
        if (awb.isExpired && awb.status != 'expired') {
          await updateAWBStatus(awb.airwayId, 'expired');
        }
      }
      await loadStatistics();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to check expired AWBs: $e';
      notifyListeners();
    }
  }

  // Get audit logs
  Future<List<Map<String, dynamic>>> getAuditLogs() async {
    try {
      return await _dbService.getAuditLogs();
    } catch (e) {
      _error = 'Failed to get audit logs: $e';
      notifyListeners();
      return [];
    }
  }
}
