import 'package:flutter/material.dart';
import 'tariff_config.dart';
import 'solar_config.dart';

enum PropertyType {
  residence,
  office,
  shop,
  industrial,
  other;

  String get displayName {
    switch (this) {
      case PropertyType.residence:
        return 'Residence';
      case PropertyType.office:
        return 'Office';
      case PropertyType.shop:
        return 'Shop';
      case PropertyType.industrial:
        return 'Industrial';
      case PropertyType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case PropertyType.residence:
        return Icons.home_rounded;
      case PropertyType.office:
        return Icons.business_rounded;
      case PropertyType.shop:
        return Icons.storefront_rounded;
      case PropertyType.industrial:
        return Icons.factory_rounded;
      case PropertyType.other:
        return Icons.location_city_rounded;
    }
  }

  Color get color {
    switch (this) {
      case PropertyType.residence:
        return const Color(0xFF0F766E); // Emerald
      case PropertyType.office:
        return const Color(0xFF0284C7); // Electric Cyan/Blue
      case PropertyType.shop:
        return const Color(0xFFD97706); // Warm Amber
      case PropertyType.industrial:
        return const Color(0xFF7C3AED); // Purple
      case PropertyType.other:
        return const Color(0xFF64748B); // Slate
    }
  }
}

class Household {
  final String id;
  final String name;
  final String location;
  final PropertyType propertyType;
  final int daysInMonth;
  final double? actualLastMonthBill;
  final double? actualLastMonthUnits;
  final DateTime createdAt;
  final TariffConfig? tariffConfig;
  final SolarConfig? solarConfig;
  final double? customSolarKwh;
  final double? inverterVoltage;
  final double? inverterCurrent;

  const Household({
    required this.id,
    required this.name,
    this.location = 'Default Location',
    this.propertyType = PropertyType.residence,
    this.daysInMonth = 30,
    this.actualLastMonthBill,
    this.actualLastMonthUnits,
    required this.createdAt,
    this.tariffConfig,
    this.solarConfig,
    this.customSolarKwh,
    this.inverterVoltage,
    this.inverterCurrent,
  });

  Household copyWith({
    String? id,
    String? name,
    String? location,
    PropertyType? propertyType,
    int? daysInMonth,
    double? actualLastMonthBill,
    double? actualLastMonthUnits,
    DateTime? createdAt,
    TariffConfig? tariffConfig,
    SolarConfig? solarConfig,
    double? customSolarKwh,
    double? inverterVoltage,
    double? inverterCurrent,
  }) {
    return Household(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      propertyType: propertyType ?? this.propertyType,
      daysInMonth: daysInMonth ?? this.daysInMonth,
      actualLastMonthBill: actualLastMonthBill ?? this.actualLastMonthBill,
      actualLastMonthUnits: actualLastMonthUnits ?? this.actualLastMonthUnits,
      createdAt: createdAt ?? this.createdAt,
      tariffConfig: tariffConfig ?? this.tariffConfig,
      solarConfig: solarConfig ?? this.solarConfig,
      customSolarKwh: customSolarKwh ?? this.customSolarKwh,
      inverterVoltage: inverterVoltage ?? this.inverterVoltage,
      inverterCurrent: inverterCurrent ?? this.inverterCurrent,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'propertyType': propertyType.name,
        'daysInMonth': daysInMonth,
        'actualLastMonthBill': actualLastMonthBill,
        'actualLastMonthUnits': actualLastMonthUnits,
        'createdAt': createdAt.toIso8601String(),
        if (tariffConfig != null) 'tariffConfig': tariffConfig!.toJson(),
        if (solarConfig != null) 'solarConfig': solarConfig!.toJson(),
        if (customSolarKwh != null) 'customSolarKwh': customSolarKwh,
        if (inverterVoltage != null) 'inverterVoltage': inverterVoltage,
        if (inverterCurrent != null) 'inverterCurrent': inverterCurrent,
      };

  factory Household.fromJson(Map<String, dynamic> json) {
    PropertyType pType = PropertyType.residence;
    final typeStr = json['propertyType'] as String?;
    if (typeStr != null) {
      pType = PropertyType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => PropertyType.residence,
      );
    }

    TariffConfig? tariff;
    if (json['tariffConfig'] is Map<String, dynamic>) {
      try {
        tariff = TariffConfig.fromJson(json['tariffConfig'] as Map<String, dynamic>);
      } catch (_) {}
    }

    SolarConfig? solar;
    if (json['solarConfig'] is Map<String, dynamic>) {
      try {
        solar = SolarConfig.fromJson(json['solarConfig'] as Map<String, dynamic>);
      } catch (_) {}
    }

    return Household(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String? ?? 'Default Location',
      propertyType: pType,
      daysInMonth: (json['daysInMonth'] as num?)?.toInt() ?? 30,
      actualLastMonthBill: (json['actualLastMonthBill'] as num?)?.toDouble(),
      actualLastMonthUnits: (json['actualLastMonthUnits'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      tariffConfig: tariff,
      solarConfig: solar,
      customSolarKwh: (json['customSolarKwh'] as num?)?.toDouble(),
      inverterVoltage: (json['inverterVoltage'] as num?)?.toDouble(),
      inverterCurrent: (json['inverterCurrent'] as num?)?.toDouble(),
    );
  }
}
