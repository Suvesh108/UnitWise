import '../data/models/tariff_config.dart';

class SlabBreakdownItem {
  final double fromUnits;
  final double toUnits;
  final double unitsInSlab;
  final double ratePerKwh;
  final double cost;

  const SlabBreakdownItem({
    required this.fromUnits,
    required this.toUnits,
    required this.unitsInSlab,
    required this.ratePerKwh,
    required this.cost,
  });
}

class BillCalculationResult {
  final double totalUnitsKwh;
  final double energyCharges;
  final List<SlabBreakdownItem> slabBreakdown;
  final double fixedCharge;
  final double fpppaCharges;
  final double taxAmount;
  final double totalBill;
  final double effectiveRatePerKwh;
  final double? actualBill;
  final double? billVariance;
  final double? billVariancePercent;
  final String varianceDiagnosis;

  const BillCalculationResult({
    required this.totalUnitsKwh,
    required this.energyCharges,
    required this.slabBreakdown,
    required this.fixedCharge,
    required this.fpppaCharges,
    required this.taxAmount,
    required this.totalBill,
    required this.effectiveRatePerKwh,
    this.actualBill,
    this.billVariance,
    this.billVariancePercent,
    this.varianceDiagnosis = '',
  });

  static const BillCalculationResult empty = BillCalculationResult(
    totalUnitsKwh: 0,
    energyCharges: 0,
    slabBreakdown: [],
    fixedCharge: 0,
    fpppaCharges: 0,
    taxAmount: 0,
    totalBill: 0,
    effectiveRatePerKwh: 0,
  );
}

class BillCalculator {
  static BillCalculationResult calculateBill({
    required double totalUnitsKwh,
    required TariffConfig tariff,
    double? actualBill,
  }) {
    if (totalUnitsKwh <= 0) {
      return BillCalculationResult.empty;
    }

    double energyCharges = 0.0;
    final List<SlabBreakdownItem> slabBreakdown = [];

    if (tariff.type == TariffType.flat) {
      energyCharges = totalUnitsKwh * tariff.flatRatePerKwh;
      slabBreakdown.add(
        SlabBreakdownItem(
          fromUnits: 0,
          toUnits: totalUnitsKwh,
          unitsInSlab: totalUnitsKwh,
          ratePerKwh: tariff.flatRatePerKwh,
          cost: energyCharges,
        ),
      );
    } else {
      // Tiered slab calculation
      double remainingUnits = totalUnitsKwh;

      for (final slab in tariff.slabs) {
        if (remainingUnits <= 0) break;

        final slabCapacity = slab.toUnits.isInfinite
            ? remainingUnits
            : (slab.toUnits - slab.fromUnits);

        final unitsInThisSlab = remainingUnits < slabCapacity ? remainingUnits : slabCapacity;
        final slabCost = unitsInThisSlab * slab.ratePerKwh;

        energyCharges += slabCost;
        slabBreakdown.add(
          SlabBreakdownItem(
            fromUnits: slab.fromUnits,
            toUnits: slab.toUnits,
            unitsInSlab: unitsInThisSlab,
            ratePerKwh: slab.ratePerKwh,
            cost: slabCost,
          ),
        );

        remainingUnits -= unitsInThisSlab;
      }
    }

    final fpppaCharges = totalUnitsKwh * tariff.fpppaRatePerKwh;
    final fixedCharge = tariff.fixedCharge;
    final subtotal = energyCharges + fpppaCharges + fixedCharge;
    final taxAmount = (subtotal * tariff.taxPercentage) / 100.0;
    final totalBill = subtotal + taxAmount;
    final effectiveRatePerKwh = totalUnitsKwh > 0 ? totalBill / totalUnitsKwh : 0.0;

    // Variance diagnosis
    double? variance;
    double? variancePercent;
    String diagnosis = '';

    if (actualBill != null && actualBill > 0) {
      variance = actualBill - totalBill;
      variancePercent = totalBill > 0 ? (variance / totalBill) * 100.0 : 0.0;

      if (variance.abs() < 50) {
        diagnosis = 'Excellent match! Your appliance profile accurately matches your bill.';
      } else if (variance > 0) {
        if (variancePercent > 25) {
          diagnosis = 'Actual bill is higher by ${tariff.currencySymbol}${variance.toStringAsFixed(0)} (+${variancePercent.toStringAsFixed(1)}%). Consider checking for standby/phantom loads, older inefficient appliances, or unrecorded water heating.';
        } else {
          diagnosis = 'Actual bill is slightly higher by ${tariff.currencySymbol}${variance.toStringAsFixed(0)}. Normal seasonal fluctuation or occasional high appliance runtimes.';
        }
      } else {
        diagnosis = 'Your estimate is higher than actual by ${tariff.currencySymbol}${(-variance).toStringAsFixed(0)}. You may be using some appliances less than the default hours.';
      }
    }

    return BillCalculationResult(
      totalUnitsKwh: totalUnitsKwh,
      energyCharges: energyCharges,
      slabBreakdown: slabBreakdown,
      fixedCharge: fixedCharge,
      fpppaCharges: fpppaCharges,
      taxAmount: taxAmount,
      totalBill: totalBill,
      effectiveRatePerKwh: effectiveRatePerKwh,
      actualBill: actualBill,
      billVariance: variance,
      billVariancePercent: variancePercent,
      varianceDiagnosis: diagnosis,
    );
  }
}
