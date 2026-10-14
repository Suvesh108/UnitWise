import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/models/household.dart';
import '../../domain/energy_calculator.dart';
import '../../domain/bill_calculator.dart';
import '../../domain/solar_calculator.dart';

class PdfReportGenerator {
  static Future<Uint8List> generateAuditReport({
    required Household household,
    required HouseholdConsumptionSummary consumption,
    required BillCalculationResult bill,
    required SolarCalculationResult solar,
    NetEnergyBalance? netBalance,
    required String currencySymbol,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'UnitWise',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.Text(
                    'Household Electricity & Solar Feasibility Report',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Profile: ${household.name}',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Location: ${household.location}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Date: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 1.5, color: PdfColors.green700),
          pw.SizedBox(height: 12),

          // Key Highlights
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildStatBox('Monthly Units', '${consumption.totalMonthlyKwh.toStringAsFixed(1)} kWh'),
              _buildStatBox('Estimated Bill', '$currencySymbol${bill.totalBill.toStringAsFixed(0)}'),
              _buildStatBox('Daily Average', '${consumption.averageDailyKwh.toStringAsFixed(1)} kWh/d'),
              _buildStatBox('Recommended Solar', '${solar.effectiveInstalledKw.toStringAsFixed(1)} kW'),
            ],
          ),
          pw.SizedBox(height: 16),

          // Appliance Inventory Table
          pw.Text(
            'Appliance Consumption Breakdown',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (consumption.applianceResults.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Center(
                child: pw.Text(
                  'No appliances recorded yet for this household profile.',
                  style: const pw.TextStyle(color: PdfColors.grey700),
                ),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: ['Appliance', 'Qty', 'Rating / Model', 'Usage / Pattern', 'Monthly kWh', '% Share'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
              cellAlignment: pw.Alignment.centerLeft,
              data: consumption.applianceResults.map((r) {
                final a = r.appliance;
                return [
                  a.name,
                  a.quantity.toString(),
                  '${a.wattage.toStringAsFixed(0)}W',
                  '${a.hoursPerDay.toStringAsFixed(1)}h/day, ${a.daysPerMonth}d',
                  '${r.monthlyKwh.toStringAsFixed(1)} kWh',
                  '${r.percentageOfTotal.toStringAsFixed(1)}%',
                ];
              }).toList(),
            ),
          pw.SizedBox(height: 16),

          // Electricity Bill Analysis
          pw.Text(
            'Electricity Bill Breakdown',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              children: [
                _buildBillRow('Energy Charges', '$currencySymbol${bill.energyCharges.toStringAsFixed(2)}'),
                _buildBillRow('Fixed Meter Charges', '$currencySymbol${bill.fixedCharge.toStringAsFixed(2)}'),
                _buildBillRow('Fuel / FPPPA Surcharge', '$currencySymbol${bill.fpppaCharges.toStringAsFixed(2)}'),
                _buildBillRow('Electricity Duty & Tax', '$currencySymbol${bill.taxAmount.toStringAsFixed(2)}'),
                pw.Divider(color: PdfColors.grey400),
                _buildBillRow(
                  'Total Estimated Monthly Bill',
                  '$currencySymbol${bill.totalBill.toStringAsFixed(2)}',
                  isBold: true,
                ),
                if (household.actualLastMonthBill != null) ...[
                  pw.SizedBox(height: 4),
                  _buildBillRow(
                    'Actual Customer Bill',
                    '$currencySymbol${household.actualLastMonthBill!.toStringAsFixed(2)}',
                  ),
                  _buildBillRow(
                    'Difference (Variance)',
                    '$currencySymbol${(household.actualLastMonthBill! - bill.totalBill).toStringAsFixed(2)}',
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          if (netBalance != null) ...[
            pw.Text(
              'Live Net Energy Flow & Solar Offset Audit',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Flow Parameter', 'Audit Metric', 'Net Impact'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
              cellAlignment: pw.Alignment.centerLeft,
              data: [
                ['Total Solar Generation', '+${netBalance.solarMonthlyKwh.toStringAsFixed(0)} kWh/month', 'Clean on-site solar yield'],
                ['Total Household Appliance Demand', '-${netBalance.applianceMonthlyKwh.toStringAsFixed(0)} kWh/month', 'Combined appliance load'],
                ['Net Grid Balance Position', '${netBalance.isSurplus ? '+' : ''}${netBalance.netBalanceKwh.toStringAsFixed(0)} kWh/month', netBalance.isSurplus ? '100% Green Self-Sufficient (Export Surplus)' : 'Supplemental utility grid import needed'],
                ['Solar Self-Sufficiency Coverage', '${netBalance.offsetPercentage.toStringAsFixed(0)}%', netBalance.isSurplus ? 'Zero utility bill achieved' : 'Covers ${netBalance.offsetPercentage.toStringAsFixed(0)}% of household consumption'],
                ['Pre-Solar Electricity Bill', '$currencySymbol${netBalance.originalBill.toStringAsFixed(0)}', 'Standard utility cost without solar'],
                ['Post-Solar Net Payable Bill', '$currencySymbol${netBalance.solarNetBill.toStringAsFixed(0)}', netBalance.isSurplus ? 'Zero bill (100% slashed)' : 'Slashed utility charges'],
                ['Monthly Financial Savings', '$currencySymbol${netBalance.monthlySavings.toStringAsFixed(0)}/month', '$currencySymbol${(netBalance.monthlySavings * 12).toStringAsFixed(0)} saved per year'],
                if (netBalance.exportEarnings > 0)
                  ['Discom Feed-in Export Credits', '$currencySymbol${netBalance.exportEarnings.toStringAsFixed(0)}/month', 'Grid export credit earnings'],
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // Solar Sizing & Rooftop Feasibility
          pw.Text(
            'Rooftop Solar System Recommendation',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Parameter', 'Value', 'Notes'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellAlignment: pw.Alignment.centerLeft,
            data: [
              ['Recommended Solar Capacity', '${solar.effectiveInstalledKw.toStringAsFixed(1)} kW', 'Designed to offset ~100% of consumption'],
              ['Rooftop Space Required', '${solar.roofAreaRequiredSqFt.toStringAsFixed(0)} sq. ft', 'Shadow-free rooftop area'],
              ['Estimated Daily Generation', '${solar.dailyGenerationKwh.toStringAsFixed(1)} kWh/day', 'Accounting for system performance ratio'],
              ['Estimated Monthly Generation', '${solar.monthlyGenerationKwh.toStringAsFixed(0)} kWh/month', 'Solar energy produced'],
              ['Estimated Gross Cost', '$currencySymbol${solar.grossCost.toStringAsFixed(0)}', 'Equipment, inverter & balance of system'],
              ['Eligible Subsidy', '-$currencySymbol${solar.subsidyAmount.toStringAsFixed(0)}', 'PM Surya Ghar / Solar Subsidy'],
              ['Net Investment Cost', '$currencySymbol${solar.netCost.toStringAsFixed(0)}', 'Net out-of-pocket investment'],
              ['Estimated Annual Savings', '$currencySymbol${solar.annualSavings.toStringAsFixed(0)}/year', 'Bill reduction + net metering export credit'],
              ['Estimated Payback Period', '${solar.paybackPeriodYears.toStringAsFixed(1)} Years', 'Full return of capital investment'],
              ['25-Year Net Return', '$currencySymbol${solar.lifetimeNetSavings25Years.toStringAsFixed(0)}', 'Net lifetime savings (accounting for degradation)'],
              ['Annual CO2 Offset', '${solar.co2OffsetKgAnnual.toStringAsFixed(0)} kg CO2', 'Environmental clean energy impact'],
            ],
          ),
          pw.SizedBox(height: 20),

          // Disclaimer Footer
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            child: pw.Text(
              'Notice: All calculations are estimates based on standard rated values and typical usage patterns. Actual consumption varies by appliance age, efficiency rating, seasonal climate, and tariff schedule revisions.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildStatBox(String title, String value) {
    return pw.Container(
      width: 110,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBillRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
