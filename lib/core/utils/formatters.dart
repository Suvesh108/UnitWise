import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/appliance_template.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat('#,##,##0', 'en_IN');
  static final NumberFormat _decimalFormat = NumberFormat('0.0');
  static final NumberFormat _twoDecimalFormat = NumberFormat('0.00');

  static String formatCurrency(double amount, {String symbol = '₹'}) {
    return '$symbol${_currencyFormat.format(amount.round())}';
  }

  static String formatDecimal(double value) {
    return _decimalFormat.format(value);
  }

  static String formatUnits(double kwh) {
    return '${_decimalFormat.format(kwh)} kWh';
  }

  static String formatRate(double rate, {String symbol = '₹'}) {
    return '$symbol${_twoDecimalFormat.format(rate)}/unit';
  }

  static IconData getCategoryIcon(ApplianceCategory category) {
    switch (category) {
      case ApplianceCategory.cooling:
        return Icons.air;
      case ApplianceCategory.kitchen:
        return Icons.kitchen_outlined;
      case ApplianceCategory.lighting:
        return Icons.lightbulb_outline;
      case ApplianceCategory.laundry:
        return Icons.local_laundry_service_outlined;
      case ApplianceCategory.entertainment:
        return Icons.tv_outlined;
      case ApplianceCategory.heating:
        return Icons.hot_tub_outlined;
      case ApplianceCategory.waterPumps:
        return Icons.water_drop_outlined;
      case ApplianceCategory.other:
        return Icons.devices_other_outlined;
    }
  }

  static String getCategoryName(ApplianceCategory category) {
    switch (category) {
      case ApplianceCategory.cooling:
        return 'Cooling';
      case ApplianceCategory.kitchen:
        return 'Kitchen';
      case ApplianceCategory.lighting:
        return 'Lighting';
      case ApplianceCategory.laundry:
        return 'Laundry';
      case ApplianceCategory.entertainment:
        return 'Entertainment';
      case ApplianceCategory.heating:
        return 'Heating';
      case ApplianceCategory.waterPumps:
        return 'Water Pumps';
      case ApplianceCategory.other:
        return 'Other';
    }
  }

  static Color getCategoryColor(ApplianceCategory category) {
    switch (category) {
      case ApplianceCategory.cooling:
        return const Color(0xFF0EA5E9); // Cyan
      case ApplianceCategory.kitchen:
        return const Color(0xFFF97316); // Orange
      case ApplianceCategory.lighting:
        return const Color(0xFFEAB308); // Yellow
      case ApplianceCategory.laundry:
        return const Color(0xFF8B5CF6); // Purple
      case ApplianceCategory.entertainment:
        return const Color(0xFFEC4899); // Pink
      case ApplianceCategory.heating:
        return const Color(0xFFEF4444); // Red
      case ApplianceCategory.waterPumps:
        return const Color(0xFF06B6D4); // Teal
      case ApplianceCategory.other:
        return const Color(0xFF64748B); // Slate
    }
  }
}
