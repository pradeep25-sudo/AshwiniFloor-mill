import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/entry.dart';
import '../../providers/app_provider.dart';
import '../../services/backup_service.dart';
import '../../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, TextEditingController> _rateControllers = {};
  bool _isSavingRates = false;

  final List<_GrainInfo> _grains = [
    _GrainInfo(GrainType.wheat, 'गहू', '🌾'),
    _GrainInfo(GrainType.jowar, 'ज्वारी', '🌿'),
    _GrainInfo(GrainType.bajra, 'बाजरी', '🌱'),
    _GrainInfo(GrainType.rice, 'तांदूळ', '🍚'),
    _GrainInfo(GrainType.maize, 'मका', '🌽'),
    _GrainInfo(GrainType.other, 'इतर', '🫘'),
  ];

  @override
  void initState() {
    super.initState();
    for (final g in _grains) {
      _rateControllers[g.type.name] = TextEditingController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRates());
  }

  @override
  void dispose() {
    for (final c in _rateControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _loadRates() {
    final provider = context.read<AppProvider>();
    for (final g in _grains) {
      final rate = provider.getRateFromCache(g.type.name);
      _rateControllers[g.type.name]!.text = rate.toStringAsFixed(0);
    }
    setState(() {});
  }

  Future<void> _saveRates() async {
    setState(() => _isSavingRates = true);
    final provider = context.read<AppProvider>();
    for (final g in _grains) {
      final val = double.tryParse(_rateControllers[g.type.name]!.text);
      if (val != null && val > 0) {
        await provider.updateRate(g.type.name, val);
      }
    }
    setState(() => _isSavingRates = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('दर जतन झाले ✓', style: TextStyle(fontSize: 16)),
          backgroundColor: AppTheme.paid,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _exportBackup() async {
    final provider = context.read<AppProvider>();
    _showLoadingDialog('बॅकअप तयार होत आहे...');
    final result = await BackupService.exportBackup(provider);
    if (mounted) {
      Navigator.pop(context);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('बॅकअप तयार झाले ✓', style: TextStyle(fontSize: 16)),
            backgroundColor: AppTheme.paid,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('बॅकअप चूक झाले', style: TextStyle(fontSize: 16)),
            backgroundColor: AppTheme.credit,
          ),
        );
      }
    }
  }

  Future<void> _importBackup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('बॅकअप इम्पोर्ट?'),
        content: const Text(
          'सध्याचा सर्व डेटा हटेल आणि बॅकअपमधला डेटा येईल.\nखात्री आहे का?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('नाही'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.credit),
            child: const Text('हो, बदला'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final provider = context.read<AppProvider>();
    _showLoadingDialog('डेटा लोड होत आहे...');
    final success = await BackupService.importBackup(provider);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'बॅकअप इम्पोर्ट झाले ✓' : 'फाइल निवडली नाही',
            style: const TextStyle(fontSize: 16),
          ),
          backgroundColor: success ? AppTheme.paid : AppTheme.textMedium,
        ),
      );
      if (success) _loadRates();
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(width: 20),
            Text(message, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'अश्विनी खाता',
      applicationVersion: 'Version 1.0.0',
      applicationLegalese: '© 2024 अश्विनी गिरणी',
      children: [
        const SizedBox(height: 12),
        const Text(
          'तुमच्या गिरणीचे स्मार्ट हिशेब\n\nहे अॅप तुमच्या गिरणीच्या व्यवसायासाठी बनवले आहे.',
          style: TextStyle(fontSize: 15),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('सेटिंग्ज'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Rate Section ──────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.price_change_outlined,
              label: 'दर सेटिंग (₹ प्रति किलो)',
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                children: _grains.asMap().entries.map((entry) {
                  final i = entry.key;
                  final g = entry.value;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Text(g.emoji,
                                style: const TextStyle(fontSize: 26)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                g.label,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: _rateControllers[g.type.name],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  prefixText: '₹',
                                  prefixStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 10),
                                  filled: true,
                                  fillColor: AppTheme.background,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        const BorderSide(color: AppTheme.divider),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        const BorderSide(color: AppTheme.divider),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: AppTheme.primary, width: 2),
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i < _grains.length - 1)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _isSavingRates ? null : _saveRates,
              icon: _isSavingRates
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isSavingRates ? 'जतन होत आहे...' : 'दर जतन करा'),
            ),
            const SizedBox(height: 28),

            // ── Backup Section ────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.backup_outlined,
              label: 'बॅकअप',
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.upload_outlined,
              iconColor: const Color(0xFF1565C0),
              label: 'बॅकअप एक्सपोर्ट करा',
              subtitle: 'डेटा फाइलमध्ये सेव्ह करा / शेअर करा',
              onTap: _exportBackup,
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.download_outlined,
              iconColor: const Color(0xFF6A1B9A),
              label: 'बॅकअप इम्पोर्ट करा',
              subtitle: 'जुना डेटा परत आणा (सध्याचा डेटा बदलेल)',
              onTap: _importBackup,
            ),
            const SizedBox(height: 28),

            // ── About Section ─────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.info_outline,
              label: 'माहिती',
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.info_outline,
              iconColor: AppTheme.primary,
              label: 'अॅपबद्दल',
              subtitle: 'Version 1.0.0 • अश्विनी खाता',
              onTap: _showAbout,
            ),
            const SizedBox(height: 40),

            // Version footer
            Center(
              child: Column(
                children: [
                  const Text(
                    'अश्विनी खाता',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'तुमच्या गिरणीचे स्मार्ट हिशेब',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'v1.0.0',
                    style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _GrainInfo {
  final GrainType type;
  final String label;
  final String emoji;

  const _GrainInfo(this.type, this.label, this.emoji);
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMedium),
          ],
        ),
      ),
    );
  }
}
