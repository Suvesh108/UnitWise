enum SolarSystemType {
  onGrid,
  hybrid,
  offGrid,
}

enum SubsidyScheme {
  pmSuryaGharIndia, // PM Surya Ghar scheme: ₹30,000 for 1kW, ₹60,000 for 2kW, ₹78,000 for 3kW+
  customFixed,
  customPercentage,
  none,
}

class SolarConfig {
  final String locationName;
  final double peakSunHours;          // typically 4.2 - 5.5 in India/Sunbelt
  final double performanceRatio;      // system losses: inverter, thermal, wiring (0.75 - 0.82)
  final double availableRoofAreaSqFt; // Rooftop area in sq ft
  final double sqFtPerKw;             // Typically 100 sq ft per 1 kW panel array
  final SolarSystemType systemType;
  final double costPerKwOnGrid;
  final double costPerKwHybrid;
  final double costPerKwOffGrid;
  final double selfConsumptionRatio;  // Portion of solar energy used on-site (0.0 to 1.0)
  final double exportTariffPerKwh;    // Net metering export credit rate
  final SubsidyScheme subsidyScheme;
  final double customSubsidyAmount;
  final double customSubsidyPercent;
  final double targetOffsetPercent;   // Target % of monthly electricity to offset (e.g. 100%)

  const SolarConfig({
    this.locationName = 'Standard Sunbelt',
    this.peakSunHours = 4.8,
    this.performanceRatio = 0.78,
    this.availableRoofAreaSqFt = 400.0,
    this.sqFtPerKw = 100.0,
    this.systemType = SolarSystemType.onGrid,
    this.costPerKwOnGrid = 55000.0,
    this.costPerKwHybrid = 75000.0,
    this.costPerKwOffGrid = 85000.0,
    this.selfConsumptionRatio = 0.65,
    this.exportTariffPerKwh = 3.20,
    this.subsidyScheme = SubsidyScheme.pmSuryaGharIndia,
    this.customSubsidyAmount = 0.0,
    this.customSubsidyPercent = 20.0,
    this.targetOffsetPercent = 100.0,
  });

  double get costPerKw {
    switch (systemType) {
      case SolarSystemType.onGrid:
        return costPerKwOnGrid;
      case SolarSystemType.hybrid:
        return costPerKwHybrid;
      case SolarSystemType.offGrid:
        return costPerKwOffGrid;
    }
  }

  SolarConfig copyWith({
    String? locationName,
    double? peakSunHours,
    double? performanceRatio,
    double? availableRoofAreaSqFt,
    double? sqFtPerKw,
    SolarSystemType? systemType,
    double? costPerKwOnGrid,
    double? costPerKwHybrid,
    double? costPerKwOffGrid,
    double? selfConsumptionRatio,
    double? exportTariffPerKwh,
    SubsidyScheme? subsidyScheme,
    double? customSubsidyAmount,
    double? customSubsidyPercent,
    double? targetOffsetPercent,
  }) {
    return SolarConfig(
      locationName: locationName ?? this.locationName,
      peakSunHours: peakSunHours ?? this.peakSunHours,
      performanceRatio: performanceRatio ?? this.performanceRatio,
      availableRoofAreaSqFt: availableRoofAreaSqFt ?? this.availableRoofAreaSqFt,
      sqFtPerKw: sqFtPerKw ?? this.sqFtPerKw,
      systemType: systemType ?? this.systemType,
      costPerKwOnGrid: costPerKwOnGrid ?? this.costPerKwOnGrid,
      costPerKwHybrid: costPerKwHybrid ?? this.costPerKwHybrid,
      costPerKwOffGrid: costPerKwOffGrid ?? this.costPerKwOffGrid,
      selfConsumptionRatio: selfConsumptionRatio ?? this.selfConsumptionRatio,
      exportTariffPerKwh: exportTariffPerKwh ?? this.exportTariffPerKwh,
      subsidyScheme: subsidyScheme ?? this.subsidyScheme,
      customSubsidyAmount: customSubsidyAmount ?? this.customSubsidyAmount,
      customSubsidyPercent: customSubsidyPercent ?? this.customSubsidyPercent,
      targetOffsetPercent: targetOffsetPercent ?? this.targetOffsetPercent,
    );
  }

  Map<String, dynamic> toJson() => {
        'locationName': locationName,
        'peakSunHours': peakSunHours,
        'performanceRatio': performanceRatio,
        'availableRoofAreaSqFt': availableRoofAreaSqFt,
        'sqFtPerKw': sqFtPerKw,
        'systemType': systemType.name,
        'costPerKwOnGrid': costPerKwOnGrid,
        'costPerKwHybrid': costPerKwHybrid,
        'costPerKwOffGrid': costPerKwOffGrid,
        'selfConsumptionRatio': selfConsumptionRatio,
        'exportTariffPerKwh': exportTariffPerKwh,
        'subsidyScheme': subsidyScheme.name,
        'customSubsidyAmount': customSubsidyAmount,
        'customSubsidyPercent': customSubsidyPercent,
        'targetOffsetPercent': targetOffsetPercent,
      };

  factory SolarConfig.fromJson(Map<String, dynamic> json) {
    return SolarConfig(
      locationName: json['locationName'] as String? ?? 'Standard Sunbelt',
      peakSunHours: (json['peakSunHours'] as num?)?.toDouble() ?? 4.8,
      performanceRatio: (json['performanceRatio'] as num?)?.toDouble() ?? 0.78,
      availableRoofAreaSqFt: (json['availableRoofAreaSqFt'] as num?)?.toDouble() ?? 400.0,
      sqFtPerKw: (json['sqFtPerKw'] as num?)?.toDouble() ?? 100.0,
      systemType: SolarSystemType.values.firstWhere(
        (e) => e.name == json['systemType'],
        orElse: () => SolarSystemType.onGrid,
      ),
      costPerKwOnGrid: (json['costPerKwOnGrid'] as num?)?.toDouble() ?? 55000.0,
      costPerKwHybrid: (json['costPerKwHybrid'] as num?)?.toDouble() ?? 75000.0,
      costPerKwOffGrid: (json['costPerKwOffGrid'] as num?)?.toDouble() ?? 85000.0,
      selfConsumptionRatio: (json['selfConsumptionRatio'] as num?)?.toDouble() ?? 0.65,
      exportTariffPerKwh: (json['exportTariffPerKwh'] as num?)?.toDouble() ?? 3.20,
      subsidyScheme: SubsidyScheme.values.firstWhere(
        (e) => e.name == json['subsidyScheme'],
        orElse: () => SubsidyScheme.pmSuryaGharIndia,
      ),
      customSubsidyAmount: (json['customSubsidyAmount'] as num?)?.toDouble() ?? 0.0,
      customSubsidyPercent: (json['customSubsidyPercent'] as num?)?.toDouble() ?? 20.0,
      targetOffsetPercent: (json['targetOffsetPercent'] as num?)?.toDouble() ?? 100.0,
    );
  }
}
