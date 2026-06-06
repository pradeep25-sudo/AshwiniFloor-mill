import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/entry.dart';
import '../../models/customer.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class NewEntryScreen extends StatefulWidget {
  final String? preselectedCustomerId;
  final GrainType? preselectedGrain;
  final double? prefilledWeight;

  const NewEntryScreen({
    super.key,
    this.preselectedCustomerId,
    this.preselectedGrain,
    this.prefilledWeight,
  });

  @override
  State<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  Customer? _selectedCustomer;
  GrainType _selectedGrain = GrainType.wheat;
  final _weightController = TextEditingController();
  double _rate = 6.0;
  double _amount = 0.0;
  DateTime _workDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedGrain = widget.preselectedGrain ?? GrainType.wheat;
    if (widget.prefilledWeight != null) {
      _weightController.text = widget.prefilledWeight.toString();
    }
    _weightController.addListener(_calculateAmount);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AppProvider>();
      if (widget.preselectedCustomerId != null) {
        _selectedCustomer = provider.getCustomerById(widget.preselectedCustomerId!);
      }
      await _loadRate();
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadRate() async {
    final provider = context.read<AppProvider>();
    final rate = await provider.getRateForGrain(_selectedGrain.name);
    setState(() {
      _rate = rate;
      _calculateAmount();
    });
  }

  void _calculateAmount() {
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    setState(() {
      _amount = weight * _rate;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _workDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'तारीख निवडा',
      locale: const Locale('mr', 'IN'),
    );
    if (picked != null) setState(() => _workDate = picked);
  }

  Future<void> _saveEntry(EntryStatus status) async {
    if (_selectedCustomer == null) {
      _showError('ग्राहक निवडा');
      return;
    }
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) {
      _showError('वजन टाका');
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<AppProvider>();

    final entry = Entry(
      customerId: _selectedCustomer!.id,
      grainType: _selectedGrain,
      weightKg: weight,
      ratePerKg: _rate,
      amount: _amount,
      status: status,
      workDate: _workDate,
    );

    await provider.addEntry(entry);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == EntryStatus.paid ? 'नोंद जतन झाली ✓' : 'उधारी नोंद जतन झाली',
            style: const TextStyle(fontSize: 16),
          ),
          backgroundColor: status == EntryStatus.paid ? AppTheme.paid : AppTheme.credit,
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
        title: const Text('नवीन नोंद'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer picker
                _SectionLabel(label: 'ग्राहक निवडा'),
                _CustomerPicker(
                  customers: provider.customers,
                  selected: _selectedCustomer,
                  onSelect: (c) => setState(() => _selectedCustomer = c),
                ),
                const SizedBox(height: 20),

                // Grain picker
                _SectionLabel(label: 'धान्य निवडा'),
                _GrainPicker(
                  selected: _selectedGrain,
                  onSelect: (g) async {
                    setState(() => _selectedGrain = g);
                    await _loadRate();
                  },
                ),
                const SizedBox(height: 20),

                // Weight
                _SectionLabel(label: 'वजन (किलो)'),
                TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'उदा. 10',
                    prefixIcon: const Icon(Icons.scale_outlined, color: AppTheme.primary),
                    suffixText: 'किलो',
                    suffixStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMedium,
                    ),
                  ),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),

                // Rate and Amount display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('दर', style: TextStyle(fontSize: 13, color: AppTheme.textMedium)),
                          Text(
                            '₹$_rate/किलो',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward, color: AppTheme.textMedium),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('रक्कम', style: TextStyle(fontSize: 13, color: AppTheme.textMedium)),
                          Text(
                            AppHelpers.formatCurrency(_amount),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Date picker
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('तारीख', style: TextStyle(fontSize: 13, color: AppTheme.textMedium)),
                              Text(
                                AppHelpers.formatDateShort(_workDate),
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppTheme.textMedium),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Save buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : () => _saveEntry(EntryStatus.paid),
                        icon: const Icon(Icons.check_circle_outline, size: 22),
                        label: const Text('दिले ✓'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.paid,
                          minimumSize: const Size(double.infinity, 56),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : () => _saveEntry(EntryStatus.credit),
                        icon: const Icon(Icons.pending_outlined, size: 22),
                        label: const Text('उधारी'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.credit,
                          minimumSize: const Size(double.infinity, 56),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
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

  const _SectionLabel({required this.label});

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

class _CustomerPicker extends StatelessWidget {
  final List<Customer> customers;
  final Customer? selected;
  final Function(Customer) onSelect;

  const _CustomerPicker({
    required this.customers,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected != null ? AppTheme.primary : AppTheme.divider,
            width: selected != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_outline, color: AppTheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selected?.name ?? 'ग्राहक निवडा...',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: selected != null ? AppTheme.textDark : AppTheme.textMedium,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMedium),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'ग्राहक निवडा',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(),
            if (customers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'ग्राहक नाहीत. आधी ग्राहक जोडा.',
                  style: TextStyle(fontSize: 16, color: AppTheme.textMedium),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: customers.length,
                  itemBuilder: (_, i) {
                    final c = customers[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withOpacity(0.15),
                        child: Text(
                          c.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      title: Text(c.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      subtitle: c.phone != null ? Text(c.phone!) : null,
                      trailing: selected?.id == c.id
                          ? const Icon(Icons.check, color: AppTheme.primary)
                          : null,
                      onTap: () {
                        onSelect(c);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GrainPicker extends StatelessWidget {
  final GrainType selected;
  final Function(GrainType) onSelect;

  const _GrainPicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: GrainType.values.map((grain) {
        final isSelected = grain == selected;
        return GestureDetector(
          onTap: () => onSelect(grain),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(grain.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  grain.displayName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
