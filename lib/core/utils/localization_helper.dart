import 'package:flutter/material.dart';

extension LocalizationHelper on BuildContext {
  /// Check if the current locale is Arabic
  bool get isAr => Localizations.localeOf(this).languageCode == 'ar';

  /// Extract the appropriate localized string from a Supabase row mapping.
  /// Examples of expected fields: `name` (English fallback), `name_ar` (Arabic).
  /// If the locale is 'ar' and `key_ar` exists and is not empty, it returns that.
  /// Otherwise, it returns the value of `key`.
  String getLocalized(Map<String, dynamic>? data, String key) {
    if (data == null) return '';
    
    if (isAr) {
      final arKey = '${key}_ar';
      final arValue = data[arKey];
      if (arValue != null && arValue.toString().trim().isNotEmpty) {
        return arValue.toString();
      }
    }
    
    // Fallback to English (or whatever is in the base key)
    final enKey = '${key}_en';
    return data[enKey]?.toString() ?? data[key]?.toString() ?? data['text']?.toString() ?? '';
  }
}
