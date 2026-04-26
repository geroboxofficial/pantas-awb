import 'package:crypto/crypto.dart';
import 'dart:convert';

class QRSecurityService {
  static const String _secretKey = 'PANTAS_AWB_SECURITY_KEY_2026';

  /// Generate HMAC-SHA256 signature for QR data
  static String generateHMACSignature(String payload) {
    return Hmac(sha256, utf8.encode(_secretKey))
        .convert(utf8.encode(payload))
        .toString();
  }

  /// Verify HMAC signature
  static bool verifyHMACSignature(String payload, String signature) {
    final expectedSignature = generateHMACSignature(payload);
    return expectedSignature == signature;
  }

  /// Create secure QR data with signature
  static Map<String, String> createSecureQRData(Map<String, dynamic> data) {
    final payload = jsonEncode(data);
    final signature = generateHMACSignature(payload);

    final qrData = {
      'v': '2', // Version
      'alg': 'HmacSHA256', // Algorithm
      'payload': payload,
      'sig': signature,
    };

    final qrContent = jsonEncode(qrData);
    return {
      'qrContent': qrContent,
      'signature': signature,
      'payload': payload,
    };
  }

  /// Verify and extract QR data
  static Map<String, dynamic> verifyAndExtractQRData(String qrContent) {
    try {
      final decoded = jsonDecode(qrContent) as Map<String, dynamic>;

      final version = decoded['v'] as String?;
      final algorithm = decoded['alg'] as String?;
      final payload = decoded['payload'] as String?;
      final signature = decoded['sig'] as String?;

      if (version == null || algorithm == null || payload == null || signature == null) {
        return {
          'valid': false,
          'error': 'Invalid QR format: missing required fields',
        };
      }

      if (algorithm != 'HmacSHA256') {
        return {
          'valid': false,
          'error': 'Unsupported algorithm: $algorithm',
        };
      }

      if (!verifyHMACSignature(payload, signature)) {
        return {
          'valid': false,
          'error': 'Invalid signature: QR code may have been tampered',
        };
      }

      final data = jsonDecode(payload);
      return {
        'valid': true,
        'data': data,
      };
    } catch (e) {
      return {
        'valid': false,
        'error': 'Failed to parse QR data: $e',
      };
    }
  }

  /// Generate unique AWB ID with timestamp
  static String generateAWBId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond % 10000;
    return 'AWB${timestamp}${random.toString().padLeft(4, '0')}';
  }

  /// Hash sensitive data
  static String hashData(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  /// Encrypt password for backup (simple XOR for demo, use proper encryption in production)
  static String encryptPassword(String password) {
    // In production, use proper encryption like AES
    return base64.encode(utf8.encode(password));
  }

  /// Decrypt password from backup
  static String decryptPassword(String encrypted) {
    try {
      return utf8.decode(base64.decode(encrypted));
    } catch (e) {
      throw Exception('Failed to decrypt password: $e');
    }
  }
}
