import '../data/models/appliance_template.dart';
import '../data/models/household_appliance.dart';

class ApplianceConsumptionResult {
  final HouseholdAppliance appliance;
  final double monthlyKwh;
  final double activeMonthlyKwh;
  final double standbyMonthlyKwh;
  final double dailyKwh;
  final double percentageOfTotal;

  const ApplianceConsumptionResult({
    required this.appliance,
    required this.monthlyKwh,
    this.activeMonthlyKwh = 0.0,
    this.standbyMonthlyKwh = 0.0,
    required this.dailyKwh,
    this.percentageOfTotal = 0.0,
  });

  ApplianceConsumptionResult copyWith({
    double? percentageOfTotal,
    double? activeMonthlyKwh,
    double? standbyMonthlyKwh,
  }) {
    return ApplianceConsumptionResult(
      appliance: appliance,
      monthlyKwh: monthlyKwh,
      activeMonthlyKwh: activeMonthlyKwh ?? this.activeMonthlyKwh,
      standbyMonthlyKwh: standbyMonthlyKwh ?? this.standbyMonthlyKwh,
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

class StandbyApplianceResult {
  final HouseholdAppliance appliance;
  final double standbyWatts;
  final double monthlyStandbyKwh;
  final double idleHoursPerDay;

  const StandbyApplianceResult({
    required this.appliance,
    required this.standbyWatts,
    required this.monthlyStandbyKwh,
    required this.idleHoursPerDay,
  });
}

class StandbyConsumptionSummary {
  final double totalStandbyWatts;
  final double monthlyStandbyKwh;
  final double dailyStandbyKwh;
  final double percentageOfTotal;
  final List<StandbyApplianceResult> offenders;

  const StandbyConsumptionSummary({
    required this.totalStandbyWatts,
    required this.monthlyStandbyKwh,
    required this.dailyStandbyKwh,
    required this.percentageOfTotal,
    required this.offenders,
  });

  static const StandbyConsumptionSummary empty = StandbyConsumptionSummary(
    totalStandbyWatts: 0.0,
    monthlyStandbyKwh: 0.0,
    dailyStandbyKwh: 0.0,
    percentageOfTotal: 0.0,
    offenders: [],
  );
}

class HouseholdConsumptionSummary {
  final double totalMonthlyKwh;
  final double averageDailyKwh;
  final List<ApplianceConsumptionResult> applianceResults;
  final List<CategoryConsumptionResult> categoryResults;
  final List<ApplianceConsumptionResult> topConsumers;
  final StandbyConsumptionSummary standbySummary;

  const HouseholdConsumptionSummary({
    required this.totalMonthlyKwh,
    required this.averageDailyKwh,
    required this.applianceResults,
    required this.categoryResults,
    required this.topConsumers,
    this.standbySummary = StandbyConsumptionSummary.empty,
  });

  static const HouseholdConsumptionSummary empty = HouseholdConsumptionSummary(
    totalMonthlyKwh: 0.0,
    averageDailyKwh: 0.0,
    applianceResults: [],
    categoryResults: [],
    topConsumers: [],
    standbySummary: StandbyConsumptionSummary.empty,
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

  /// Calculates monthly active kWh for an individual appliance
  static double calculateApplianceActiveKwh(
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

  /// Calculates monthly standby (vampire) kWh for an individual appliance during idle hours
  static double calculateApplianceStandbyKwh(
    HouseholdAppliance item, {
    int monthDays = 30,
  }) {
    if (item.standbyWatts <= 0) return 0.0;
    final effectiveDays = item.daysPerMonth.clamp(1, monthDays);
    // Idle hours per day = remaining hours when not actively running
    final idleHours = (24.0 - item.hoursPerDay).clamp(0.0, 24.0);
    return (item.standbyWatts * idleHours * effectiveDays * item.quantity) / 1000.0;
  }

  /// Calculates total monthly kWh (active + standby vampire draw)
  static double calculateApplianceMonthlyKwh(
    HouseholdAppliance item, {
    int monthDays = 30,
  }) {
    final active = calculateApplianceActiveKwh(item, monthDays: monthDays);
    final standby = calculateApplianceStandbyKwh(item, monthDays: monthDays);
    return active + standby;
  }

  /// Calculates the complete household summary
  static HouseholdConsumptionSummary calculateHouseholdConsumption(
    List<HouseholdAppliance> appliances, {
    int monthDays = 30,
  }) => calculateHouseholdSummary(appliances, monthDays: monthDays);

  /// Calculates the complete household summary
  static HouseholdConsumptionSummary calculateHouseholdSummary(
    List<HouseholdAppliance> appliances, {
    int monthDays = 30,
  }) {
    if (appliances.isEmpty) {
      return HouseholdConsumptionSummary.empty;
    }

    double totalMonthlyKwh = 0.0;
    double totalStandbyMonthlyKwh = 0.0;
    double totalStandbyWatts = 0.0;
    final List<StandbyApplianceResult> offenders = [];
    final List<ApplianceConsumptionResult> initialResults = [];

    for (final app in appliances) {
      final active = calculateApplianceActiveKwh(app, monthDays: monthDays);
      final standby = calculateApplianceStandbyKwh(app, monthDays: monthDays);
      final monthly = active + standby;
      final daily = monthDays > 0 ? monthly / monthDays : 0.0;

      totalMonthlyKwh += monthly;
      totalStandbyMonthlyKwh += standby;

      if (app.standbyWatts > 0) {
        totalStandbyWatts += (app.standbyWatts * app.quantity);
        final idleHours = (24.0 - app.hoursPerDay).clamp(0.0, 24.0);
        offenders.add(
          StandbyApplianceResult(
            appliance: app,
            standbyWatts: app.standbyWatts * app.quantity,
            monthlyStandbyKwh: standby,
            idleHoursPerDay: idleHours,
          ),
        );
      }

      initialResults.add(
        ApplianceConsumptionResult(
          appliance: app,
          monthlyKwh: monthly,
          activeMonthlyKwh: active,
          standbyMonthlyKwh: standby,
          dailyKwh: daily,
        ),
      );
    }

    // Sort descending by monthly consumption
    initialResults.sort((a, b) => b.monthlyKwh.compareTo(a.monthlyKwh));
    offenders.sort((a, b) => b.monthlyStandbyKwh.compareTo(a.monthlyStandbyKwh));

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

    final standbySummary = StandbyConsumptionSummary(
      totalStandbyWatts: totalStandbyWatts,
      monthlyStandbyKwh: totalStandbyMonthlyKwh,
      dailyStandbyKwh: monthDays > 0 ? totalStandbyMonthlyKwh / monthDays : 0.0,
      percentageOfTotal: totalMonthlyKwh > 0 ? (totalStandbyMonthlyKwh / totalMonthlyKwh) * 100.0 : 0.0,
      offenders: offenders,
    );

    return HouseholdConsumptionSummary(
      totalMonthlyKwh: totalMonthlyKwh,
      averageDailyKwh: averageDailyKwh,
      applianceResults: applianceResults,
      categoryResults: categoryResults,
      topConsumers: topConsumers,
      standbySummary: standbySummary,
    );
  }
}
