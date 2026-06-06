import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class ReceivePaymentScreen extends StatefulWidget {
  final String? preselectedCustomerId;

  const ReceivePaymentScreen({super.key, this.preselectedCustomerId});

  @override
  State<ReceivePaymentScreen> createState() => _ReceivePaymentScreenState();
}

class _ReceivePaymentScreenState extends State<ReceivePaymentScreen> {
  Customer? _selectedCustomer;
  final _amountController = TextEditingController();
  bool _isSaving = false;
  double _pendingAmount = 0;
  bool _clearAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      if (widget.preselectedCustomerId != null) {
        final c = provider.getCustomerById(widget.preselectedCustomerId!);
        if (c != null) _selectCustomer(c, provider);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectCustomer(Customer c, AppProvider provider) {
    final pending = provider.getPendingAmount(c.id);
    setState(() {
      _selectedCustomer = c;
      _pendingAmount = pending;
      _clearAll = false;
      _amountController.clear();
    });
  }

  void _toggleClearAll(bool val) {
    setState(() {
      _clearAll = val;
      if (val) {
        _amountController.text = _pendingAmount.toStringAsFixed(0);
      } else {
        _amountController.clear();
      }
    });
  }

  Future<void> _save() async {
    if (_selectedCustomer == null) {
      _showError('ग्राहक निवडा');
      return;
    }
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('रक्कम टाका');
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<AppProvider>();

    await provider.receivePartialPayment(_selectedCustomer!.id, amount);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppHelpers.formatCurrency(amount)} मिळाले ✓',
            style: const TextStyle(fontSize: 17),
          ),
          backgroundColor: AppTheme.paid,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.credit),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('पैसे मिळवा'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          // Only show customers with pending
          final customersWithPending = provider.customers
              .where((c) => provider.getPendingAmount(c.id) > 0)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer picker
                const _SectionLabel('ग्राहक निवडा'),
                if (customersWithPending.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.paid.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.paid.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.paid, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'सर्व ग्राहकांची उधारी नाही!',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.paid,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: customersWithPending.length,
                      itemBuilder: (_, i) {
                        final c = customersWithPending[i];
                        final isSelected = _selectedCustomer?.id == c.id;
                        final pending = provider.getPendingAmount(c.id);
                        return GestureDetector(
                          onTap: () => _selectCustomer(c, provider),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary : AppTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? AppTheme.primary : AppTheme.divider,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  c.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppHelpers.formatCurrency(pending),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white70 : AppTheme.credit,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 20),

                if (_selectedCustomer != null) ...[
                  // Pending info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.credit.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.credit.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'एकूण उधारी',
                              style: TextStyle(fontSize: 14, color: AppTheme.textMedium),
                            ),
                            Text(
                              _selectedCustomer!.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          AppHelpers.formatCurrency(_pendingAmount),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.credit,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Clear all toggle
                  GestureDetector(
                    onTap: () => _toggleClearAll(!_clearAll),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _clearAll ? AppTheme.paid.withOpacity(0.1) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _clearAll ? AppTheme.paid : AppTheme.divider,
                          width: _clearAll ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _clearAll ? Icons.check_box : Icons.check_box_outline_blank,
                            color: _clearAll ? AppTheme.paid : AppTheme.textMedium,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'सर्व उधारी एकत्र चुकती करा',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const _SectionLabel('रक्कम (₹)'),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                      hintText: '0',
                    ),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                    onChanged: (_) {
                      if (_clearAll) setState(() => _clearAll = false);
                    },
                  ),
                  const SizedBox(height: 28),

                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: const Icon(Icons.check_circle_outline, size: 24),
                    label: _isSaving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('पैसे मिळाले ✓', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.paid,
                      minimumSize: const Size(double.infinity, 60),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppTheme.textDark,
        ),
      ),
    );
  }
}
