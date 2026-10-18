import 'appliance_template.dart';

class HouseholdAppliance {
  final String id;
  final String householdId;
  final String? templateId;
  final String name;
  final ApplianceCategory category;
  final CalculationType calculationType;
  final int quantity;
  final double wattage;
  final double standbyWatts;
  final double hoursPerDay;
  final int daysPerMonth;
  final int cyclesPerMonth;
  final double dutyCycle;
  final double kwhPerCycle;
  final UsageProfile usageProfile;
  final String customNotes;

  const HouseholdAppliance({
    required this.id,
    required this.householdId,
    this.templateId,
    required this.name,
    required this.category,
    required this.calculationType,
    required this.quantity,
    required this.wattage,
    this.standbyWatts = 0.0,
    required this.hoursPerDay,
    required this.daysPerMonth,
    this.cyclesPerMonth = 15,
    this.dutyCycle = 1.0,
    this.kwhPerCycle = 0.0,
    this.usageProfile = UsageProfile.normal,
    this.customNotes = '',
  });

  HouseholdAppliance copyWith({
    String? id,
    String? householdId,
    String? templateId,
    String? name,
    ApplianceCategory? category,
    CalculationType? calculationType,
    int? quantity,
    double? wattage,
    double? standbyWatts,
    double? hoursPerDay,
    int? daysPerMonth,
    int? cyclesPerMonth,
    double? dutyCycle,
    double? kwhPerCycle,
    UsageProfile? usageProfile,
    String? customNotes,
  }) {
    return HouseholdAppliance(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      category: category ?? this.category,
      calculationType: calculationType ?? this.calculationType,
      quantity: quantity ?? this.quantity,
      wattage: wattage ?? this.wattage,
      standbyWatts: standbyWatts ?? this.standbyWatts,
      hoursPerDay: hoursPerDay ?? this.hoursPerDay,
      daysPerMonth: daysPerMonth ?? this.daysPerMonth,
      cyclesPerMonth: cyclesPerMonth ?? this.cyclesPerMonth,
      dutyCycle: dutyCycle ?? this.dutyCycle,
      kwhPerCycle: kwhPerCycle ?? this.kwhPerCycle,
      usageProfile: usageProfile ?? this.usageProfile,
      customNotes: customNotes ?? this.customNotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'householdId': householdId,
        'templateId': templateId,
        'name': name,
        'category': category.name,
        'calculationType': calculationType.name,
        'quantity': quantity,
        'wattage': wattage,
        'standbyWatts': standbyWatts,
        'hoursPerDay': hoursPerDay,
        'daysPerMonth': daysPerMonth,
        'cyclesPerMonth': cyclesPerMonth,
        'dutyCycle': dutyCycle,
        'kwhPerCycle': kwhPerCycle,
        'usageProfile': usageProfile.name,
        'customNotes': customNotes,
      };

  factory HouseholdAppliance.fromJson(Map<String, dynamic> json) {
    return HouseholdAppliance(
      id: json['id'] as String,
      householdId: json['householdId'] as String,
      templateId: json['templateId'] as String?,
      name: json['name'] as String,
      category: ApplianceCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ApplianceCategory.other,
      ),
      calculationType: CalculationType.values.firstWhere(
        (e) => e.name == json['calculationType'],
        orElse: () => CalculationType.continuous,
      ),
      quantity: (json['quantity'] as num).toInt(),
      wattage: (json['wattage'] as num).toDouble(),
      standbyWatts: (json['standbyWatts'] as num?)?.toDouble() ?? 0.0,
      hoursPerDay: (json['hoursPerDay'] as num).toDouble(),
      daysPerMonth: (json['daysPerMonth'] as num).toInt(),
      cyclesPerMonth: (json['cyclesPerMonth'] as num?)?.toInt() ?? 15,
      dutyCycle: (json['dutyCycle'] as num?)?.toDouble() ?? 1.0,
      kwhPerCycle: (json['kwhPerCycle'] as num?)?.toDouble() ?? 0.0,
      usageProfile: UsageProfile.values.firstWhere(
        (e) => e.name == json['usageProfile'],
        orElse: () => UsageProfile.normal,
      ),
      customNotes: json['customNotes'] as String? ?? '',
    );
  }
}
