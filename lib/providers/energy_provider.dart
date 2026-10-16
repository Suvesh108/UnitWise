import 'package:flutter/foundation.dart';
import '../data/models/household.dart';
import '../data/models/household_appliance.dart';
import '../data/models/tariff_config.dart';
import '../data/models/solar_config.dart';
import '../data/repositories/energy_repository.dart';
import '../domain/energy_calculator.dart';
import '../domain/bill_calculator.dart';
import '../domain/solar_calculator.dart';

class EnergyProvider extends ChangeNotifier {
  final EnergyRepository _repository;

  List<Household> _households = [];
  String _activeHouseholdId = 'default_home';
  List<HouseholdAppliance> _allAppliances = [];
  TariffConfig _tariff = const TariffConfig(id: 'default_tariff', name: 'Residential Standard');
  SolarConfig _solar = const SolarConfig();

  EnergyProvider(this._repository) {
    _loadState();
  }

  void _loadState() {
    _households = _repository.loadHouseholds();
    _activeHouseholdId = _repository.getActiveHouseholdId();
    if (_households.isNotEmpty && !_households.any((h) => h.id == _activeHouseholdId)) {
      _activeHouseholdId = _households.first.id;
    }
    _allAppliances = _repository.loadAppliances();
    // One-time automatic purge of legacy pre-seeded starter appliances so user starts completely clean
    if (_allAppliances.any((a) => a.id.startsWith('starter_'))) {
      _allAppliances.removeWhere((a) => a.id.startsWith('starter_'));
      _repository.saveAppliances(_allAppliances);
    }
    _tariff = _repository.loadTariff();
    _solar = _repository.loadSolar();
    _customSolarGenerationKwh = _repository.loadCustomSolarGeneration();
    _voltageVolts = _repository.loadInverterVoltage();
    _currentAmps = _repository.loadInverterCurrent();
    notifyListeners();
  }

  // --- Getters ---
  List<Household> get households => _households;
  String get activeHouseholdId => _activeHouseholdId;

  Household get activeHousehold {
    return _households.firstWhere(
      (h) => h.id == _activeHouseholdId,
      orElse: () => Household(
        id: _activeHouseholdId,
        name: 'Primary Residence',
        propertyType: PropertyType.residence,
        createdAt: DateTime.now(),
      ),
    );
  }

  List<HouseholdAppliance> get currentAppliances {
    return _allAppliances.where((a) => a.householdId == _activeHouseholdId).toList();
  }

  // Property-scoped Tariff & Solar (prevents cross-property mixing)
  TariffConfig get tariff => activeHousehold.tariffConfig ?? _tariff;
  SolarConfig get solar => activeHousehold.solarConfig ?? _solar;

  // --- Calculations ---
  HouseholdConsumptionSummary get consumptionSummary {
    return EnergyCalculator.calculateHouseholdSummary(
      currentAppliances,
      monthDays: activeHousehold.daysInMonth,
    );
  }

  BillCalculationResult get billResult {
    return BillCalculator.calculateBill(
      totalUnitsKwh: consumptionSummary.totalMonthlyKwh,
      tariff: tariff,
      actualBill: activeHousehold.actualLastMonthBill,
    );
  }

  SolarCalculationResult get solarResult {
    return SolarCalculator.calculateSolar(
      monthlyConsumptionKwh: consumptionSummary.totalMonthlyKwh,
      effectiveRetailTariff: billResult.effectiveRatePerKwh > 0
          ? billResult.effectiveRatePerKwh
          : tariff.flatRatePerKwh,
      config: solar,
      monthDays: activeHousehold.daysInMonth,
    );
  }

  // --- Net Energy Balance State & Calculation ---
  double? _customSolarGenerationKwh;
  double? _customApplianceLoadKwh;
  double _voltageVolts = 230.0;
  double _currentAmps = 10.0;

  double? get customSolarGenerationKwh => activeHousehold.customSolarKwh ?? _customSolarGenerationKwh;
  double? get customApplianceLoadKwh => _customApplianceLoadKwh;
  double get voltageVolts => activeHousehold.inverterVoltage ?? _voltageVolts;
  double get currentAmps => activeHousehold.inverterCurrent ?? _currentAmps;

  double get effectiveSolarMonthlyKwh {
    final custom = customSolarGenerationKwh;
    if (custom != null) {
      return custom;
    }
    return solarResult.monthlyGenerationKwh > 0
        ? solarResult.monthlyGenerationKwh
        : 0.0;
  }

  double get effectiveApplianceMonthlyKwh {
    if (_customApplianceLoadKwh != null) {
      return _customApplianceLoadKwh!;
    }
    return consumptionSummary.totalMonthlyKwh;
  }

  NetEnergyBalance get netEnergyBalance {
    final rate = billResult.effectiveRatePerKwh > 0
        ? billResult.effectiveRatePerKwh
        : tariff.flatRatePerKwh;
    return SolarCalculator.calculateNetBalance(
      solarMonthlyKwh: effectiveSolarMonthlyKwh,
      applianceMonthlyKwh: effectiveApplianceMonthlyKwh,
      retailRatePerKwh: rate,
      exportRatePerKwh: solar.exportTariffPerKwh,
      fixedCharges: tariff.fixedCharge,
    );
  }

  Future<void> setCustomSolarGeneration(double? kwh) async {
    _customSolarGenerationKwh = kwh;
    await _repository.saveCustomSolarGeneration(kwh);
    final updated = activeHousehold.copyWith(customSolarKwh: kwh);
    await updateActiveHousehold(updated);
  }

  void setCustomApplianceLoad(double? kwh) {
    _customApplianceLoadKwh = kwh;
    notifyListeners();
  }

  Future<void> setElectricalSpecs({required double voltage, required double current}) async {
    _voltageVolts = voltage;
    _currentAmps = current;
    await _repository.saveInverterVoltage(voltage);
    await _repository.saveInverterCurrent(current);
    final genKwh = SolarCalculator.calculateKwhFromElectricalSpecs(
      voltageVolts: voltage,
      currentAmps: current,
      peakSunHours: solar.peakSunHours,
      days: activeHousehold.daysInMonth,
    );
    _customSolarGenerationKwh = genKwh;
    await _repository.saveCustomSolarGeneration(genKwh);
    final updated = activeHousehold.copyWith(
      inverterVoltage: voltage,
      inverterCurrent: current,
      customSolarKwh: genKwh,
    );
    await updateActiveHousehold(updated);
  }

  Future<void> resetNetBalanceInputs() async {
    _customSolarGenerationKwh = null;
    _customApplianceLoadKwh = null;
    _voltageVolts = 230.0;
    _currentAmps = 10.0;
    await _repository.saveCustomSolarGeneration(null);
    await _repository.saveInverterVoltage(230.0);
    await _repository.saveInverterCurrent(10.0);
    final updated = activeHousehold.copyWith(
      customSolarKwh: null,
      inverterVoltage: 230.0,
      inverterCurrent: 10.0,
    );
    await updateActiveHousehold(updated);
  }

  /// Calculates what percentage of total solar generation this appliance draws
  double getApplianceSolarShare(HouseholdAppliance appliance) {
    final totalSolar = effectiveSolarMonthlyKwh;
    if (totalSolar <= 0) return 0.0;
    final appKwh = EnergyCalculator.calculateApplianceMonthlyKwh(
      appliance,
      monthDays: activeHousehold.daysInMonth,
    );
    return (appKwh / totalSolar) * 100.0;
  }

  /// Checks if solar generation is sufficient to cover this appliance
  bool isApplianceSolarCovered(HouseholdAppliance appliance) {
    final balance = netEnergyBalance;
    if (balance.isSurplus) return true;
    final appKwh = EnergyCalculator.calculateApplianceMonthlyKwh(
      appliance,
      monthDays: activeHousehold.daysInMonth,
    );
    return effectiveSolarMonthlyKwh >= appKwh;
  }

  // --- Appliance Actions ---
  Future<void> addAppliance(HouseholdAppliance appliance) async {
    _allAppliances.add(appliance);
    await _repository.saveAppliances(_allAppliances);
    notifyListeners();
  }

  Future<void> updateAppliance(HouseholdAppliance appliance) async {
    final idx = _allAppliances.indexWhere((a) => a.id == appliance.id);
    if (idx != -1) {
      _allAppliances[idx] = appliance;
      await _repository.saveAppliances(_allAppliances);
      notifyListeners();
    }
  }

  Future<void> deleteAppliance(String id) async {
    _allAppliances.removeWhere((a) => a.id == id);
    await _repository.saveAppliances(_allAppliances);
    notifyListeners();
  }

  Future<void> duplicateAppliance(HouseholdAppliance source) async {
    final copy = source.copyWith(
      id: 'app_${DateTime.now().millisecondsSinceEpoch}',
      name: '${source.name} (Copy)',
    );
    await addAppliance(copy);
  }

  // --- Tariff & Solar Config ---
  Future<void> updateTariff(TariffConfig newTariff) async {
    _tariff = newTariff;
    await _repository.saveTariff(newTariff);
    final updated = activeHousehold.copyWith(tariffConfig: newTariff);
    await updateActiveHousehold(updated);
  }

  Future<void> updateSolar(SolarConfig newSolar) async {
    _solar = newSolar;
    await _repository.saveSolar(newSolar);
    final updated = activeHousehold.copyWith(solarConfig: newSolar);
    await updateActiveHousehold(updated);
  }

  // --- Multi-Property Management ---
  int getApplianceCountForHousehold(String householdId) {
    return _allAppliances.where((a) => a.householdId == householdId).length;
  }

  double getMonthlyKwhForHousehold(String householdId) {
    final apps = _allAppliances.where((a) => a.householdId == householdId).toList();
    final h = _households.firstWhere(
      (item) => item.id == householdId,
      orElse: () => activeHousehold,
    );
    return EnergyCalculator.calculateHouseholdSummary(apps, monthDays: h.daysInMonth).totalMonthlyKwh;
  }

  Future<void> updateActiveHousehold(Household updated) async {
    final idx = _households.indexWhere((h) => h.id == updated.id);
    if (idx != -1) {
      _households[idx] = updated;
      await _repository.saveHouseholds(_households);
      notifyListeners();
    }
  }

  Future<void> createProperty({
    required String name,
    required PropertyType propertyType,
    String location = 'Default Location',
    int daysInMonth = 30,
  }) async {
    final id = 'prop_${DateTime.now().millisecondsSinceEpoch}';
    final newProperty = Household(
      id: id,
      name: name,
      location: location,
      propertyType: propertyType,
      daysInMonth: daysInMonth,
      createdAt: DateTime.now(),
      tariffConfig: _tariff,
      solarConfig: _solar,
    );
    _households.add(newProperty);
    await _repository.saveHouseholds(_households);
    await switchHousehold(id);
  }

  Future<void> createHousehold(String name, String location, {int daysInMonth = 30, PropertyType propertyType = PropertyType.residence}) async {
    await createProperty(name: name, propertyType: propertyType, location: location, daysInMonth: daysInMonth);
  }

  Future<void> switchHousehold(String id) async {
    if (_activeHouseholdId == id) return;
    _activeHouseholdId = id;
    await _repository.setActiveHouseholdId(id);
    notifyListeners();
  }

  Future<void> deleteHousehold(String id) async {
    if (_households.length <= 1) return; // Keep at least one property
    _households.removeWhere((h) => h.id == id);
    _allAppliances.removeWhere((a) => a.householdId == id);
    await _repository.saveHouseholds(_households);
    await _repository.saveAppliances(_allAppliances);
    if (_activeHouseholdId == id) {
      _activeHouseholdId = _households.first.id;
      await _repository.setActiveHouseholdId(_activeHouseholdId);
    }
    notifyListeners();
  }

  // --- Backup & Restore ---
  String exportJson() => _repository.exportFullDataJson();

  Future<bool> importJson(String jsonString) async {
    final ok = await _repository.importFullDataJson(jsonString);
    if (ok) {
      _loadState();
    }
    return ok;
  }

  Future<void> clearAllData() async {
    await _repository.clearAllData();
    _allAppliances = [];
    _customSolarGenerationKwh = null;
    _customApplianceLoadKwh = null;
    _loadState();
  }
}
