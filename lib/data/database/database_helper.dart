import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:netvigilant/data/database/database_entities.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'netvigilant.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create app usage records table
    await db.execute('''
      CREATE TABLE app_usage_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        packageName TEXT NOT NULL,
        appName TEXT NOT NULL,
        networkUsage REAL NOT NULL DEFAULT 0.0,
        totalTimeInForeground INTEGER NOT NULL DEFAULT 0,
        cpuUsage REAL NOT NULL DEFAULT 0.0,
        memoryUsage REAL NOT NULL DEFAULT 0.0,
        batteryUsage REAL NOT NULL DEFAULT 0.0,
        launchCount INTEGER NOT NULL DEFAULT 0,
        lastTimeUsed INTEGER NOT NULL,
        recordDate INTEGER NOT NULL,
        UNIQUE(packageName, recordDate)
      )
    ''');

    // Create network traffic records table
    await db.execute('''
      CREATE TABLE network_traffic_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        packageName TEXT NOT NULL,
        appName TEXT NOT NULL,
        uid INTEGER NOT NULL,
        rxBytes INTEGER NOT NULL DEFAULT 0,
        txBytes INTEGER NOT NULL DEFAULT 0,
        timestamp INTEGER NOT NULL,
        networkType TEXT NOT NULL,
        isBackgroundTraffic INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create real-time metrics table
    await db.execute('''
      CREATE TABLE realtime_metrics_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uplinkSpeed REAL NOT NULL DEFAULT 0.0,
        downlinkSpeed REAL NOT NULL DEFAULT 0.0,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Create daily summary table
    await db.execute('''
      CREATE TABLE daily_summary_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL UNIQUE,
        totalDataUsage REAL NOT NULL DEFAULT 0.0,
        activeAppsCount INTEGER NOT NULL DEFAULT 0,
        peakDownloadSpeed REAL NOT NULL DEFAULT 0.0,
        peakUploadSpeed REAL NOT NULL DEFAULT 0.0,
        totalForegroundTime INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create indices for better performance
    await db.execute('CREATE INDEX idx_app_usage_date ON app_usage_records(recordDate)');
    await db.execute('CREATE INDEX idx_app_usage_package ON app_usage_records(packageName)');
    await db.execute('CREATE INDEX idx_network_traffic_timestamp ON network_traffic_records(timestamp)');
    await db.execute('CREATE INDEX idx_network_traffic_package ON network_traffic_records(packageName)');
    await db.execute('CREATE INDEX idx_realtime_metrics_timestamp ON realtime_metrics_records(timestamp)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < newVersion) {
      // Add migration logic as needed
    }
  }

  // App Usage Records
  Future<int> insertAppUsageRecord(AppUsageRecord record) async {
    final db = await database;
    return await db.insert('app_usage_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<AppUsageRecord>> getAppUsageRecords({
    DateTime? startDate,
    DateTime? endDate,
    String? packageName,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += 'recordDate >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'recordDate <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    if (packageName != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'packageName = ?';
      whereArgs.add(packageName);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'app_usage_records',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'recordDate DESC',
    );

    return maps.map((map) => AppUsageRecord.fromMap(map)).toList();
  }

  Future<AppUsageRecord?> getLatestAppUsageRecord(String packageName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'app_usage_records',
      where: 'packageName = ?',
      whereArgs: [packageName],
      orderBy: 'recordDate DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return AppUsageRecord.fromMap(maps.first);
    }
    return null;
  }

  // Network Traffic Records
  Future<int> insertNetworkTrafficRecord(NetworkTrafficRecord record) async {
    final db = await database;
    return await db.insert('network_traffic_records', record.toMap());
  }

  Future<List<NetworkTrafficRecord>> getNetworkTrafficRecords({
    DateTime? startDate,
    DateTime? endDate,
    String? packageName,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += 'timestamp >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'timestamp <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    if (packageName != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'packageName = ?';
      whereArgs.add(packageName);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'network_traffic_records',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => NetworkTrafficRecord.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getAllNetworkTrafficRaw() async {
    final db = await database;
    return await db.query('network_traffic_records', orderBy: 'timestamp ASC');
  }

  Future<List<Map<String, dynamic>>> getAggregatedNetworkUsageByUidRaw({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += 'timestamp >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'timestamp <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    return await db.rawQuery('''
      SELECT uid, packageName, appName, SUM(rxBytes) as totalRxBytes, SUM(txBytes) as totalTxBytes
      FROM network_traffic_records
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      GROUP BY uid, packageName, appName
    ''', whereArgs.isEmpty ? [] : whereArgs);
  }

  // Real-time Metrics Records
  Future<int> insertRealTimeMetricsRecord(RealTimeMetricsRecord record) async {
    final db = await database;
    return await db.insert('realtime_metrics_records', record.toMap());
  }

  Future<List<RealTimeMetricsRecord>> getRealTimeMetricsRecords({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += 'timestamp >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'timestamp <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'realtime_metrics_records',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => RealTimeMetricsRecord.fromMap(map)).toList();
  }

  // Daily Summary Records
  Future<int> insertOrUpdateDailySummary(DailySummaryRecord record) async {
    final db = await database;
    return await db.insert('daily_summary_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<DailySummaryRecord>> getDailySummaryRecords({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += 'date >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'daily_summary_records',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC',
    );

    return maps.map((map) => DailySummaryRecord.fromMap(map)).toList();
  }

  Future<DailySummaryRecord?> getDailySummaryForDate(DateTime date) async {
    final db = await database;
    final dayStart = DateTime(date.year, date.month, date.day);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_summary_records',
      where: 'date = ?',
      whereArgs: [dayStart.millisecondsSinceEpoch],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return DailySummaryRecord.fromMap(maps.first);
    }
    return null;
  }

  // Utility methods
  Future<Map<String, double>> getTotalDataUsageByApp({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += 'timestamp >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'timestamp <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT packageName, SUM(rxBytes + txBytes) as totalBytes
      FROM network_traffic_records
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      GROUP BY packageName
      ORDER BY totalBytes DESC
    ''', whereArgs.isEmpty ? [] : whereArgs);

    return Map.fromEntries(
      maps.map((map) => MapEntry(
        map['packageName'] as String,
        (map['totalBytes'] as num).toDouble(),
      )),
    );
  }

  Future<double> getPeakSpeedInPeriod({
    DateTime? startDate,
    DateTime? endDate,
    bool isDownload = true,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += 'timestamp >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'timestamp <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final speedColumn = isDownload ? 'downlinkSpeed' : 'uplinkSpeed';
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT MAX($speedColumn) as maxSpeed
      FROM realtime_metrics_records
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
    ''', whereArgs.isEmpty ? [] : whereArgs);

    if (maps.isNotEmpty && maps.first['maxSpeed'] != null) {
      return (maps.first['maxSpeed'] as num).toDouble();
    }
    return 0.0;
  }

  // Data cleanup methods
  Future<int> deleteOldRecords(String table, int daysToKeep) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    
    String timestampColumn;
    switch (table) {
      case 'app_usage_records':
        timestampColumn = 'recordDate';
        break;
      case 'network_traffic_records':
      case 'realtime_metrics_records':
        timestampColumn = 'timestamp';
        break;
      case 'daily_summary_records':
        timestampColumn = 'date';
        break;
      default:
        throw ArgumentError('Invalid table name: $table');
    }

    return await db.delete(
      table,
      where: '$timestampColumn < ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
    );
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('app_usage_records');
    await db.delete('network_traffic_records');
    await db.delete('realtime_metrics_records');
    await db.delete('daily_summary_records');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Specific cleanup methods for background service
  Future<void> deleteRealTimeMetricsOlderThan(DateTime cutoffDate) async {
    final db = await database;
    await db.delete(
      'realtime_metrics_records',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
    );
  }

  Future<int> deleteAppUsageRecordsOlderThan(DateTime cutoffDate) async {
    final db = await database;
    return await db.delete(
      'app_usage_records',
      where: 'recordDate < ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
    );
  }

  Future<int> deleteNetworkTrafficOlderThan(DateTime cutoffDate) async {
    final db = await database;
    return await db.delete(
      'network_traffic_records',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
    );
  }

  Future<int> deleteDailySummariesOlderThan(DateTime cutoffDate) async {
    final db = await database;
    return await db.delete(
      'daily_summary_records',
      where: 'date < ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
    );
  }
}