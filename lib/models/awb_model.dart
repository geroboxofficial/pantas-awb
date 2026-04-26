class AWB {
  final int? id;
  final String airwayId;
  final String type; // A6, 80mm, 58mm
  final String senderName;
  final String senderPhone;
  final String senderDepartment;
  final String recipientName;
  final String recipientAddress;
  final String recipientPhone;
  final String reference;
  final String remarks;
  final String status; // created, scanned, completed, expired
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiresAt;
  final int validityExtensionCount; // 0-2
  final String? qrSignature;

  AWB({
    this.id,
    required this.airwayId,
    required this.type,
    required this.senderName,
    required this.senderPhone,
    required this.senderDepartment,
    required this.recipientName,
    required this.recipientAddress,
    required this.recipientPhone,
    required this.reference,
    required this.remarks,
    this.status = 'created',
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
    this.validityExtensionCount = 0,
    this.qrSignature,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'airway_id': airwayId,
      'type': type,
      'sender_name': senderName,
      'sender_phone': senderPhone,
      'sender_department': senderDepartment,
      'recipient_name': recipientName,
      'recipient_address': recipientAddress,
      'recipient_phone': recipientPhone,
      'reference': reference,
      'remarks': remarks,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'validity_extension_count': validityExtensionCount,
      'qr_signature': qrSignature,
    };
  }

  factory AWB.fromMap(Map<String, dynamic> map) {
    return AWB(
      id: map['id'] as int?,
      airwayId: map['airway_id'] as String,
      type: map['type'] as String,
      senderName: map['sender_name'] as String,
      senderPhone: map['sender_phone'] as String,
      senderDepartment: map['sender_department'] as String,
      recipientName: map['recipient_name'] as String,
      recipientAddress: map['recipient_address'] as String,
      recipientPhone: map['recipient_phone'] as String,
      reference: map['reference'] as String,
      remarks: map['remarks'] as String,
      status: map['status'] as String? ?? 'created',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      expiresAt: DateTime.parse(map['expires_at'] as String),
      validityExtensionCount: map['validity_extension_count'] as int? ?? 0,
      qrSignature: map['qr_signature'] as String?,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get canExtendValidity => validityExtensionCount < 2;
}
