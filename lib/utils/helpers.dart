import 'package:intl/intl.dart';

class AppHelpers {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'hi_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _weightFormat = NumberFormat('#,##0.##');

  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  static String formatWeight(double weight) {
    return '${_weightFormat.format(weight)} किलो';
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'आज';
    if (dateOnly == yesterday) return 'काल';
    return DateFormat('dd MMM yyyy', 'hi').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatDateForDisplay(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'hi').format(date);
  }

  static String formatTime(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$h:${minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return time;
    }
  }

  static String formatDateTime(DateTime dt) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  static String getMonthName(int month) {
    const months = [
      'जानेवारी', 'फेब्रुवारी', 'मार्च', 'एप्रिल', 'मे', 'जून',
      'जुलै', 'ऑगस्ट', 'सप्टेंबर', 'ऑक्टोबर', 'नोव्हेंबर', 'डिसेंबर'
    ];
    return months[month - 1];
  }

  // Parse Marathi/Hindi number words to digits
  static double? parseMarathiNumber(String text) {
    final numMap = {
      'एक': 1, 'दोन': 2, 'तीन': 3, 'चार': 4, 'पाच': 5,
      'सहा': 6, 'सात': 7, 'आठ': 8, 'नऊ': 9, 'दहा': 10,
      'पंधरा': 15, 'वीस': 20, 'पंचवीस': 25, 'तीस': 30,
      'पन्नास': 50, 'शंभर': 100,
    };
    
    final lower = text.toLowerCase().trim();
    if (numMap.containsKey(lower)) {
      return numMap[lower]!.toDouble();
    }
    
    // Try direct parse
    final cleaned = lower.replaceAll(',', '').replaceAll(' ', '');
    return double.tryParse(cleaned);
  }

  // Extract grain info from voice text
  static Map<String, String?> extractVoiceInfo(String text) {
    final result = <String, String?>{
      'customer': null,
      'grain': null,
      'weight': null,
    };

    final grainKeywords = {
      'गहू': 'wheat', 'गेहू': 'wheat', 'wheat': 'wheat',
      'ज्वारी': 'jowar', 'ज्वार': 'jowar', 'jowar': 'jowar',
      'बाजरी': 'bajra', 'बाजरा': 'bajra', 'bajra': 'bajra',
      'तांदूळ': 'rice', 'तांदुळ': 'rice', 'rice': 'rice',
      'मका': 'maize', 'maize': 'maize',
      'इतर': 'other', 'other': 'other',
    };

    for (final entry in grainKeywords.entries) {
      if (text.contains(entry.key)) {
        result['grain'] = entry.value;
        break;
      }
    }

    // Extract weight (number before or after grain keyword)
    final weightRegex = RegExp(r'(\d+(?:\.\d+)?)\s*(?:किलो|kg|किग्रा|k)?');
    final weightMatch = weightRegex.firstMatch(text);
    if (weightMatch != null) {
      result['weight'] = weightMatch.group(1);
    }

    return result;
  }
}
