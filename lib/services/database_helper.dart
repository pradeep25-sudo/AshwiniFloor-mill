import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ashwini_khata.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        photo_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE rates (
        id TEXT PRIMARY KEY,
        grain_type TEXT NOT NULL UNIQUE,
        rate_per_kg REAL NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE entries (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        grain_type TEXT NOT NULL,
        weight_kg REAL NOT NULL,
        rate_per_kg REAL NOT NULL,
        amount REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'credit',
        work_date TEXT NOT NULL,
        work_time TEXT NOT NULL,
        created_at TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_time TEXT NOT NULL,
        created_at TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Insert default rates
    final now = DateTime.now().toIso8601String();
    final defaultRates = [
      {'id': 'rate_wheat', 'grain_type': 'wheat', 'rate_per_kg': 6.0, 'updated_at': now},
      {'id': 'rate_jowar', 'grain_type': 'jowar', 'rate_per_kg': 8.0, 'updated_at': now},
      {'id': 'rate_bajra', 'grain_type': 'bajra', 'rate_per_kg': 7.0, 'updated_at': now},
      {'id': 'rate_rice', 'grain_type': 'rice', 'rate_per_kg': 10.0, 'updated_at': now},
      {'id': 'rate_maize', 'grain_type': 'maize', 'rate_per_kg': 5.0, 'updated_at': now},
      {'id': 'rate_other', 'grain_type': 'other', 'rate_per_kg': 6.0, 'updated_at': now},
    ];
    for (final rate in defaultRates) {
      await db.insert('rates', rate);
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
    // if (oldVersion < 2) { ... }
  }

  // ─── CUSTOMERS ───────────────────────────────────────────────────────────────

  Future<String> insertCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    await db.insert('customers', customer, conflictAlgorithm: ConflictAlgorithm.replace);
    return customer['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    final db = await database;
    return await db.query('customers', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getCustomer(String id) async {
    final db = await database;
    final results = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    await db.update('customers', customer, where: 'id = ?', whereArgs: [customer['id']]);
  }

  Future<void> deleteCustomer(String id) async {
    final db = await database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    final db = await database;
    return await db.query(
      'customers',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
  }

  // ─── ENTRIES ─────────────────────────────────────────────────────────────────

  Future<String> insertEntry(Map<String, dynamic> entry) async {
    final db = await database;
    await db.insert('entries', entry, conflictAlgorithm: ConflictAlgorithm.replace);
    return entry['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getEntriesForCustomer(String customerId) async {
    final db = await database;
    return await db.query(
      'entries',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'work_date DESC, work_time DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getCreditEntriesForCustomer(String customerId) async {
    final db = await database;
    return await db.query(
      'entries',
      where: 'customer_id = ? AND status = ?',
      whereArgs: [customerId, 'credit'],
      orderBy: 'work_date DESC',
    );
  }

  Future<double> getPendingAmountForCustomer(String customerId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM entries WHERE customer_id = ? AND status = ?',
      [customerId, 'credit'],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> updateEntryStatus(String entryId, String status) async {
    final db = await database;
    await db.update(
      'entries',
      {'status': status},
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  Future<void> markAllEntriesPaid(String customerId) async {
    final db = await database;
    await db.update(
      'entries',
      {'status': 'paid'},
      where: 'customer_id = ? AND status = ?',
      whereArgs: [customerId, 'credit'],
    );
  }

  Future<List<Map<String, dynamic>>> getTodayEntries() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return await db.query(
      'entries',
      where: 'work_date = ?',
      whereArgs: [today],
      orderBy: 'work_time DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getEntriesForDateRange(String startDate, String endDate) async {
    final db = await database;
    return await db.query(
      'entries',
      where: 'work_date >= ? AND work_date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'work_date DESC, work_time DESC',
    );
  }

  Future<Map<String, dynamic>> getDailyStats(String date) async {
    final db = await database;
    final entries = await db.query('entries', where: 'work_date = ?', whereArgs: [date]);
    double totalEarnings = 0;
    double totalCredit = 0;
    double totalGrain = 0;
    Set<String> customerIds = {};

    for (final e in entries) {
      final amount = (e['amount'] as num).toDouble();
      final weight = (e['weight_kg'] as num).toDouble();
      totalGrain += weight;
      customerIds.add(e['customer_id'] as String);
      if (e['status'] == 'paid') {
        totalEarnings += amount;
      } else {
        totalCredit += amount;
      }
    }

    return {
      'total_earnings': totalEarnings,
      'total_credit': totalCredit,
      'total_grain': totalGrain,
      'customer_count': customerIds.length,
      'entry_count': entries.length,
    };
  }

  Future<Map<String, dynamic>> getMonthlyStats(int year, int month) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = '$year-${month.toString().padLeft(2, '0')}-31';

    final entries = await db.query(
      'entries',
      where: 'work_date >= ? AND work_date <= ?',
      whereArgs: [startDate, endDate],
    );

    final payments = await db.query(
      'payments',
      where: 'payment_date >= ? AND payment_date <= ?',
      whereArgs: [startDate, endDate],
    );

    double totalPaid = 0;
    double totalCredit = 0;
    double totalGrain = 0;

    for (final e in entries) {
      final amount = (e['amount'] as num).toDouble();
      final weight = (e['weight_kg'] as num).toDouble();
      totalGrain += weight;
      if (e['status'] == 'paid') {
        totalPaid += amount;
      } else {
        totalCredit += amount;
      }
    }

    double totalPaymentsReceived = 0;
    for (final p in payments) {
      totalPaymentsReceived += (p['amount'] as num).toDouble();
    }

    final allPending = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM entries WHERE status = ?',
      ['credit'],
    );

    return {
      'total_paid': totalPaid,
      'total_credit': totalCredit,
      'total_grain': totalGrain,
      'payments_received': totalPaymentsReceived,
      'total_pending': (allPending.first['total'] as num?)?.toDouble() ?? 0.0,
      'entry_count': entries.length,
    };
  }

  // ─── PAYMENTS ────────────────────────────────────────────────────────────────

  Future<String> insertPayment(Map<String, dynamic> payment) async {
    final db = await database;
    await db.insert('payments', payment, conflictAlgorithm: ConflictAlgorithm.replace);
    return payment['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getPaymentsForCustomer(String customerId) async {
    final db = await database;
    return await db.query(
      'payments',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'payment_date DESC',
    );
  }

  // ─── RATES ───────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllRates() async {
    final db = await database;
    return await db.query('rates', orderBy: 'grain_type ASC');
  }

  Future<double> getRateForGrain(String grainType) async {
    final db = await database;
    final result = await db.query('rates', where: 'grain_type = ?', whereArgs: [grainType]);
    if (result.isNotEmpty) {
      return (result.first['rate_per_kg'] as num).toDouble();
    }
    return 6.0;
  }

  Future<void> updateRate(String grainType, double rate) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'rates',
      {'rate_per_kg': rate, 'updated_at': now},
      where: 'grain_type = ?',
      whereArgs: [grainType],
    );
  }

  // ─── BACKUP ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'customers': await db.query('customers'),
      'entries': await db.query('entries'),
      'payments': await db.query('payments'),
      'rates': await db.query('rates'),
      'settings': await db.query('settings'),
    };
  }

  Future<void> importAllData(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('payments');
      await txn.delete('entries');
      await txn.delete('customers');
      await txn.delete('rates');
      await txn.delete('settings');

      for (final c in (data['customers'] as List)) {
        await txn.insert('customers', Map<String, dynamic>.from(c),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final e in (data['entries'] as List)) {
        await txn.insert('entries', Map<String, dynamic>.from(e),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final p in (data['payments'] as List)) {
        await txn.insert('payments', Map<String, dynamic>.from(p),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final r in (data['rates'] as List)) {
        await txn.insert('rates', Map<String, dynamic>.from(r),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
