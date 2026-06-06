import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/entry.dart';
import '../models/payment.dart';
import '../models/rate.dart';
import '../services/database_helper.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Customer> _customers = [];
  List<Entry> _todayEntries = [];
  List<Rate> _rates = [];
  Map<String, dynamic> _todayStats = {};
  Map<String, double> _pendingAmounts = {};

  bool _isLoading = false;

  List<Customer> get customers => _customers;
  List<Entry> get todayEntries => _todayEntries;
  List<Rate> get rates => _rates;
  Map<String, dynamic> get todayStats => _todayStats;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    await loadCustomers();
    await loadRates();
    await loadTodayData();
    _isLoading = false;
    notifyListeners();
  }

  // ─── CUSTOMERS ───────────────────────────────────────────────────────────────

  Future<void> loadCustomers() async {
    final maps = await _db.getAllCustomers();
    _customers = maps.map((m) => Customer.fromMap(m)).toList();
    await _loadPendingAmounts();
    notifyListeners();
  }

  Future<void> _loadPendingAmounts() async {
    for (final customer in _customers) {
      _pendingAmounts[customer.id] = await _db.getPendingAmountForCustomer(customer.id);
    }
  }

  double getPendingAmount(String customerId) {
    return _pendingAmounts[customerId] ?? 0.0;
  }

  Future<String> addCustomer(Customer customer) async {
    final id = await _db.insertCustomer(customer.toMap());
    await loadCustomers();
    return id;
  }

  Future<void> updateCustomer(Customer customer) async {
    await _db.updateCustomer(customer.toMap());
    await loadCustomers();
  }

  Future<void> deleteCustomer(String id) async {
    await _db.deleteCustomer(id);
    await loadCustomers();
  }

  Future<List<Customer>> searchCustomers(String query) async {
    if (query.isEmpty) return _customers;
    final maps = await _db.searchCustomers(query);
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Customer? getCustomerById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── ENTRIES ─────────────────────────────────────────────────────────────────

  Future<void> loadTodayData() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final maps = await _db.getTodayEntries();
    _todayEntries = maps.map((m) => Entry.fromMap(m)).toList();
    _todayStats = await _db.getDailyStats(today);
    notifyListeners();
  }

  Future<String> addEntry(Entry entry) async {
    final id = await _db.insertEntry(entry.toMap());
    await loadTodayData();
    await _loadPendingAmounts();
    notifyListeners();
    return id;
  }

  Future<List<Entry>> getEntriesForCustomer(String customerId) async {
    final maps = await _db.getEntriesForCustomer(customerId);
    return maps.map((m) => Entry.fromMap(m)).toList();
  }

  Future<List<Entry>> getCreditEntriesForCustomer(String customerId) async {
    final maps = await _db.getCreditEntriesForCustomer(customerId);
    return maps.map((m) => Entry.fromMap(m)).toList();
  }

  Future<void> markEntryPaid(String entryId) async {
    await _db.updateEntryStatus(entryId, 'paid');
    await loadTodayData();
    await _loadPendingAmounts();
    notifyListeners();
  }

  Future<void> markAllEntriesPaid(String customerId) async {
    await _db.markAllEntriesPaid(customerId);
    await loadTodayData();
    await _loadPendingAmounts();
    notifyListeners();
  }

  Future<List<Entry>> getEntriesForDateRange(String startDate, String endDate) async {
    final maps = await _db.getEntriesForDateRange(startDate, endDate);
    return maps.map((m) => Entry.fromMap(m)).toList();
  }

  // ─── PAYMENTS ────────────────────────────────────────────────────────────────

  Future<void> addPayment(Payment payment) async {
    await _db.insertPayment(payment.toMap());
    await _loadPendingAmounts();
    notifyListeners();
  }

  Future<List<Payment>> getPaymentsForCustomer(String customerId) async {
    final maps = await _db.getPaymentsForCustomer(customerId);
    return maps.map((m) => Payment.fromMap(m)).toList();
  }

  // Partial payment: record payment, mark oldest credit entries as paid up to amount
  Future<void> receivePartialPayment(String customerId, double amount) async {
    final now = DateTime.now();
    final payment = Payment(
      customerId: customerId,
      amount: amount,
      paymentDate: now,
    );
    await _db.insertPayment(payment.toMap());

    final creditEntries = await _db.getCreditEntriesForCustomer(customerId);
    double remaining = amount;
    for (final entryMap in creditEntries) {
      if (remaining <= 0) break;
      final entryAmount = (entryMap['amount'] as num).toDouble();
      if (entryAmount <= remaining) {
        await _db.updateEntryStatus(entryMap['id'] as String, 'paid');
        remaining -= entryAmount;
      }
    }

    await _loadPendingAmounts();
    await loadTodayData();
    notifyListeners();
  }

  // ─── RATES ───────────────────────────────────────────────────────────────────

  Future<void> loadRates() async {
    final maps = await _db.getAllRates();
    _rates = maps.map((m) => Rate.fromMap(m)).toList();
    notifyListeners();
  }

  Future<double> getRateForGrain(String grainType) async {
    return await _db.getRateForGrain(grainType);
  }

  Future<void> updateRate(String grainType, double rate) async {
    await _db.updateRate(grainType, rate);
    await loadRates();
  }

  double getRateFromCache(String grainType) {
    try {
      return _rates.firstWhere((r) => r.grainType == grainType).ratePerKg;
    } catch (_) {
      return 6.0;
    }
  }

  // ─── STATS ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMonthlyStats(int year, int month) async {
    return await _db.getMonthlyStats(year, month);
  }

  // ─── BACKUP ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> exportData() async {
    return await _db.exportAllData();
  }

  Future<void> importData(Map<String, dynamic> data) async {
    await _db.importAllData(data);
    await initialize();
  }
}
