import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pantas_awb/models/awb_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pantas_awb.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Airway Bills Table
    await db.execute('''
      CREATE TABLE airway_bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        airway_id TEXT UNIQUE NOT NULL,
        type TEXT NOT NULL,
        sender_name TEXT NOT NULL,
        sender_phone TEXT,
        sender_department TEXT,
        recipient_name TEXT NOT NULL,
        recipient_address TEXT,
        recipient_phone TEXT,
        reference TEXT,
        remarks TEXT,
        status TEXT DEFAULT 'created',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        validity_extension_count INTEGER DEFAULT 0,
        qr_signature TEXT
      )
    ''');

    // User Profiles Table
    await db.execute('''
      CREATE TABLE user_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_name TEXT NOT NULL,
        profile_type TEXT,
        department TEXT,
        phone TEXT,
        address TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Security Audit Log Table
    await db.execute('''
      CREATE TABLE security_audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_type TEXT NOT NULL,
        event_description TEXT,
        severity TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Handover Records Table
    await db.execute('''
      CREATE TABLE handover_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        airway_id TEXT NOT NULL,
        timestamp1 TEXT,
        timestamp2 TEXT,
        timestamp3 TEXT,
        timestamp4 TEXT,
        timestamp5 TEXT,
        timestamp6 TEXT,
        timestamp7 TEXT,
        timestamp8 TEXT,
        timestamp9 TEXT,
        timestamp10 TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(airway_id) REFERENCES airway_bills(airway_id)
      )
    ''');

    // Backup Metadata Table
    await db.execute('''
      CREATE TABLE backup_metadata (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        backup_name TEXT NOT NULL,
        backup_date TEXT NOT NULL,
        file_path TEXT,
        file_size INTEGER,
        is_encrypted INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better search performance
    await db.execute('CREATE INDEX idx_airway_id ON airway_bills(airway_id)');
    await db.execute('CREATE INDEX idx_status ON airway_bills(status)');
    await db.execute('CREATE INDEX idx_expires_at ON airway_bills(expires_at)');
  }

  // AWB Operations
  Future<int> insertAWB(AWB awb) async {
    final db = await database;
    return await db.insert('airway_bills', awb.toMap());
  }

  Future<List<AWB>> getAllAWBs() async {
    final db = await database;
    final maps = await db.query('airway_bills', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) => AWB.fromMap(maps[i]));
  }

  Future<AWB?> getAWBById(String airwayId) async {
    final db = await database;
    final maps = await db.query(
      'airway_bills',
      where: 'airway_id = ?',
      whereArgs: [airwayId],
    );
    if (maps.isNotEmpty) {
      return AWB.fromMap(maps.first);
    }
    return null;
  }

  Future<List<AWB>> searchAWBs(String query) async {
    final db = await database;
    final maps = await db.query(
      'airway_bills',
      where: '''
        airway_id LIKE ? OR 
        sender_name LIKE ? OR 
        recipient_name LIKE ? OR 
        reference LIKE ? OR
        remarks LIKE ?
      ''',
      whereArgs: [
        '%$query%',
        '%$query%',
        '%$query%',
        '%$query%',
        '%$query%',
      ],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => AWB.fromMap(maps[i]));
  }

  Future<List<AWB>> filterAWBs({
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (status != null) {
      where += 'status = ?';
      whereArgs.add(status);
    }

    if (type != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'type = ?';
      whereArgs.add(type);
    }

    if (startDate != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'created_at >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'created_at <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final maps = await db.query(
      'airway_bills',
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) => AWB.fromMap(maps[i]));
  }

  Future<int> updateAWB(AWB awb) async {
    final db = await database;
    return await db.update(
      'airway_bills',
      awb.toMap(),
      where: 'id = ?',
      whereArgs: [awb.id],
    );
  }

  Future<int> deleteAWB(int id) async {
    final db = await database;
    return await db.delete(
      'airway_bills',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Audit Log Operations
  Future<void> logSecurityEvent(
    String eventType,
    String? description,
    String severity,
  ) async {
    final db = await database;
    await db.insert('security_audit_logs', {
      'event_type': eventType,
      'event_description': description,
      'severity': severity,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAuditLogs({int limit = 50}) async {
    final db = await database;
    return await db.query(
      'security_audit_logs',
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  // Handover Operations
  Future<void> recordHandoverStep(String airwayId, int stepNumber, DateTime timestamp) async {
    final db = await database;
    final existing = await db.query(
      'handover_records',
      where: 'airway_id = ?',
      whereArgs: [airwayId],
    );

    if (existing.isEmpty) {
      await db.insert('handover_records', {
        'airway_id': airwayId,
        'timestamp$stepNumber': timestamp.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      await db.update(
        'handover_records',
        {'timestamp$stepNumber': timestamp.toIso8601String()},
        where: 'airway_id = ?',
        whereArgs: [airwayId],
      );
    }
  }

  // Backup Operations
  Future<void> saveBackupMetadata(
    String backupName,
    String filePath,
    int fileSize,
  ) async {
    final db = await database;
    await db.insert('backup_metadata', {
      'backup_name': backupName,
      'backup_date': DateTime.now().toIso8601String(),
      'file_path': filePath,
      'file_size': fileSize,
      'is_encrypted': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getBackupMetadata() async {
    final db = await database;
    return await db.query(
      'backup_metadata',
      orderBy: 'backup_date DESC',
    );
  }

  // Statistics
  Future<Map<String, int>> getStatistics() async {
    final db = await database;
    
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM airway_bills');
    final total = (totalResult.first['count'] as int?) ?? 0;

    final activeResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM airway_bills WHERE status = ?',
      ['created'],
    );
    final active = (activeResult.first['count'] as int?) ?? 0;

    final completedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM airway_bills WHERE status = ?',
      ['completed'],
    );
    final completed = (completedResult.first['count'] as int?) ?? 0;

    return {
      'total': total,
      'active': active,
      'completed': completed,
      'expired': total - active - completed,
    };
  }

  // Close database
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
