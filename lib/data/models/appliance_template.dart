enum ApplianceCategory {
  cooling,
  kitchen,
  lighting,
  laundry,
  entertainment,
  heating,
  waterPumps,
  other,
}

enum CalculationType {
  continuous, // Rated watts * hours * days
  dutyCycle,  // Rated watts * duty cycle * hours * days (e.g. Refrigerator, Inverter AC)
  perCycle,   // kWh per cycle * cycles per month (e.g. Washing machine, Dishwasher)
}

enum UsageProfile {
  low,
  normal,
  heavy,
}

class ApplianceTemplate {
  final String id;
  final String name;
  final ApplianceCategory category;
  final CalculationType calculationType;
  final double defaultWatts;
  final double defaultStandbyWatts;
  final double defaultDutyCycle;
  final double defaultKwhPerCycle;
  final double defaultHoursPerDay;
  final int defaultDaysPerMonth;
  final int defaultCyclesPerMonth;
  final String iconName;
  final String description;
  final String calculationNote;

  const ApplianceTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.calculationType,
    required this.defaultWatts,
    this.defaultStandbyWatts = 0.0,
    this.defaultDutyCycle = 1.0,
    this.defaultKwhPerCycle = 0.0,
    this.defaultHoursPerDay = 4.0,
    this.defaultDaysPerMonth = 30,
    this.defaultCyclesPerMonth = 15,
    required this.iconName,
    required this.description,
    required this.calculationNote,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'calculationType': calculationType.name,
        'defaultWatts': defaultWatts,
        'defaultStandbyWatts': defaultStandbyWatts,
        'defaultDutyCycle': defaultDutyCycle,
        'defaultKwhPerCycle': defaultKwhPerCycle,
        'defaultHoursPerDay': defaultHoursPerDay,
        'defaultDaysPerMonth': defaultDaysPerMonth,
        'defaultCyclesPerMonth': defaultCyclesPerMonth,
        'iconName': iconName,
        'description': description,
        'calculationNote': calculationNote,
      };

  factory ApplianceTemplate.fromJson(Map<String, dynamic> json) {
    return ApplianceTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      category: ApplianceCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ApplianceCategory.other,
      ),
      calculationType: CalculationType.values.firstWhere(
        (e) => e.name == json['calculationType'],
        orElse: () => CalculationType.continuous,
      ),
      defaultWatts: (json['defaultWatts'] as num).toDouble(),
      defaultStandbyWatts: (json['defaultStandbyWatts'] as num?)?.toDouble() ?? 0.0,
      defaultDutyCycle: (json['defaultDutyCycle'] as num?)?.toDouble() ?? 1.0,
      defaultKwhPerCycle: (json['defaultKwhPerCycle'] as num?)?.toDouble() ?? 0.0,
      defaultHoursPerDay: (json['defaultHoursPerDay'] as num?)?.toDouble() ?? 4.0,
      defaultDaysPerMonth: (json['defaultDaysPerMonth'] as num?)?.toInt() ?? 30,
      defaultCyclesPerMonth: (json['defaultCyclesPerMonth'] as num?)?.toInt() ?? 15,
      iconName: json['iconName'] as String? ?? 'devices',
      description: json['description'] as String? ?? '',
      calculationNote: json['calculationNote'] as String? ?? '',
    );
  }
}
