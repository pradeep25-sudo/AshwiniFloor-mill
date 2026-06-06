import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../models/customer.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import 'customer_detail_screen.dart';
import 'add_edit_customer_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _searchController = TextEditingController();
  List<Customer> _filteredCustomers = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearch() async {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredCustomers = [];
      });
      return;
    }
    final provider = context.read<AppProvider>();
    final results = await provider.searchCustomers(query);
    setState(() {
      _isSearching = true;
      _filteredCustomers = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('ग्राहक'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: AppTheme.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditCustomerScreen()),
            ).then((_) => context.read<AppProvider>().loadCustomers()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ग्राहक शोधा...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMedium),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textMedium),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _isSearching = false);
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: Consumer<AppProvider>(
              builder: (context, provider, _) {
                final customers = _isSearching ? _filteredCustomers : provider.customers;

                if (customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline, size: 64, color: AppTheme.textLight),
                        const SizedBox(height: 16),
                        Text(
                          _isSearching ? 'ग्राहक सापडला नाही' : 'अजून ग्राहक नाही',
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppTheme.textMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!_isSearching) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'वर + दाबून नवीन ग्राहक जोडा',
                            style: TextStyle(fontSize: 14, color: AppTheme.textLight),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    final pending = provider.getPendingAmount(customer.id);
                    return _CustomerCard(
                      customer: customer,
                      pendingAmount: pending,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerDetailScreen(customerId: customer.id),
                        ),
                      ).then((_) => provider.loadCustomers()),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final double pendingAmount;
  final VoidCallback onTap;

  const _CustomerCard({
    required this.customer,
    required this.pendingAmount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPending = pendingAmount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasPending ? AppTheme.credit.withOpacity(0.3) : AppTheme.divider,
          ),
        ),
        child: Row(
          children: [
            _CustomerAvatar(customer: customer, size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  if (customer.phone != null && customer.phone!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      customer.phone!,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMedium),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppHelpers.formatCurrency(pendingAmount),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: hasPending ? AppTheme.credit : AppTheme.paid,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasPending ? 'उधारी' : 'चुकती ✓',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasPending ? AppTheme.credit : AppTheme.paid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerAvatar extends StatelessWidget {
  final Customer customer;
  final double size;

  const _CustomerAvatar({required this.customer, required this.size});

  @override
  Widget build(BuildContext context) {
    if (customer.photoPath != null && customer.photoPath!.isNotEmpty) {
      final file = File(customer.photoPath!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: size / 2,
          backgroundImage: FileImage(file),
        );
      }
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppTheme.primary.withOpacity(0.15),
      child: Text(
        customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: size / 2.2,
          fontWeight: FontWeight.w800,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}
