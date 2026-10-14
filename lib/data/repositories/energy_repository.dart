import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/household.dart';
import '../models/household_appliance.dart';
import '../models/tariff_config.dart';
import '../models/solar_config.dart';

class EnergyRepository {
  static const String _keyHouseholds = 'unitwise_households';
  static const String _keyAppliances = 'unitwise_appliances';
  static const String _keyTariff = 'unitwise_tariff';
  static const String _keySolar = 'unitwise_solar';
  static const String _keyActiveHouseholdId = 'unitwise_active_household_id';
  static const String _keyInitialized = 'unitwise_is_initialized';
  static const String _keyCustomSolarGen = 'unitwise_custom_solar_gen';
  static const String _keyInverterVoltage = 'unitwise_inverter_voltage';
  static const String _keyInverterCurrent = 'unitwise_inverter_current';

  final SharedPreferences _prefs;

  EnergyRepository(this._prefs);

  static Future<EnergyRepository> init() async {
    final prefs = await SharedPreferences.getInstance();
    final repo = EnergyRepository(prefs);
    await repo._ensureInitialData();
    return repo;
  }

  Future<void> _ensureInitialData() async {
    final isInitialized = _prefs.getBool(_keyInitialized) ?? false;
    if (isInitialized) return;

    // 1. Create Default Household with clean slate (user inputs data)
    final defaultHousehold = Household(
      id: 'default_home',
      name: 'Primary Residence',
      location: 'Sunbelt Region',
      daysInMonth: 30,
      actualLastMonthBill: null,
      actualLastMonthUnits: null,
      createdAt: DateTime.now(),
    );
    await saveHouseholds([defaultHousehold]);
    await setActiveHouseholdId(defaultHousehold.id);

    // 2. Clean slate: 0 pre-seeded appliances, user will input all data
    await saveAppliances([]);

    // 3. Default Tariff
    const defaultTariff = TariffConfig(
      id: 'default_tariff',
      name: 'Residential Tiered Tariff (Standard)',
      type: TariffType.tieredSlab,
      slabs: [
        TariffSlab(fromUnits: 0, toUnits: 100, ratePerKwh: 3.50),
        TariffSlab(fromUnits: 100, toUnits: 200, ratePerKwh: 5.50),
        TariffSlab(fromUnits: 200, toUnits: 400, ratePerKwh: 7.50),
        TariffSlab(fromUnits: 400, toUnits: double.infinity, ratePerKwh: 9.50),
      ],
      fixedCharge: 120.0,
      taxPercentage: 9.0,
      fpppaRatePerKwh: 0.35,
      currencySymbol: '₹',
    );
    await saveTariff(defaultTariff);

    // 4. Default Solar Config
    const defaultSolar = SolarConfig(
      locationName: 'Standard Sunbelt',
      peakSunHours: 4.8,
      performanceRatio: 0.78,
      availableRoofAreaSqFt: 400.0,
      sqFtPerKw: 100.0,
      systemType: SolarSystemType.onGrid,
      costPerKwOnGrid: 55000.0,
      selfConsumptionRatio: 0.65,
      exportTariffPerKwh: 3.20,
      subsidyScheme: SubsidyScheme.pmSuryaGharIndia,
      targetOffsetPercent: 100.0,
    );
    await saveSolar(defaultSolar);

    await _prefs.setBool(_keyInitialized, true);
  }

  // --- Households ---
  List<Household> loadHouseholds() {
    final raw = _prefs.getString(_keyHouseholds);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Household.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHouseholds(List<Household> households) async {
    final raw = jsonEncode(households.map((h) => h.toJson()).toList());
    await _prefs.setString(_keyHouseholds, raw);
  }

  String getActiveHouseholdId() {
    return _prefs.getString(_keyActiveHouseholdId) ?? 'default_home';
  }

  Future<void> setActiveHouseholdId(String id) async {
    await _prefs.setString(_keyActiveHouseholdId, id);
  }

  // --- Appliances ---
  List<HouseholdAppliance> loadAppliances() {
    final raw = _prefs.getString(_keyAppliances);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => HouseholdAppliance.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAppliances(List<HouseholdAppliance> appliances) async {
    final raw = jsonEncode(appliances.map((a) => a.toJson()).toList());
    await _prefs.setString(_keyAppliances, raw);
  }

  // --- Tariff ---
  TariffConfig loadTariff() {
    final raw = _prefs.getString(_keyTariff);
    if (raw == null || raw.isEmpty) {
      return const TariffConfig(
        id: 'default_tariff',
        name: 'Residential Tiered Tariff (Standard)',
      );
    }
    try {
      return TariffConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const TariffConfig(
        id: 'default_tariff',
        name: 'Residential Tiered Tariff (Standard)',
      );
    }
  }

  Future<void> saveTariff(TariffConfig tariff) async {
    await _prefs.setString(_keyTariff, jsonEncode(tariff.toJson()));
  }

  // --- Solar ---
  SolarConfig loadSolar() {
    final raw = _prefs.getString(_keySolar);
    if (raw == null || raw.isEmpty) {
      return const SolarConfig();
    }
    try {
      return SolarConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const SolarConfig();
    }
  }

  Future<void> saveSolar(SolarConfig solar) async {
    await _prefs.setString(_keySolar, jsonEncode(solar.toJson()));
  }

  // --- Net Energy Balance & Inverter Specs Persistence ---
  double? loadCustomSolarGeneration() {
    return _prefs.containsKey(_keyCustomSolarGen) ? _prefs.getDouble(_keyCustomSolarGen) : null;
  }

  Future<void> saveCustomSolarGeneration(double? kwh) async {
    if (kwh == null) {
      await _prefs.remove(_keyCustomSolarGen);
    } else {
      await _prefs.setDouble(_keyCustomSolarGen, kwh);
    }
  }

  double loadInverterVoltage() => _prefs.getDouble(_keyInverterVoltage) ?? 230.0;
  Future<void> saveInverterVoltage(double v) async => await _prefs.setDouble(_keyInverterVoltage, v);

  double loadInverterCurrent() => _prefs.getDouble(_keyInverterCurrent) ?? 10.0;
  Future<void> saveInverterCurrent(double a) async => await _prefs.setDouble(_keyInverterCurrent, a);

  // --- Full Backup Export / Import ---
  String exportFullDataJson() {
    final map = {
      'households': loadHouseholds().map((h) => h.toJson()).toList(),
      'appliances': loadAppliances().map((a) => a.toJson()).toList(),
      'tariff': loadTariff().toJson(),
      'solar': loadSolar().toJson(),
      'version': '0.0.1',
      'exportedAt': DateTime.now().toIso8601String(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  Future<bool> importFullDataJson(String jsonString) async {
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      if (map.containsKey('households')) {
        final hl = (map['households'] as List<dynamic>)
            .map((e) => Household.fromJson(e as Map<String, dynamic>))
            .toList();
        await saveHouseholds(hl);
      }
      if (map.containsKey('appliances')) {
        final al = (map['appliances'] as List<dynamic>)
            .map((e) => HouseholdAppliance.fromJson(e as Map<String, dynamic>))
            .toList();
        await saveAppliances(al);
      }
      if (map.containsKey('tariff')) {
        await saveTariff(TariffConfig.fromJson(map['tariff'] as Map<String, dynamic>));
      }
      if (map.containsKey('solar')) {
        await saveSolar(SolarConfig.fromJson(map['solar'] as Map<String, dynamic>));
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> clearAllData() async {
    final defaultHousehold = Household(
      id: 'default_home',
      name: 'Primary Residence',
      location: 'Sunbelt Region',
      daysInMonth: 30,
      actualLastMonthBill: null,
      actualLastMonthUnits: null,
      createdAt: DateTime.now(),
    );
    await saveHouseholds([defaultHousehold]);
    await setActiveHouseholdId(defaultHousehold.id);
    await saveAppliances([]);
    await saveCustomSolarGeneration(null);
  }
}
