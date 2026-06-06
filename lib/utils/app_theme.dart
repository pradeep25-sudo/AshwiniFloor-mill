import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1B7F3E);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color accent = Color(0xFFFF6B35);
  static const Color paid = Color(0xFF2E7D32);
  static const Color credit = Color(0xFFC62828);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMedium = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color shadow = Color(0x0F000000);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: divider, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(fontSize: 16),
      ),
    );
  }
}

class AppStrings {
  static const appName = 'अश्विनी खाता';
  static const tagline = 'तुमच्या गिरणीचे स्मार्ट हिशेब';
  static const newEntry = 'नवीन नोंद';
  static const receivePayment = 'पैसे मिळवा';
  static const customers = 'ग्राहक';
  static const reports = 'अहवाल';
  static const settings = 'सेटिंग्ज';
  static const todayEarnings = 'आजची कमाई';
  static const todayCustomers = 'आजचे ग्राहक';
  static const pendingAmount = 'उधारी रक्कम';
  static const totalGrain = 'एकूण धान्य';
  static const paid = 'दिले ✓';
  static const credit = 'उधारी';
  static const save = 'जतन करा';
  static const cancel = 'रद्द करा';
  static const delete = 'हटवा';
  static const search = 'शोधा...';
  static const addCustomer = 'नवीन ग्राहक';
  static const weight = 'वजन (किलो)';
  static const amount = 'रक्कम';
  static const rate = 'दर';
  static const grain = 'धान्य';
  static const customer = 'ग्राहक';
  static const date = 'तारीख';
  static const back = 'मागे';
  static const paymentReceived = 'पैसे मिळाले';
  static const allPaid = 'सर्व उधारी चुकती';
  static const partialPayment = 'काही पैसे';
  static const history = 'इतिहास';
  static const paymentHistory = 'पेमेंट इतिहास';
  static const noEntries = 'अजून नोंदी नाहीत';
  static const noCustomers = 'अजून ग्राहक नाहीत';
  static const rateSettings = 'दर सेटिंग्ज';
  static const backup = 'बॅकअप';
  static const exportBackup = 'बॅकअप एक्सपोर्ट';
  static const importBackup = 'बॅकअप इम्पोर्ट';
  static const daily = 'दैनिक';
  static const monthly = 'मासिक';
  static const voiceEntry = 'आवाज नोंद';
}
