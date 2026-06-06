import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../models/entry.dart';
import '../../models/payment.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import 'add_edit_customer_screen.dart';
import '../payment/receive_payment_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Entry> _entries = [];
  List<Payment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final provider = context.read<AppProvider>();
    final entries = await provider.getEntriesForCustomer(widget.customerId);
    final payments = await provider.getPaymentsForCustomer(widget.customerId);
    if (mounted) {
      setState(() {
        _entries = entries;
        _payments = payments;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllPaid(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('सर्व उधारी चुकती?'),
        content: Text('${customer.name} यांची सर्व उधारी चुकती करायची का?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('नाही')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.paid),
            child: const Text('हो, चुकती'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<AppProvider>().markAllEntriesPaid(widget.customerId);
      await _loadData();
    }
  }

  Future<void> _markSinglePaid(Entry entry) async {
    await context.read<AppProvider>().markEntryPaid(entry.id);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final customer = provider.getCustomerById(widget.customerId);
        if (customer == null) {
          return const Scaffold(body: Center(child: Text('ग्राहक सापडला नाही')));
        }
        final pending = provider.getPendingAmount(widget.customerId);

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: AppTheme.surface,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textDark),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditCustomerScreen(customer: customer),
                      ),
                    ).then((_) {
                      provider.loadCustomers();
                      _loadData();
                    }),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.credit),
                    onPressed: () => _confirmDelete(context, provider, customer),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: AppTheme.surface,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        _buildAvatar(customer),
                        const SizedBox(height: 12),
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                        if (customer.phone != null)
                          Text(
                            customer.phone!,
                            style: const TextStyle(fontSize: 15, color: AppTheme.textMedium),
                          ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: pending > 0
                                ? AppTheme.credit.withOpacity(0.1)
                                : AppTheme.paid.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            pending > 0
                                ? 'उधारी: ${AppHelpers.formatCurrency(pending)}'
                                : 'चुकती ✓',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: pending > 0 ? AppTheme.credit : AppTheme.paid,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.textMedium,
                  indicatorColor: AppTheme.primary,
                  labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'नोंदी'),
                    Tab(text: 'पेमेंट'),
                  ],
                ),
              ),
            ],
            body: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _EntriesTab(
                        entries: _entries,
                        onMarkPaid: _markSinglePaid,
                        onMarkAllPaid: () => _markAllPaid(customer),
                        pending: pending,
                      ),
                      _PaymentsTab(payments: _payments),
                    ],
                  ),
          ),
          bottomNavigationBar: pending > 0
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReceivePaymentScreen(preselectedCustomerId: widget.customerId),
                        ),
                      ).then((_) {
                        provider.initialize();
                        _loadData();
                      }),
                      icon: const Icon(Icons.currency_rupee),
                      label: const Text('पैसे मिळवा'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildAvatar(Customer customer) {
    if (customer.photoPath != null && customer.photoPath!.isNotEmpty) {
      final file = File(customer.photoPath!);
      if (file.existsSync()) {
        return CircleAvatar(radius: 40, backgroundImage: FileImage(file));
      }
    }
    return CircleAvatar(
      radius: 40,
      backgroundColor: AppTheme.primary.withOpacity(0.15),
      child: Text(
        customer.name[0].toUpperCase(),
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.primary),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppProvider provider, Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ग्राहक हटवायचा?'),
        content: Text('${customer.name} यांना यादीतून काढायचे का? सर्व नोंदी हटतील.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('नाही')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.credit),
            child: const Text('हटवा'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await provider.deleteCustomer(customer.id);
      if (mounted) Navigator.pop(context);
    }
  }
}

class _EntriesTab extends StatelessWidget {
  final List<Entry> entries;
  final Function(Entry) onMarkPaid;
  final VoidCallback onMarkAllPaid;
  final double pending;

  const _EntriesTab({
    required this.entries,
    required this.onMarkPaid,
    required this.onMarkAllPaid,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: AppTheme.textLight),
            SizedBox(height: 12),
            Text(
              'अजून नोंदी नाहीत',
              style: TextStyle(fontSize: 17, color: AppTheme.textMedium, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending > 0)
          GestureDetector(
            onTap: onMarkAllPaid,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.paid.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.paid.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: AppTheme.paid, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'सर्व उधारी चुकती करा',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.paid,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ...entries.map((entry) => _EntryCard(entry: entry, onMarkPaid: () => onMarkPaid(entry))),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  final Entry entry;
  final VoidCallback onMarkPaid;

  const _EntryCard({required this.entry, required this.onMarkPaid});

  @override
  Widget build(BuildContext context) {
    final isPaid = entry.status == EntryStatus.paid;
    final statusColor = isPaid ? AppTheme.paid : AppTheme.credit;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isPaid ? AppTheme.divider : AppTheme.credit.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(entry.grainType.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.grainType.displayName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${AppHelpers.formatDate(entry.workDate)} • ${AppHelpers.formatTime(entry.workTime)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppHelpers.formatCurrency(entry.amount),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isPaid ? 'दिले ✓' : 'उधारी',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoChip(label: '${AppHelpers.formatWeight(entry.weightKg)}'),
              const SizedBox(width: 8),
              _InfoChip(label: '₹${entry.ratePerKg}/किलो'),
              const Spacer(),
              if (!isPaid)
                GestureDetector(
                  onTap: onMarkPaid,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.paid,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'चुकती ✓',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  final List<Payment> payments;

  const _PaymentsTab({required this.payments});

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment_outlined, size: 56, color: AppTheme.textLight),
            SizedBox(height: 12),
            Text(
              'अजून पेमेंट नाही',
              style: TextStyle(fontSize: 17, color: AppTheme.textMedium, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.paid.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.paid.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.currency_rupee, color: AppTheme.paid, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'पेमेंट मिळाले',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${AppHelpers.formatDate(payment.paymentDate)} • ${AppHelpers.formatTime(payment.paymentTime)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
                    ),
                  ],
                ),
              ),
              Text(
                AppHelpers.formatCurrency(payment.amount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.paid,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
