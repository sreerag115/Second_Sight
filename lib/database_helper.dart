import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('users.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE,
        password TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE detection_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        createdAt INTEGER NOT NULL,
        type TEXT NOT NULL,
        obstacleCount INTEGER NOT NULL DEFAULT 0,
        personDetected INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE detection_events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          createdAt INTEGER NOT NULL,
          type TEXT NOT NULL,
          obstacleCount INTEGER NOT NULL DEFAULT 0,
          personDetected INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
  }

  // Hash password
  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> registerUser(String email, String password) async {
    final db = await instance.database;

    final hashed = hashPassword(password);

    await db.insert(
      'users',
      {
        'email': email,
        'password': hashed,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<bool> loginUser(String email, String password) async {
    final db = await instance.database;

    final hashed = hashPassword(password);

    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashed],
    );

    return result.isNotEmpty;
  }

  Future<void> logDetectionEvent({
    required String type, // e.g. "alert"
    required int obstacleCount,
    required bool personDetected,
    DateTime? createdAt,
  }) async {
    final db = await instance.database;
    final ts = (createdAt ?? DateTime.now()).millisecondsSinceEpoch;
    await db.insert(
      'detection_events',
      {
        'createdAt': ts,
        'type': type,
        'obstacleCount': obstacleCount,
        'personDetected': personDetected ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await instance.database;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day)
        .millisecondsSinceEpoch;

    final alertsTodayResult = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM detection_events WHERE type = ? AND createdAt >= ?',
      ['alert', startOfDay],
    );
    final obstaclesTodayResult = await db.rawQuery(
      'SELECT COALESCE(SUM(obstacleCount), 0) as sum FROM detection_events WHERE type = ? AND createdAt >= ?',
      ['alert', startOfDay],
    );
    final lastAlertResult = await db.rawQuery(
      'SELECT createdAt FROM detection_events WHERE type = ? ORDER BY createdAt DESC LIMIT 1',
      ['alert'],
    );

    final alertsToday = (alertsTodayResult.first['cnt'] as int?) ?? 0;
    final obstaclesToday = (obstaclesTodayResult.first['sum'] as int?) ?? 0;
    final lastAlertAt = lastAlertResult.isEmpty
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            (lastAlertResult.first['createdAt'] as int?) ?? 0,
          );

    return {
      'alertsToday': alertsToday,
      'obstaclesToday': obstaclesToday,
      'lastAlertAt': lastAlertAt,
    };
  }
}