enum TariffType {
  flat,
  tieredSlab,
}

class TariffSlab {
  final double fromUnits;
  final double toUnits; // Use double.infinity for no upper bound
  final double ratePerKwh;

  const TariffSlab({
    required this.fromUnits,
    required this.toUnits,
    required this.ratePerKwh,
  });

  Map<String, dynamic> toJson() => {
        'fromUnits': fromUnits,
        'toUnits': toUnits.isInfinite ? -1 : toUnits,
        'ratePerKwh': ratePerKwh,
      };

  factory TariffSlab.fromJson(Map<String, dynamic> json) {
    final to = (json['toUnits'] as num).toDouble();
    return TariffSlab(
      fromUnits: (json['fromUnits'] as num).toDouble(),
      toUnits: to < 0 ? double.infinity : to,
      ratePerKwh: (json['ratePerKwh'] as num).toDouble(),
    );
  }
}

class TariffConfig {
  final String id;
  final String name;
  final TariffType type;
  final double flatRatePerKwh;
  final List<TariffSlab> slabs;
  final double fixedCharge;
  final double taxPercentage;
  final double fpppaRatePerKwh; // Fuel & Power Purchase Price Adjustment
  final String currencySymbol;

  const TariffConfig({
    required this.id,
    required this.name,
    this.type = TariffType.tieredSlab,
    this.flatRatePerKwh = 6.5,
    this.slabs = const [
      TariffSlab(fromUnits: 0, toUnits: 100, ratePerKwh: 3.5),
      TariffSlab(fromUnits: 100, toUnits: 200, ratePerKwh: 5.5),
      TariffSlab(fromUnits: 200, toUnits: 400, ratePerKwh: 7.5),
      TariffSlab(fromUnits: 400, toUnits: double.infinity, ratePerKwh: 9.5),
    ],
    this.fixedCharge = 120.0,
    this.taxPercentage = 9.0,
    this.fpppaRatePerKwh = 0.35,
    this.currencySymbol = '₹',
  });

  TariffConfig copyWith({
    String? id,
    String? name,
    TariffType? type,
    double? flatRatePerKwh,
    List<TariffSlab>? slabs,
    double? fixedCharge,
    double? taxPercentage,
    double? fpppaRatePerKwh,
    String? currencySymbol,
  }) {
    return TariffConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      flatRatePerKwh: flatRatePerKwh ?? this.flatRatePerKwh,
      slabs: slabs ?? this.slabs,
      fixedCharge: fixedCharge ?? this.fixedCharge,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      fpppaRatePerKwh: fpppaRatePerKwh ?? this.fpppaRatePerKwh,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'flatRatePerKwh': flatRatePerKwh,
        'slabs': slabs.map((s) => s.toJson()).toList(),
        'fixedCharge': fixedCharge,
        'taxPercentage': taxPercentage,
        'fpppaRatePerKwh': fpppaRatePerKwh,
        'currencySymbol': currencySymbol,
      };

  factory TariffConfig.fromJson(Map<String, dynamic> json) {
    return TariffConfig(
      id: json['id'] as String? ?? 'custom',
      name: json['name'] as String? ?? 'Custom Tariff',
      type: TariffType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TariffType.tieredSlab,
      ),
      flatRatePerKwh: (json['flatRatePerKwh'] as num?)?.toDouble() ?? 6.5,
      slabs: (json['slabs'] as List<dynamic>?)
              ?.map((s) => TariffSlab.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [
            TariffSlab(fromUnits: 0, toUnits: 100, ratePerKwh: 3.5),
            TariffSlab(fromUnits: 100, toUnits: 200, ratePerKwh: 5.5),
            TariffSlab(fromUnits: 200, toUnits: 400, ratePerKwh: 7.5),
            TariffSlab(fromUnits: 400, toUnits: double.infinity, ratePerKwh: 9.5),
          ],
      fixedCharge: (json['fixedCharge'] as num?)?.toDouble() ?? 120.0,
      taxPercentage: (json['taxPercentage'] as num?)?.toDouble() ?? 9.0,
      fpppaRatePerKwh: (json['fpppaRatePerKwh'] as num?)?.toDouble() ?? 0.35,
      currencySymbol: json['currencySymbol'] as String? ?? '₹',
    );
  }
}
