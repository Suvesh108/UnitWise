import '../data/models/appliance_template.dart';
import '../data/models/household_appliance.dart';

class ApplianceConsumptionResult {
  final HouseholdAppliance appliance;
  final double monthlyKwh;
  final double dailyKwh;
  final double percentageOfTotal;

  const ApplianceConsumptionResult({
    required this.appliance,
    required this.monthlyKwh,
    required this.dailyKwh,
    this.percentageOfTotal = 0.0,
  });

  ApplianceConsumptionResult copyWith({double? percentageOfTotal}) {
    return ApplianceConsumptionResult(
      appliance: appliance,
      monthlyKwh: monthlyKwh,
      dailyKwh: dailyKwh,
      percentageOfTotal: percentageOfTotal ?? this.percentageOfTotal,
    );
  }
}

class CategoryConsumptionResult {
  final ApplianceCategory category;
  final double monthlyKwh;
  final double percentageOfTotal;
  final int applianceCount;

  const CategoryConsumptionResult({
    required this.category,
    required this.monthlyKwh,
    required this.percentageOfTotal,
    required this.applianceCount,
  });
}

class HouseholdConsumptionSummary {
  final double totalMonthlyKwh;
  final double averageDailyKwh;
  final List<ApplianceConsumptionResult> applianceResults;
  final List<CategoryConsumptionResult> categoryResults;
  final List<ApplianceConsumptionResult> topConsumers;

  const HouseholdConsumptionSummary({
    required this.totalMonthlyKwh,
    required this.averageDailyKwh,
    required this.applianceResults,
    required this.categoryResults,
    required this.topConsumers,
  });

  static const HouseholdConsumptionSummary empty = HouseholdConsumptionSummary(
    totalMonthlyKwh: 0.0,
    averageDailyKwh: 0.0,
    applianceResults: [],
    categoryResults: [],
    topConsumers: [],
  );
}

class EnergyCalculator {
  /// Profile multiplier: Low = 0.8x, Normal = 1.0x, Heavy = 1.25x
  static double getUsageMultiplier(UsageProfile profile) {
    switch (profile) {
      case UsageProfile.low:
        return 0.8;
      case UsageProfile.normal:
        return 1.0;
      case UsageProfile.heavy:
        return 1.25;
    }
  }

  /// Calculates monthly kWh for an individual appliance
  static double calculateApplianceMonthlyKwh(
    HouseholdAppliance item, {
    int monthDays = 30,
  }) {
    final multiplier = getUsageMultiplier(item.usageProfile);
    // Bound days to monthDays
    final effectiveDays = item.daysPerMonth.clamp(1, monthDays);

    switch (item.calculationType) {
      case CalculationType.continuous:
        // (W * H * D * Q) / 1000 * multiplier
        final kwh = (item.wattage * item.hoursPerDay * effectiveDays * item.quantity) / 1000.0;
        return kwh * multiplier;

      case CalculationType.dutyCycle:
        // (W * dutyCycle * H * D * Q) / 1000 * multiplier
        final effectiveDuty = item.dutyCycle.clamp(0.01, 1.0);
        final kwh = (item.wattage * effectiveDuty * item.hoursPerDay * effectiveDays * item.quantity) / 1000.0;
        return kwh * multiplier;

      case CalculationType.perCycle:
        // kwhPerCycle * cyclesPerMonth * Q * multiplier
        final kwh = item.kwhPerCycle * item.cyclesPerMonth * item.quantity;
        return kwh * multiplier;
    }
  }

  /// Calculates the complete household summary
  static HouseholdConsumptionSummary calculateHouseholdSummary(
    List<HouseholdAppliance> appliances, {
    int monthDays = 30,
  }) {
    if (appliances.isEmpty) {
      return HouseholdConsumptionSummary.empty;
    }

    double totalMonthlyKwh = 0.0;
    final List<ApplianceConsumptionResult> initialResults = [];

    for (final app in appliances) {
      final monthly = calculateApplianceMonthlyKwh(app, monthDays: monthDays);
      final daily = monthDays > 0 ? monthly / monthDays : 0.0;
      totalMonthlyKwh += monthly;
      initialResults.add(
        ApplianceConsumptionResult(
          appliance: app,
          monthlyKwh: monthly,
          dailyKwh: daily,
        ),
      );
    }

    // Sort descending by monthly consumption
    initialResults.sort((a, b) => b.monthlyKwh.compareTo(a.monthlyKwh));

    // Calculate percentages
    final List<ApplianceConsumptionResult> applianceResults = initialResults.map((r) {
      final pct = totalMonthlyKwh > 0 ? (r.monthlyKwh / totalMonthlyKwh) * 100.0 : 0.0;
      return r.copyWith(percentageOfTotal: pct);
    }).toList();

    // Group by category
    final Map<ApplianceCategory, double> catKwh = {};
    final Map<ApplianceCategory, int> catCounts = {};

    for (final r in applianceResults) {
      final cat = r.appliance.category;
      catKwh[cat] = (catKwh[cat] ?? 0.0) + r.monthlyKwh;
      catCounts[cat] = (catCounts[cat] ?? 0) + r.appliance.quantity;
    }

    final List<CategoryConsumptionResult> categoryResults = catKwh.entries.map((entry) {
      final pct = totalMonthlyKwh > 0 ? (entry.value / totalMonthlyKwh) * 100.0 : 0.0;
      return CategoryConsumptionResult(
        category: entry.key,
        monthlyKwh: entry.value,
        percentageOfTotal: pct,
        applianceCount: catCounts[entry.key] ?? 0,
      );
    }).toList()
      ..sort((a, b) => b.monthlyKwh.compareTo(a.monthlyKwh));

    final topConsumers = applianceResults.take(3).toList();
    final averageDailyKwh = monthDays > 0 ? totalMonthlyKwh / monthDays : 0.0;

    return HouseholdConsumptionSummary(
      totalMonthlyKwh: totalMonthlyKwh,
      averageDailyKwh: averageDailyKwh,
      applianceResults: applianceResults,
      categoryResults: categoryResults,
      topConsumers: topConsumers,
    );
  }
}
