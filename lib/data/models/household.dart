class Household {
  final String id;
  final String name;
  final String location;
  final int daysInMonth;
  final double? actualLastMonthBill;
  final double? actualLastMonthUnits;
  final DateTime createdAt;

  const Household({
    required this.id,
    required this.name,
    this.location = 'Default Location',
    this.daysInMonth = 30,
    this.actualLastMonthBill,
    this.actualLastMonthUnits,
    required this.createdAt,
  });

  Household copyWith({
    String? id,
    String? name,
    String? location,
    int? daysInMonth,
    double? actualLastMonthBill,
    double? actualLastMonthUnits,
    DateTime? createdAt,
  }) {
    return Household(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      daysInMonth: daysInMonth ?? this.daysInMonth,
      actualLastMonthBill: actualLastMonthBill ?? this.actualLastMonthBill,
      actualLastMonthUnits: actualLastMonthUnits ?? this.actualLastMonthUnits,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'daysInMonth': daysInMonth,
        'actualLastMonthBill': actualLastMonthBill,
        'actualLastMonthUnits': actualLastMonthUnits,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String? ?? 'Default Location',
      daysInMonth: (json['daysInMonth'] as num?)?.toInt() ?? 30,
      actualLastMonthBill: (json['actualLastMonthBill'] as num?)?.toDouble(),
      actualLastMonthUnits: (json['actualLastMonthUnits'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
