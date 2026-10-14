import 'package:flutter_test/flutter_test.dart';
import 'package:unitwise/data/models/appliance_template.dart';
import 'package:unitwise/data/models/household_appliance.dart';
import 'package:unitwise/data/models/tariff_config.dart';
import 'package:unitwise/data/models/solar_config.dart';
import 'package:unitwise/domain/energy_calculator.dart';
import 'package:unitwise/domain/bill_calculator.dart';
import 'package:unitwise/domain/solar_calculator.dart';

void main() {
  group('EnergyCalculator Tests', () {
    test('Standard continuous appliance matches Section 4.A example (Three 60W fans for 8h/day, 30 days)', () {
      const fans = HouseholdAppliance(
        id: '1',
        householdId: 'h1',
        name: 'Ceiling Fan',
        category: ApplianceCategory.cooling,
        calculationType: CalculationType.continuous,
        quantity: 3,
        wattage: 60.0,
        hoursPerDay: 8.0,
        daysPerMonth: 30,
      );

      final kwh = EnergyCalculator.calculateApplianceMonthlyKwh(fans, monthDays: 30);
      // (60 * 8 * 30 * 3) / 1000 = 43.2 kWh
      expect(kwh, closeTo(43.2, 0.001));
    });

    test('Duty-cycle appliance (Refrigerator 220W with 35% duty cycle over 24h)', () {
      const fridge = HouseholdAppliance(
        id: '2',
        householdId: 'h1',
        name: 'Refrigerator',
        category: ApplianceCategory.kitchen,
        calculationType: CalculationType.dutyCycle,
        quantity: 1,
        wattage: 220.0,
        dutyCycle: 0.35,
        hoursPerDay: 24.0,
        daysPerMonth: 30,
      );

      final kwh = EnergyCalculator.calculateApplianceMonthlyKwh(fridge, monthDays: 30);
      // (220 * 0.35 * 24 * 30 * 1) / 1000 = 55.44 kWh
      expect(kwh, closeTo(55.44, 0.01));
    });

    test('Per-cycle appliance (Washing Machine 0.75 kWh/cycle for 15 cycles)', () {
      const washer = HouseholdAppliance(
        id: '3',
        householdId: 'h1',
        name: 'Washing Machine',
        category: ApplianceCategory.laundry,
        calculationType: CalculationType.perCycle,
        quantity: 1,
        wattage: 2000.0,
        kwhPerCycle: 0.75,
        cyclesPerMonth: 15,
        hoursPerDay: 1.0,
        daysPerMonth: 15,
      );

      final kwh = EnergyCalculator.calculateApplianceMonthlyKwh(washer, monthDays: 30);
      // 0.75 * 15 * 1 = 11.25 kWh
      expect(kwh, closeTo(11.25, 0.001));
    });

    test('Household summary calculates correct total and top consumers', () {
      const fan = HouseholdAppliance(
        id: '1',
        householdId: 'h1',
        name: 'Ceiling Fan',
        category: ApplianceCategory.cooling,
        calculationType: CalculationType.continuous,
        quantity: 3,
        wattage: 60.0,
        hoursPerDay: 8.0,
        daysPerMonth: 30,
      ); // 43.2 kWh

      const fridge = HouseholdAppliance(
        id: '2',
        householdId: 'h1',
        name: 'Refrigerator',
        category: ApplianceCategory.kitchen,
        calculationType: CalculationType.dutyCycle,
        quantity: 1,
        wattage: 220.0,
        dutyCycle: 0.35,
        hoursPerDay: 24.0,
        daysPerMonth: 30,
      ); // 55.44 kWh

      const ac = HouseholdAppliance(
        id: '3',
        householdId: 'h1',
        name: 'Inverter AC',
        category: ApplianceCategory.cooling,
        calculationType: CalculationType.dutyCycle,
        quantity: 1,
        wattage: 1450.0,
        dutyCycle: 0.48,
        hoursPerDay: 8.0,
        daysPerMonth: 30,
      ); // (1450 * 0.48 * 8 * 30 * 1) / 1000 = 167.04 kWh

      final summary = EnergyCalculator.calculateHouseholdSummary([fan, fridge, ac], monthDays: 30);

      // Total = 43.2 + 55.44 + 167.04 = 265.68 kWh
      expect(summary.totalMonthlyKwh, closeTo(265.68, 0.01));
      expect(summary.averageDailyKwh, closeTo(265.68 / 30, 0.01));
      expect(summary.topConsumers.first.appliance.name, equals('Inverter AC'));
      expect(summary.topConsumers.length, equals(3));
    });
  });

  group('BillCalculator Tests', () {
    test('Flat tariff calculates exact energy charge', () {
      const tariff = TariffConfig(
        id: 'flat_test',
        name: 'Flat Rate',
        type: TariffType.flat,
        flatRatePerKwh: 6.0,
        fixedCharge: 0.0,
        fpppaRatePerKwh: 0.0,
        taxPercentage: 0.0,
      );

      final result = BillCalculator.calculateBill(totalUnitsKwh: 245.0, tariff: tariff);
      expect(result.energyCharges, closeTo(1470.0, 0.001));
      expect(result.totalBill, closeTo(1470.0, 0.001));
    });

    test('Tiered slab tariff calculates exact cumulative slabs and taxes', () {
      const tariff = TariffConfig(
        id: 'slab_test',
        name: 'Slab Rate',
        type: TariffType.tieredSlab,
        slabs: [
          TariffSlab(fromUnits: 0, toUnits: 100, ratePerKwh: 3.0),
          TariffSlab(fromUnits: 100, toUnits: 200, ratePerKwh: 5.0),
          TariffSlab(fromUnits: 200, toUnits: 400, ratePerKwh: 8.0),
        ],
        fixedCharge: 100.0,
        fpppaRatePerKwh: 0.5,
        taxPercentage: 10.0,
      );

      // Total Units = 250 kWh
      // Slab 1 (0-100): 100 * 3 = 300
      // Slab 2 (100-200): 100 * 5 = 500
      // Slab 3 (200-250): 50 * 8 = 400
      // Energy charges = 1200
      // FPPPA = 250 * 0.5 = 125
      // Fixed = 100
      // Subtotal = 1200 + 125 + 100 = 1425
      // Tax 10% = 142.5
      // Total Bill = 1567.5
      final result = BillCalculator.calculateBill(totalUnitsKwh: 250.0, tariff: tariff);

      expect(result.energyCharges, closeTo(1200.0, 0.01));
      expect(result.fpppaCharges, closeTo(125.0, 0.01));
      expect(result.fixedCharge, closeTo(100.0, 0.01));
      expect(result.taxAmount, closeTo(142.5, 0.01));
      expect(result.totalBill, closeTo(1567.5, 0.01));
    });

    test('Actual bill variance diagnosis reports under/over estimates', () {
      const tariff = TariffConfig(
        id: 'flat_test',
        name: 'Flat Rate',
        type: TariffType.flat,
        flatRatePerKwh: 6.0,
        fixedCharge: 100.0,
        fpppaRatePerKwh: 0.0,
        taxPercentage: 0.0,
      );

      final result = BillCalculator.calculateBill(
        totalUnitsKwh: 200.0, // Bill = 1200 + 100 = 1300
        tariff: tariff,
        actualBill: 1700.0,   // Actual is 400 higher
      );

      expect(result.billVariance, closeTo(400.0, 0.01));
      expect(result.varianceDiagnosis, contains('Actual bill is higher'));
    });
  });

  group('SolarCalculator Tests', () {
    test('Solar kW sizing formula accurately offsets consumption', () {
      const config = SolarConfig(
        peakSunHours: 5.0,
        performanceRatio: 0.80,
        availableRoofAreaSqFt: 500.0,
        sqFtPerKw: 100.0,
      );

      // Monthly kWh = 360 kWh in 30 days = 12 kWh/day
      // Denominator = 5.0 * 0.80 = 4.0
      // Exact kW = 12 / 4.0 = 3.0 kW
      final result = SolarCalculator.calculateSolar(
        monthlyConsumptionKwh: 360.0,
        effectiveRetailTariff: 7.0,
        config: config,
        monthDays: 30,
      );

      expect(result.recommendedKw, closeTo(3.0, 0.01));
      expect(result.isRoofConstrained, isFalse);
      expect(result.dailyGenerationKwh, closeTo(3.0 * 5.0 * 0.80, 0.01)); // 12 kWh/day
      expect(result.monthlyGenerationKwh, closeTo(360.0, 0.01)); // 100% offset
    });

    test('PM Surya Ghar Subsidy calculates tiers accurately', () {
      const config = SolarConfig(subsidyScheme: SubsidyScheme.pmSuryaGharIndia);

      // 1 kW -> ₹30,000
      final sub1 = SolarCalculator.calculateSubsidy(systemKw: 1.0, grossCost: 55000, config: config);
      expect(sub1, closeTo(30000.0, 0.01));

      // 2 kW -> ₹60,000
      final sub2 = SolarCalculator.calculateSubsidy(systemKw: 2.0, grossCost: 110000, config: config);
      expect(sub2, closeTo(60000.0, 0.01));

      // 3 kW -> ₹78,000
      final sub3 = SolarCalculator.calculateSubsidy(systemKw: 3.0, grossCost: 165000, config: config);
      expect(sub3, closeTo(78000.0, 0.01));

      // 5 kW -> ₹78,000 capped
      final sub5 = SolarCalculator.calculateSubsidy(systemKw: 5.0, grossCost: 275000, config: config);
      expect(sub5, closeTo(78000.0, 0.01));
    });

    test('Roof area constraint caps effective system size', () {
      const config = SolarConfig(
        peakSunHours: 5.0,
        performanceRatio: 0.80,
        availableRoofAreaSqFt: 150.0, // Only 150 sq ft allows max 1.5 kW
        sqFtPerKw: 100.0,
      );

      // 480 kWh/month requires ~4.0 kW, but roof only holds 1.5 kW
      final result = SolarCalculator.calculateSolar(
        monthlyConsumptionKwh: 480.0,
        effectiveRetailTariff: 8.0,
        config: config,
        monthDays: 30,
      );

      expect(result.isRoofConstrained, isTrue);
      expect(result.effectiveInstalledKw, closeTo(1.5, 0.01));
    });

    test('NetEnergyBalance Surplus: Solar generates 360 kWh vs 245 kWh appliance load', () {
      final balance = SolarCalculator.calculateNetBalance(
        solarMonthlyKwh: 360.0,
        applianceMonthlyKwh: 245.0,
        retailRatePerKwh: 6.0,
        exportRatePerKwh: 3.20,
        fixedCharges: 100.0,
      );

      // 360 - 245 = +115 kWh surplus
      expect(balance.netBalanceKwh, closeTo(115.0, 0.01));
      expect(balance.isSurplus, isTrue);
      expect(balance.gridImportKwh, equals(0.0));
      expect(balance.gridExportKwh, closeTo(115.0, 0.01));
      expect(balance.exportEarnings, closeTo(115.0 * 3.20, 0.01)); // ₹368.0
      expect(balance.solarNetBill, equals(0.0)); // Zero bill!
    });

    test('NetEnergyBalance Deficit: Solar generates 180 kWh vs 245 kWh appliance load', () {
      final balance = SolarCalculator.calculateNetBalance(
        solarMonthlyKwh: 180.0,
        applianceMonthlyKwh: 245.0,
        retailRatePerKwh: 6.0,
        exportRatePerKwh: 3.20,
        fixedCharges: 100.0,
      );

      // 180 - 245 = -65 kWh deficit
      expect(balance.netBalanceKwh, closeTo(-65.0, 0.01));
      expect(balance.isSurplus, isFalse);
      expect(balance.gridImportKwh, closeTo(65.0, 0.01));
      expect(balance.gridExportKwh, equals(0.0));
      // Remaining bill = 65 * 6.0 + 100 = 490
      expect(balance.solarNetBill, closeTo(490.0, 0.01));
      // Original bill = 245 * 6.0 + 100 = 1570
      expect(balance.originalBill, closeTo(1570.0, 0.01));
      // Savings = 1570 - 490 = 1080
      expect(balance.monthlySavings, closeTo(1080.0, 0.01));
    });

    test('calculateKwhFromElectricalSpecs: 230V at 10A for 5 sun hours over 30 days', () {
      // 230 * 10 = 2300W = 2.3 kW
      // Daily = 2.3 * 5 = 11.5 kWh/day
      // Monthly = 11.5 * 30 = 345 kWh/mo
      final kwh = SolarCalculator.calculateKwhFromElectricalSpecs(
        voltageVolts: 230.0,
        currentAmps: 10.0,
        peakSunHours: 5.0,
        days: 30,
      );
      expect(kwh, closeTo(345.0, 0.01));
    });
  });
}
