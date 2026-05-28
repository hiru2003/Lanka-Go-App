import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';

class SqliteService {
  static Database? _database;

  /// Closes the database and resets the static database reference.
  /// Used to prevent test pollution.
  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'lankago_cache.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Table for offline queued transactions
        await db.execute('''
          CREATE TABLE offline_transactions(
            id TEXT PRIMARY KEY,
            user_id TEXT,
            type TEXT,
            amount REAL,
            timestamp TEXT,
            route TEXT,
            bus_id TEXT,
            is_offline INTEGER,
            is_synced INTEGER
          )
        ''');

        // Table for cached user balances
        await db.execute('''
          CREATE TABLE cached_user(
            id TEXT PRIMARY KEY,
            balance REAL
          )
        ''');
      },
    );
  }

  /// Retrieves the current count of queued unsynced transactions in local SQLite
  Future<int> getUnsyncedCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM offline_transactions WHERE is_synced = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Inserts an offline transaction, enforcing the LKR 500 transaction cap limit
  Future<void> queueOfflineTransaction(TransactionModel tx) async {
    final db = await database;
    
    // Check 500 limit
    final count = await getUnsyncedCount();
    if (count >= 500) {
      throw Exception('SQLite Cache limit reached (500 maximum offline transactions exceeded). Please connect to sync.');
    }

    await db.insert(
      'offline_transactions',
      tx.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Update locally cached balance
    await db.rawUpdate(
      'UPDATE cached_user SET balance = balance + ? WHERE id = ?',
      [tx.amount, tx.userId],
    );
  }

  /// Retrieves all unsynced transactions from local SQLite
  Future<List<TransactionModel>> getUnsyncedTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'offline_transactions',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    return List.generate(maps.length, (i) {
      return TransactionModel.fromJson(maps[i]);
    });
  }

  /// Synchronizes balance cache
  Future<void> updateCachedUser(String userId, double newBalance) async {
    final db = await database;
    await db.insert(
      'cached_user',
      {'id': userId, 'balance': newBalance},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves cached passenger balance when offline
  Future<double> getCachedBalance(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cached_user',
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (maps.isEmpty) return 0.0;
    return (maps.first['balance'] as num).toDouble();
  }

  /// Mark local SQLite transactions as synced after server sync response
  Future<void> markAsSynced(List<String> ids) async {
    final db = await database;
    for (var id in ids) {
      await db.update(
        'offline_transactions',
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  /// Delete transactions from cache
  Future<void> clearSyncedTransactions() async {
    final db = await database;
    await db.delete(
      'offline_transactions',
      where: 'is_synced = ?',
      whereArgs: [1],
    );
  }
}
