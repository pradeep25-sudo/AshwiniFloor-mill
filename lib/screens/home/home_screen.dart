import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import '../entry/new_entry_screen.dart';
import '../entry/voice_entry_screen.dart';
import '../customer/customer_list_screen.dart';
import '../payment/receive_payment_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'अश्विनी खाता',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
            const Text(
              'तुमच्या गिरणीचे स्मार्ट हिशेब',
              style: TextStyle(fontSize: 11, color: AppTheme.textMedium, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textMedium),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadTodayData(),
            color: AppTheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DashboardSection(stats: provider.todayStats),
                  const SizedBox(height: 24),
                  _QuickActionsSection(),
                  const SizedBox(height: 24),
                  _TodayEntriesSection(provider: provider),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VoiceEntryScreen()),
        ).then((_) => context.read<AppProvider>().loadTodayData()),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.mic, color: Colors.white, size: 36),
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _DashboardSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final earnings = (stats['total_earnings'] as num?)?.toDouble() ?? 0;
    final credit = (stats['total_credit'] as num?)?.toDouble() ?? 0;
    final customers = (stats['customer_count'] as num?)?.toInt() ?? 0;
    final grain = (stats['total_grain'] as num?)?.toDouble() ?? 0;

    final provider = context.watch<AppProvider>();
    double totalPending = 0;
    for (final c in provider.customers) {
      totalPending += provider.getPendingAmount(c.id);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'आजचा आढावा',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMedium,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'आजची कमाई',
                value: AppHelpers.formatCurrency(earnings),
                icon: Icons.payments_outlined,
                color: AppTheme.paid,
                bgColor: const Color(0xFFE8F5E9),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'एकूण उधारी',
                value: AppHelpers.formatCurrency(totalPending),
                icon: Icons.pending_actions_outlined,
                color: AppTheme.credit,
                bgColor: const Color(0xFFFFEBEE),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'आजचे ग्राहक',
                value: '$customers',
                icon: Icons.people_outline,
                color: AppTheme.primary,
                bgColor: const Color(0xFFE8F5E9),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'आजचे धान्य',
                value: AppHelpers.formatWeight(grain),
                icon: Icons.grain_outlined,
                color: const Color(0xFF8B6914),
                bgColor: const Color(0xFFFFF8E1),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'काय करायचे?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMedium,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'नवीन नोंद',
                icon: Icons.add_circle_outline,
                color: AppTheme.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewEntryScreen()),
                ).then((_) => context.read<AppProvider>().loadTodayData()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'पैसे मिळवा',
                icon: Icons.currency_rupee,
                color: const Color(0xFF1565C0),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReceivePaymentScreen()),
                ).then((_) => context.read<AppProvider>().initialize()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'ग्राहक',
                icon: Icons.people_outline,
                color: const Color(0xFF6A1B9A),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerListScreen()),
                ).then((_) => context.read<AppProvider>().loadCustomers()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'अहवाल',
                icon: Icons.bar_chart_outlined,
                color: const Color(0xFFE65100),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayEntriesSection extends StatelessWidget {
  final AppProvider provider;

  const _TodayEntriesSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final entries = provider.todayEntries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'आजच्या नोंदी',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMedium,
                letterSpacing: 0.5,
              ),
            ),
            if (entries.isNotEmpty)
              Text(
                '${entries.length} नोंदी',
                style: const TextStyle(fontSize: 13, color: AppTheme.textMedium),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
            ),
            child: const Column(
              children: [
                Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textLight),
                SizedBox(height: 12),
                Text(
                  'आज अजून कोणती नोंद नाही',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'वर मायक्रोफोन दाबून सुरू करा',
                  style: TextStyle(fontSize: 13, color: AppTheme.textLight),
                ),
              ],
            ),
          )
        else
          ...entries.map((entry) {
            final customer = provider.getCustomerById(entry.customerId);
            return _EntryTile(entry: entry, customerName: customer?.name ?? 'अज्ञात');
          }),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  final dynamic entry;
  final String customerName;

  const _EntryTile({required this.entry, required this.customerName});

  @override
  Widget build(BuildContext context) {
    final isPaid = entry.status.name == 'paid';
    final statusColor = isPaid ? AppTheme.paid : AppTheme.credit;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(entry.grainType.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.grainType.displayName} • ${AppHelpers.formatWeight(entry.weightKg)}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textMedium),
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
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 3),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPaid ? 'दिले ✓' : 'उधारी',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
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
