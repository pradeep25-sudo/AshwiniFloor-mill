import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/entry.dart';
import '../../models/customer.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import 'new_entry_screen.dart';

class VoiceEntryScreen extends StatefulWidget {
  const VoiceEntryScreen({super.key});

  @override
  State<VoiceEntryScreen> createState() => _VoiceEntryScreenState();
}

class _VoiceEntryScreenState extends State<VoiceEntryScreen>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  String _recognizedText = '';
  String _statusText = 'माइक दाबा आणि बोला';

  // Parsed values
  Customer? _parsedCustomer;
  GrainType? _parsedGrain;
  double? _parsedWeight;
  double _rate = 0;
  double _amount = 0;
  bool _showConfirmation = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initSpeech();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      _speechAvailable = await _speech.initialize(
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') {
            setState(() => _isListening = false);
            _processText(_recognizedText);
          }
        },
        onError: (e) {
          setState(() {
            _isListening = false;
            _statusText = 'चूक झाली, पुन्हा प्रयत्न करा';
          });
        },
      );
    } else {
      setState(() => _statusText = 'माइकची परवानगी द्या');
    }
    setState(() {});
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      await _initSpeech();
      return;
    }
    setState(() {
      _isListening = true;
      _recognizedText = '';
      _statusText = 'ऐकत आहे...';
      _showConfirmation = false;
      _parsedCustomer = null;
      _parsedGrain = null;
      _parsedWeight = null;
    });

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
        });
      },
      localeId: 'mr_IN',
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 2),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
    _processText(_recognizedText);
  }

  Future<void> _processText(String text) async {
    if (text.trim().isEmpty) {
      setState(() => _statusText = 'काहीच ऐकले नाही, पुन्हा प्रयत्न करा');
      return;
    }

    final provider = context.read<AppProvider>();
    final extracted = AppHelpers.extractVoiceInfo(text);

    // Find customer by name match
    Customer? foundCustomer;
    if (extracted['customer'] != null) {
      final results = await provider.searchCustomers(extracted['customer']!);
      if (results.isNotEmpty) foundCustomer = results.first;
    } else {
      // Try to find any customer name in the text
      for (final c in provider.customers) {
        if (text.contains(c.name.split(' ').first)) {
          foundCustomer = c;
          break;
        }
      }
    }

    final grainType = extracted['grain'] != null
        ? GrainType.fromString(extracted['grain']!)
        : null;
    final weight = extracted['weight'] != null ? double.tryParse(extracted['weight']!) : null;

    double rate = 0;
    double amount = 0;
    if (grainType != null && weight != null) {
      rate = await provider.getRateForGrain(grainType.name);
      amount = weight * rate;
    }

    setState(() {
      _parsedCustomer = foundCustomer;
      _parsedGrain = grainType;
      _parsedWeight = weight;
      _rate = rate;
      _amount = amount;
      _showConfirmation = true;
      _statusText = 'हे बरोबर आहे का?';
    });
  }

  Future<void> _saveEntry(EntryStatus status) async {
    if (_parsedCustomer == null || _parsedGrain == null || _parsedWeight == null) {
      _goToManualEntry();
      return;
    }

    final provider = context.read<AppProvider>();
    final entry = Entry(
      customerId: _parsedCustomer!.id,
      grainType: _parsedGrain!,
      weightKg: _parsedWeight!,
      ratePerKg: _rate,
      amount: _amount,
      status: status,
      workDate: DateTime.now(),
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
        ),
      );
      Navigator.pop(context);
    }
  }

  void _goToManualEntry() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => NewEntryScreen(
          preselectedCustomerId: _parsedCustomer?.id,
          preselectedGrain: _parsedGrain,
          prefilledWeight: _parsedWeight,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('आवाज नोंद'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Instruction
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Text(
                    'असे बोला:',
                    style: TextStyle(fontSize: 14, color: AppTheme.textMedium),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '"रमेश पाचारे पाच किलो गहू"',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Microphone button
            GestureDetector(
              onTapDown: (_) => _startListening(),
              onTapUp: (_) => _isListening ? _stopListening() : null,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) {
                  return Transform.scale(
                    scale: _isListening ? _pulseAnim.value : 1.0,
                    child: child,
                  );
                },
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening ? AppTheme.credit : AppTheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? AppTheme.credit : AppTheme.primary).withOpacity(0.4),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              _statusText,
              style: TextStyle(
                fontSize: 17,
                color: _isListening ? AppTheme.credit : AppTheme.textMedium,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            if (_recognizedText.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Text(
                  '"$_recognizedText"',
                  style: const TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Confirmation card
            if (_showConfirmation) _ConfirmationCard(
              customer: _parsedCustomer,
              grain: _parsedGrain,
              weight: _parsedWeight,
              rate: _rate,
              amount: _amount,
              onPaid: () => _saveEntry(EntryStatus.paid),
              onCredit: () => _saveEntry(EntryStatus.credit),
              onEdit: _goToManualEntry,
            ),

            if (!_showConfirmation && !_isListening) ...[
              const Spacer(),
              TextButton.icon(
                onPressed: _goToManualEntry,
                icon: const Icon(Icons.edit_outlined, color: AppTheme.textMedium),
                label: const Text(
                  'हाताने लिहायचे आहे',
                  style: TextStyle(color: AppTheme.textMedium, fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfirmationCard extends StatelessWidget {
  final Customer? customer;
  final GrainType? grain;
  final double? weight;
  final double rate;
  final double amount;
  final VoidCallback onPaid;
  final VoidCallback onCredit;
  final VoidCallback onEdit;

  const _ConfirmationCard({
    required this.customer,
    required this.grain,
    required this.weight,
    required this.rate,
    required this.amount,
    required this.onPaid,
    required this.onCredit,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = customer != null && grain != null && weight != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isComplete ? AppTheme.primary.withOpacity(0.3) : AppTheme.credit.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row(
            label: 'ग्राहक',
            value: customer?.name ?? '❌ सापडला नाही',
            ok: customer != null,
          ),
          const Divider(height: 20),
          _Row(
            label: 'धान्य',
            value: grain != null ? '${grain!.emoji} ${grain!.displayName}' : '❌ सापडले नाही',
            ok: grain != null,
          ),
          const Divider(height: 20),
          _Row(
            label: 'वजन',
            value: weight != null ? AppHelpers.formatWeight(weight!) : '❌ सापडले नाही',
            ok: weight != null,
          ),
          if (isComplete) ...[
            const Divider(height: 20),
            _Row(
              label: 'दर',
              value: '₹$rate/किलो',
              ok: true,
            ),
            const Divider(height: 20),
            _Row(
              label: 'रक्कम',
              value: AppHelpers.formatCurrency(amount),
              ok: true,
              isAmount: true,
            ),
          ],
          const SizedBox(height: 16),
          if (isComplete)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onPaid,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.paid,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('दिले ✓', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onCredit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.credit,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('उधारी', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('बदल करा'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: AppTheme.primary),
                foregroundColor: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool ok;
  final bool isAmount;

  const _Row({
    required this.label,
    required this.value,
    required this.ok,
    this.isAmount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, color: AppTheme.textMedium, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isAmount ? 20 : 16,
            fontWeight: isAmount ? FontWeight.w800 : FontWeight.w700,
            color: isAmount ? AppTheme.primary : (ok ? AppTheme.textDark : AppTheme.credit),
          ),
        ),
      ],
    );
  }
}
