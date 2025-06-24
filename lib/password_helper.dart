import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class PasswordHelper {
  static String generatePassword(String duration, String extraInput) {
    final now = DateTime.now().toUtc();
    const salt = "ENIGMA_SALT_2025";
    
    final weekNum = _getJSWeekNumber(now);
    final base = _getBaseString(duration, now, weekNum);
    final hashInput = extraInput + salt + base;
    
    // Debug output
    debugPrint('⏱️ Current UTC Time: ${now.toIso8601String()}');
    debugPrint('🔄 Duration Mode: $duration');
    debugPrint('🔑 Extra Input: "$extraInput"');
    debugPrint('📅 Week Number: $weekNum');
    debugPrint('🔢 Base String: "$base"');
    debugPrint('🧩 Combined Input: "$hashInput"');

    final hashBytes = sha256.convert(utf8.encode(hashInput));
    final password = hashBytes.toString().substring(0,12);
    
    debugPrint('✅ Generated Password: "$password"');
    debugPrint('----------------------------------');
    
    return password;
  }

  static int _getJSWeekNumber(DateTime date) {
    final yearStart = DateTime.utc(date.year, 1, 1);
    final daysPassed = date.difference(yearStart).inDays;
    final weekNum = ((daysPassed + yearStart.weekday) / 7).ceil();
    
    debugPrint('📆 Week Calculation:');
    debugPrint('  - Year Start: ${yearStart.toIso8601String()}');
    debugPrint('  - Days Passed: $daysPassed');
    debugPrint('  - Year Start Weekday: ${yearStart.weekday}');
    debugPrint('  - Calculated Week: $weekNum');
    
    return weekNum;
  }

  static String _getBaseString(String duration, DateTime date, int weekNum) {
    switch(duration) {
      case 'daily': 
        return DateFormat('yyyyMMdd').format(date);
      case 'weekly': 
        return '${date.year}W$weekNum';
      case 'monthly': 
        return DateFormat('yyyyMM').format(date);
      case 'annually': 
        return date.year.toString();
      default: 
        throw Exception('Invalid duration: $duration');
    }
  }
}