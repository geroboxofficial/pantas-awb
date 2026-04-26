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
  UserProfile? _userProfile;

  // Getters
  List<AWB> get awbs => _awbs;
  List<AWB> get filteredAWBs => _filteredAWBs;
  Map<String, int> get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserProfile? get userProfile => _userProfile;

  // Initialize
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await loadAWBs();
      await loadStatistics();
      await loadUserProfile();
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load User Profile
  Future<void> loadUserProfile() async {
    try {
      _userProfile = await _dbService.getActiveProfile();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load profile: $e';
      notifyListeners();
    }
  }

  // Create or Update Profile with QR Code and vCard
  Future<bool> createProfile(UserProfile profile) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Generate unique user ID if not exists
      final userId = profile.userId ?? QRSecurityService.generateAWBId();
      final vCardData = _generateVCard(profile, userId);
      
      // Create QR data for vCard
      final qrPayload = {
        'userId': userId,
        'name': profile.name,
        'department': profile.department,
        'phone': profile.phone,
        'email': profile.email,
        'address': profile.address,
        'vCard': vCardData,
      };
      
      final secureQR = QRSecurityService.createSecureQRData(qrPayload);
      
      final updatedProfile = UserProfile(
        id: profile.id,
        name: profile.name,
        department: profile.department,
        phone: profile.phone,
        email: profile.email,
        address: profile.address,
        qrCode: secureQR['qrContent'],
        vCardData: vCardData,
        userId: userId,
        isActive: profile.isActive,
        createdAt: profile.createdAt,
        updatedAt: DateTime.now(),
      );

      if (profile.id == null) {
        await _dbService.insertProfile(updatedProfile);
        await _dbService.logSecurityEvent(
          'PROFILE_CREATED',
          'User profile created for ${profile.name} (ID: $userId)',
          'info',
        );
      } else {
        await _dbService.updateProfile(updatedProfile);
        await _dbService.logSecurityEvent(
          'PROFILE_UPDATED',
          'User profile updated for ${profile.name}',
          'info',
        );
      }
      
      _userProfile = updatedProfile;
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create/update profile: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Generate vCard format data
  String _generateVCard(UserProfile profile, String userId) {
    final now = DateTime.now();
    final nameParts = profile.name.split(' ');
    final lastName = nameParts.isNotEmpty ? nameParts.last : '';
    final firstName = nameParts.length > 1 ? nameParts.sublist(0, nameParts.length - 1).join(' ') : '';
    
    return '''BEGIN:VCARD
VERSION:3.0
FN:${profile.name}
N:$lastName;$firstName;;;
ORG:${profile.department}
TEL:${profile.phone}
EMAIL:${profile.email}
ADR:;;${profile.address}
UID:$userId
DTSTAMP:${now.toIso8601String()}
END:VCARD''';
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

      // Create QR data with sender's user ID if available
      final qrData = {
        'airwayId': airwayId,
        'type': type,
        'senderName': senderName,
        'senderDepartment': senderDepartment,
        'senderUserId': _userProfile?.userId,
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
      
      // Record initial handover step (created)
      await _dbService.recordHandoverStep(airwayId, 1, now);
      
      await _dbService.logSecurityEvent(
        'AWB_CREATED',
        'AWB $airwayId created by ${senderName}',
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
        
        // Record handover step based on status
        int stepNumber = 1;
        if (newStatus == 'scanned') stepNumber = 2;
        else if (newStatus == 'completed') stepNumber = 3;
        else if (newStatus == 'expired') stepNumber = 4;
        
        await _dbService.recordHandoverStep(airwayId, stepNumber, DateTime.now());
        
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

  // Get handover timeline for AWB
  Future<Map<String, dynamic>?> getHandoverTimeline(String airwayId) async {
    try {
      return await _dbService.getHandoverTimeline(airwayId);
    } catch (e) {
      _error = 'Failed to get handover timeline: $e';
      notifyListeners();
      return null;
    }
  }

  // Record handover step
  Future<void> recordHandoverStep(String airwayId, int stepNumber) async {
    try {
      await _dbService.recordHandoverStep(airwayId, stepNumber, DateTime.now());
      await _dbService.logSecurityEvent(
        'HANDOVER_STEP_$stepNumber',
        'Handover step $stepNumber recorded for AWB $airwayId',
        'info',
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to record handover step: $e';
      notifyListeners();
    }
  }
}
