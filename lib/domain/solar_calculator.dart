import '../data/models/solar_config.dart';

class SolarCalculationResult {
  final double monthlyConsumptionKwh;
  final double recommendedKw;
  final double effectiveInstalledKw;
  final bool isRoofConstrained;
  final double roofAreaRequiredSqFt;
  final double dailyGenerationKwh;
  final double monthlyGenerationKwh;
  final double annualGenerationKwh;
  final double selfConsumedKwhMonthly;
  final double exportedKwhMonthly;
  final double grossCost;
  final double subsidyAmount;
  final double netCost;
  final double monthlySavings;
  final double annualSavings;
  final double paybackPeriodYears;
  final double co2OffsetKgAnnual;
  final double lifetimeNetSavings25Years;
  final String recommendationSummary;

  const SolarCalculationResult({
    required this.monthlyConsumptionKwh,
    required this.recommendedKw,
    required this.effectiveInstalledKw,
    required this.isRoofConstrained,
    required this.roofAreaRequiredSqFt,
    required this.dailyGenerationKwh,
    required this.monthlyGenerationKwh,
    required this.annualGenerationKwh,
    required this.selfConsumedKwhMonthly,
    required this.exportedKwhMonthly,
    required this.grossCost,
    required this.subsidyAmount,
    required this.netCost,
    required this.monthlySavings,
    required this.annualSavings,
    required this.paybackPeriodYears,
    required this.co2OffsetKgAnnual,
    required this.lifetimeNetSavings25Years,
    required this.recommendationSummary,
  });

  static const SolarCalculationResult empty = SolarCalculationResult(
    monthlyConsumptionKwh: 0,
    recommendedKw: 0,
    effectiveInstalledKw: 0,
    isRoofConstrained: false,
    roofAreaRequiredSqFt: 0,
    dailyGenerationKwh: 0,
    monthlyGenerationKwh: 0,
    annualGenerationKwh: 0,
    selfConsumedKwhMonthly: 0,
    exportedKwhMonthly: 0,
    grossCost: 0,
    subsidyAmount: 0,
    netCost: 0,
    monthlySavings: 0,
    annualSavings: 0,
    paybackPeriodYears: 0,
    co2OffsetKgAnnual: 0,
    lifetimeNetSavings25Years: 0,
    recommendationSummary: '',
  );
}

class NetEnergyBalance {
  final double solarMonthlyKwh;
  final double applianceMonthlyKwh;
  final double netBalanceKwh; // Positive = Surplus Exported to Grid, Negative = Grid Import Needed
  final bool isSurplus;
  final double offsetPercentage; // (solar / appliance) * 100
  final double originalBill;
  final double solarNetBill;
  final double monthlySavings;
  final double exportEarnings;
  final double gridImportKwh;
  final double gridExportKwh;

  const NetEnergyBalance({
    required this.solarMonthlyKwh,
    required this.applianceMonthlyKwh,
    required this.netBalanceKwh,
    required this.isSurplus,
    required this.offsetPercentage,
    required this.originalBill,
    required this.solarNetBill,
    required this.monthlySavings,
    required this.exportEarnings,
    required this.gridImportKwh,
    required this.gridExportKwh,
  });

  double get netKwh => netBalanceKwh;

  static const NetEnergyBalance empty = NetEnergyBalance(
    solarMonthlyKwh: 0,
    applianceMonthlyKwh: 0,
    netBalanceKwh: 0,
    isSurplus: true,
    offsetPercentage: 0,
    originalBill: 0,
    solarNetBill: 0,
    monthlySavings: 0,
    exportEarnings: 0,
    gridImportKwh: 0,
    gridExportKwh: 0,
  );
}

class SolarCalculator {
  /// Calculate subsidy under various schemes
  static double calculateSubsidy({
    required double systemKw,
    required double grossCost,
    required SolarConfig config,
  }) {
    if (systemKw <= 0) return 0.0;

    switch (config.subsidyScheme) {
      case SubsidyScheme.pmSuryaGharIndia:
        // PM Surya Ghar Scheme rules:
        // Up to 1 kW: ₹30,000
        // 1 to 2 kW: ₹30,000 + (kW - 1.0) * ₹30,000 (up to ₹60,000 for 2 kW)
        // 2 to 3 kW: ₹60,000 + (kW - 2.0) * ₹18,000 (up to ₹78,000 for 3 kW)
        // Above 3 kW: capped at ₹78,000 flat
        if (systemKw <= 1.0) {
          return 30000.0 * systemKw;
        } else if (systemKw <= 2.0) {
          return 30000.0 + (systemKw - 1.0) * 30000.0;
        } else if (systemKw <= 3.0) {
          return 60000.0 + (systemKw - 2.0) * 18000.0;
        } else {
          return 78000.0;
        }

      case SubsidyScheme.customFixed:
        return config.customSubsidyAmount.clamp(0.0, grossCost);

      case SubsidyScheme.customPercentage:
        final pct = config.customSubsidyPercent.clamp(0.0, 100.0);
        return (grossCost * pct) / 100.0;

      case SubsidyScheme.none:
        return 0.0;
    }
  }

  /// Sizing and financial returns engine
  static SolarCalculationResult calculateSolar({
    required double monthlyConsumptionKwh,
    required double effectiveRetailTariff,
    required SolarConfig config,
    int monthDays = 30,
  }) {
    if (monthlyConsumptionKwh <= 0) {
      return SolarCalculationResult.empty;
    }

    // 1. Target daily energy
    final targetDailyKwh = (monthlyConsumptionKwh * (config.targetOffsetPercent / 100.0)) / monthDays;

    // 2. Solar sizing formula: Solar kW = Target daily energy / (Peak sun hours * Performance ratio)
    final denominator = config.peakSunHours * config.performanceRatio;
    final exactRequiredKw = denominator > 0 ? targetDailyKwh / denominator : 0.0;

    // Standardize to rounded practical increments (0.5 kW steps, min 1.0 kW)
    double recommendedKw = (exactRequiredKw * 2).round() / 2.0;
    if (recommendedKw < 1.0 && exactRequiredKw > 0.2) recommendedKw = 1.0;

    // 3. Roof space constraint check
    final maxRoofKw = config.availableRoofAreaSqFt / config.sqFtPerKw;
    final isRoofConstrained = recommendedKw > maxRoofKw;
    final effectiveInstalledKw = isRoofConstrained ? (maxRoofKw * 2).floor() / 2.0 : recommendedKw;
    final roofAreaRequiredSqFt = effectiveInstalledKw * config.sqFtPerKw;

    // 4. Expected Generation
    final dailyGenerationKwh = effectiveInstalledKw * config.peakSunHours * config.performanceRatio;
    final monthlyGenerationKwh = dailyGenerationKwh * monthDays;
    final annualGenerationKwh = dailyGenerationKwh * 365.0;

    // 5. Self-consumption vs Grid Export
    // Self-consumption cannot exceed household monthly consumption
    final potentialSelfConsumed = monthlyGenerationKwh * config.selfConsumptionRatio;
    final selfConsumedKwhMonthly = potentialSelfConsumed < monthlyConsumptionKwh
        ? potentialSelfConsumed
        : monthlyConsumptionKwh;
    final exportedKwhMonthly = (monthlyGenerationKwh - selfConsumedKwhMonthly).clamp(0.0, double.infinity);

    // 6. Savings
    final directBillOffsetMonthly = selfConsumedKwhMonthly * effectiveRetailTariff;
    final exportCreditMonthly = exportedKwhMonthly * config.exportTariffPerKwh;
    final monthlySavings = directBillOffsetMonthly + exportCreditMonthly;
    final annualSavings = monthlySavings * 12.0;

    // 7. Costs and Subsidies
    final grossCost = effectiveInstalledKw * config.costPerKw;
    final subsidyAmount = calculateSubsidy(
      systemKw: effectiveInstalledKw,
      grossCost: grossCost,
      config: config,
    );
    final netCost = (grossCost - subsidyAmount).clamp(0.0, double.infinity);

    // 8. Payback period
    final paybackPeriodYears = annualSavings > 0 ? netCost / annualSavings : 0.0;

    // 9. Environmental and 25-Year Lifetime Returns (with 0.7% annual panel degradation)
    final co2OffsetKgAnnual = annualGenerationKwh * 0.82; // 0.82 kg CO2 per kWh grid offset

    double lifetimeGrossSavings = 0.0;
    double currentYearSavings = annualSavings;
    for (int year = 1; year <= 25; year++) {
      lifetimeGrossSavings += currentYearSavings;
      currentYearSavings *= 0.993; // 0.7% degradation per year
    }
    final lifetimeNetSavings25Years = lifetimeGrossSavings - netCost;

    // Recommendation text
    String summary = '';
    if (isRoofConstrained) {
      summary = 'Your roof allows max ${effectiveInstalledKw.toStringAsFixed(1)} kW (needs ${recommendedKw.toStringAsFixed(1)} kW for 100% offset). It will still cover ${((monthlyGenerationKwh / monthlyConsumptionKwh) * 100).toStringAsFixed(0)}% of your monthly bill.';
    } else {
      summary = 'A ${effectiveInstalledKw.toStringAsFixed(1)} kW rooftop system offsets ~${((monthlyGenerationKwh / monthlyConsumptionKwh) * 100).toStringAsFixed(0)}% of your electricity consumption with a ${paybackPeriodYears.toStringAsFixed(1)}-year payback.';
    }

    return SolarCalculationResult(
      monthlyConsumptionKwh: monthlyConsumptionKwh,
      recommendedKw: recommendedKw,
      effectiveInstalledKw: effectiveInstalledKw,
      isRoofConstrained: isRoofConstrained,
      roofAreaRequiredSqFt: roofAreaRequiredSqFt,
      dailyGenerationKwh: dailyGenerationKwh,
      monthlyGenerationKwh: monthlyGenerationKwh,
      annualGenerationKwh: annualGenerationKwh,
      selfConsumedKwhMonthly: selfConsumedKwhMonthly,
      exportedKwhMonthly: exportedKwhMonthly,
      grossCost: grossCost,
      subsidyAmount: subsidyAmount,
      netCost: netCost,
      monthlySavings: monthlySavings,
      annualSavings: annualSavings,
      paybackPeriodYears: paybackPeriodYears,
      co2OffsetKgAnnual: co2OffsetKgAnnual,
      lifetimeNetSavings25Years: lifetimeNetSavings25Years,
      recommendationSummary: summary,
    );
  }

  /// Real-time Solar Generation vs Household Appliances Net Metering Balance
  /// Solar Generation (kWh) - Appliance Load (kWh) = Net Grid Balance (kWh)
  static NetEnergyBalance calculateNetBalance({
    required double solarMonthlyKwh,
    required double applianceMonthlyKwh,
    required double retailRatePerKwh,
    required double exportRatePerKwh,
    double fixedCharges = 0.0,
  }) {
    final netKwh = solarMonthlyKwh - applianceMonthlyKwh;
    final isSurplus = netKwh >= 0;
    final offsetPct = applianceMonthlyKwh > 0
        ? (solarMonthlyKwh / applianceMonthlyKwh) * 100.0
        : (solarMonthlyKwh > 0 ? 100.0 : 0.0);

    final gridImportKwh = isSurplus ? 0.0 : -netKwh;
    final gridExportKwh = isSurplus ? netKwh : 0.0;

    final originalBill = (applianceMonthlyKwh * retailRatePerKwh) + fixedCharges;
    final exportEarnings = gridExportKwh * exportRatePerKwh;
    final gridEnergyCharge = gridImportKwh * retailRatePerKwh;

    // With net metering, export credits offset remaining charges
    final uncreditedBill = gridEnergyCharge + (gridImportKwh > 0 ? fixedCharges : 0.0);
    final solarNetBill = (uncreditedBill - exportEarnings).clamp(0.0, double.infinity);
    final monthlySavings = (originalBill - solarNetBill).clamp(0.0, originalBill + exportEarnings);

    return NetEnergyBalance(
      solarMonthlyKwh: solarMonthlyKwh,
      applianceMonthlyKwh: applianceMonthlyKwh,
      netBalanceKwh: netKwh,
      isSurplus: isSurplus,
      offsetPercentage: offsetPct,
      originalBill: originalBill,
      solarNetBill: solarNetBill,
      monthlySavings: monthlySavings,
      exportEarnings: exportEarnings,
      gridImportKwh: gridImportKwh,
      gridExportKwh: gridExportKwh,
    );
  }

  /// Helper to calculate Monthly kWh from Voltage (V), Amperage (A), and Daily Peak Sun Hours
  /// Power (Watts) = Voltage (V) * Current (A)
  /// Daily kWh = (Watts * Sun Hours) / 1000
  /// Monthly kWh = Daily kWh * Days
  static double calculateKwhFromElectricalSpecs({
    required double voltageVolts,
    required double currentAmps,
    double peakSunHours = 5.0,
    int days = 30,
  }) {
    final watts = voltageVolts * currentAmps;
    final dailyKwh = (watts * peakSunHours) / 1000.0;
    return dailyKwh * days;
  }
}
