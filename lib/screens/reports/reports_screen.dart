import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import '../../models/entry.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  Map<String, dynamic> _dailyStats = {};
  Map<String, dynamic> _monthlyStats = {};
  bool _isLoadingDaily = true;
  bool _isLoadingMonthly = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDailyStats();
    _loadMonthlyStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyStats() async {
    setState(() => _isLoadingDaily = true);
    final provider = context.read<AppProvider>();
    final stats = await provider.getMonthlyStats(_selectedYear, _selectedMonth);
    // Get daily entries for selected date
    final dateStr = _selectedDate.toIso8601String().substring(0, 10);
    final db = await _getDailyStats(provider, dateStr);
    if (mounted) {
      setState(() {
        _dailyStats = db;
        _isLoadingDaily = false;
      });
    }
  }

  Future<Map<String, dynamic>> _getDailyStats(AppProvider provider, String date) async {
    final entries = await provider.getEntriesForDateRange(date, date);
    double earned = 0, credit = 0, grain = 0;
    Set<String> customers = {};
    Map<String, double> grainMap = {};
    for (final e in entries) {
      customers.add(e.customerId);
      grain += e.weightKg;
      grainMap[e.grainType.name] = (grainMap[e.grainType.name] ?? 0) + e.weightKg;
      if (e.status == EntryStatus.paid) {
        earned += e.amount;
      } else {
        credit += e.amount;
      }
    }
    return {
      'earned': earned,
      'credit': credit,
      'grain': grain,
      'customer_count': customers.length,
      'entry_count': entries.length,
      'grain_breakdown': grainMap,
    };
  }

  Future<void> _loadMonthlyStats() async {
    setState(() => _isLoadingMonthly = true);
    final provider = context.read<AppProvider>();
    final stats = await provider.getMonthlyStats(_selectedYear, _selectedMonth);
    if (mounted) {
      setState(() {
        _monthlyStats = stats;
        _isLoadingMonthly = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'तारीख निवडा',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _loadDailyStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('अहवाल'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMedium,
          indicatorColor: AppTheme.primary,
          labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'दैनिक'),
            Tab(text: 'मासिक'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DailyReport(
            selectedDate: _selectedDate,
            stats: _dailyStats,
            isLoading: _isLoadingDaily,
            onSelectDate: _selectDate,
          ),
          _MonthlyReport(
            selectedMonth: _selectedMonth,
            selectedYear: _selectedYear,
            stats: _monthlyStats,
            isLoading: _isLoadingMonthly,
            onMonthChanged: (month, year) {
              setState(() {
                _selectedMonth = month;
                _selectedYear = year;
              });
              _loadMonthlyStats();
            },
          ),
        ],
      ),
    );
  }
}

class _DailyReport extends StatelessWidget {
  final DateTime selectedDate;
  final Map<String, dynamic> stats;
  final bool isLoading;
  final VoidCallback onSelectDate;

  const _DailyReport({
    required this.selectedDate,
    required this.stats,
    required this.isLoading,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Date picker
          GestureDetector(
            onTap: onSelectDate,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    AppHelpers.formatDateForDisplay(selectedDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.expand_more, color: AppTheme.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (isLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          else ...[
            _StatRow(
              label: 'एकूण कमाई',
              value: AppHelpers.formatCurrency((stats['earned'] as num?)?.toDouble() ?? 0),
              color: AppTheme.paid,
              icon: Icons.payments_outlined,
            ),
            _StatRow(
              label: 'एकूण उधारी',
              value: AppHelpers.formatCurrency((stats['credit'] as num?)?.toDouble() ?? 0),
              color: AppTheme.credit,
              icon: Icons.pending_outlined,
            ),
            _StatRow(
              label: 'एकूण धान्य',
              value: AppHelpers.formatWeight((stats['grain'] as num?)?.toDouble() ?? 0),
              color: const Color(0xFF8B6914),
              icon: Icons.grain_outlined,
            ),
            _StatRow(
              label: 'ग्राहक',
              value: '${(stats['customer_count'] as num?)?.toInt() ?? 0}',
              color: AppTheme.primary,
              icon: Icons.people_outline,
            ),

            if ((stats['grain_breakdown'] as Map?)?.isNotEmpty == true) ...[
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'धान्य तपशील',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ...(stats['grain_breakdown'] as Map<String, dynamic>).entries.map((e) {
                final grain = GrainType.fromString(e.key);
                return _GrainRow(grain: grain, weight: (e.value as num).toDouble());
              }),
            ],
          ],
        ],
      ),
    );
  }
}

class _MonthlyReport extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final Map<String, dynamic> stats;
  final bool isLoading;
  final Function(int, int) onMonthChanged;

  const _MonthlyReport({
    required this.selectedMonth,
    required this.selectedYear,
    required this.stats,
    required this.isLoading,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month picker
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  int m = selectedMonth - 1;
                  int y = selectedYear;
                  if (m < 1) {
                    m = 12;
                    y--;
                  }
                  onMonthChanged(m, y);
                },
                icon: const Icon(Icons.chevron_left, size: 30),
                color: AppTheme.primary,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${AppHelpers.getMonthName(selectedMonth)} $selectedYear',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  int m = selectedMonth + 1;
                  int y = selectedYear;
                  if (m > 12) {
                    m = 1;
                    y++;
                  }
                  if (y > DateTime.now().year || (y == DateTime.now().year && m > DateTime.now().month)) return;
                  onMonthChanged(m, y);
                },
                icon: const Icon(Icons.chevron_right, size: 30),
                color: AppTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (isLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          else ...[
            _StatRow(
              label: 'एकूण कमाई (Paid)',
              value: AppHelpers.formatCurrency((stats['total_paid'] as num?)?.toDouble() ?? 0),
              color: AppTheme.paid,
              icon: Icons.payments_outlined,
            ),
            _StatRow(
              label: 'एकूण उधारी दिली',
              value: AppHelpers.formatCurrency((stats['total_credit'] as num?)?.toDouble() ?? 0),
              color: AppTheme.credit,
              icon: Icons.pending_outlined,
            ),
            _StatRow(
              label: 'पेमेंट मिळाले',
              value: AppHelpers.formatCurrency((stats['payments_received'] as num?)?.toDouble() ?? 0),
              color: const Color(0xFF1565C0),
              icon: Icons.currency_rupee,
            ),
            _StatRow(
              label: 'बाकी उधारी (सर्व)',
              value: AppHelpers.formatCurrency((stats['total_pending'] as num?)?.toDouble() ?? 0),
              color: AppTheme.credit,
              icon: Icons.account_balance_wallet_outlined,
            ),
            _StatRow(
              label: 'धान्य पिसले',
              value: AppHelpers.formatWeight((stats['total_grain'] as num?)?.toDouble() ?? 0),
              color: const Color(0xFF8B6914),
              icon: Icons.grain_outlined,
            ),
            _StatRow(
              label: 'एकूण नोंदी',
              value: '${(stats['entry_count'] as num?)?.toInt() ?? 0}',
              color: AppTheme.primary,
              icon: Icons.receipt_long_outlined,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, color: AppTheme.textMedium, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

class _GrainRow extends StatelessWidget {
  final GrainType grain;
  final double weight;

  const _GrainRow({required this.grain, required this.weight});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Text(grain.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Text(
            grain.displayName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            AppHelpers.formatWeight(weight),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
