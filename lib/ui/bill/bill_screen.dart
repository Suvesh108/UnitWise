import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import 'package:provider/provider.dart';
import '../../providers/energy_provider.dart';
import '../../providers/settings_provider.dart';
import '../../data/models/tariff_config.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/native/native_channel.dart';
import 'tariff_settings_dialog.dart';

class BillScreen extends StatefulWidget {
  const BillScreen({super.key});

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  final TextEditingController _actualBillController = TextEditingController();
  bool _isEditingActual = false;

  @override
  void initState() {
    super.initState();
    final h = context.read<EnergyProvider>().activeHousehold;
    if (h.actualLastMonthBill != null) {
      _actualBillController.text = h.actualLastMonthBill!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _actualBillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final energy = context.watch<EnergyProvider>();
    final settings = context.watch<SettingsProvider>();
    final summary = energy.consumptionSummary;
    final bill = energy.billResult;
    final balance = energy.netEnergyBalance;
    final tariff = energy.tariff;
    final currency = settings.currency;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        title: Text(
          'Bill Estimator & Net Metering',
          style: AppTypography.style(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.tune_outlined, size: 16, color: AppTheme.emeraldPrimary),
            label: Text(
              'Tariff Settings',
              style: AppTypography.style(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: AppTheme.emeraldPrimary,
              ),
            ),
            onPressed: () => TariffSettingsDialog.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Estimated Bill Card with Solar Net Metering
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                balance.isSurplus ? Icons.verified : Icons.solar_power_outlined,
                                size: 15,
                                color: balance.isSurplus ? AppTheme.emeraldPrimary : AppTheme.solarGold,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'NET PAYABLE WITH SOLAR',
                                style: AppTypography.style(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: balance.isSurplus ? AppTheme.emeraldPrimary : AppTheme.solarGold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            Formatters.formatCurrency(balance.solarNetBill, symbol: currency),
                            style: AppTypography.style(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: balance.isSurplus ? AppTheme.emeraldPrimary : AppTheme.textDark,
                              letterSpacing: -1.0,
                            ),
                          ),
                          Text(
                            (balance.solarMonthlyKwh == 0 && balance.applianceMonthlyKwh == 0)
                                ? 'No appliances added yet. Add devices to estimate bill.'
                                : (balance.isSurplus
                                    ? 'Zero bill (Saves ${Formatters.formatCurrency(balance.monthlySavings, symbol: currency)}/mo)'
                                    : 'Slashed from ${Formatters.formatCurrency(balance.originalBill, symbol: currency)} (Save ${Formatters.formatCurrency(balance.monthlySavings, symbol: currency)})'),
                            style: AppTypography.style(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${balance.solarMonthlyKwh.toStringAsFixed(0)} / ${summary.totalMonthlyKwh.toStringAsFixed(0)} u',
                              style: AppTypography.style(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Text(
                              'Solar / Load',
                              style: AppTypography.style(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tariff: ${tariff.name}',
                        style: AppTypography.style(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Utility Gross: ${Formatters.formatCurrency(bill.totalBill, symbol: currency)}',
                        style: AppTypography.style(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Net Metering Summary Pill
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: balance.isSurplus ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: balance.isSurplus ? const Color(0xFFBBF7D0) : const Color(0xFFBFDBFE),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (balance.isSurplus ? AppTheme.emeraldPrimary : AppTheme.electricCyan).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      balance.isSurplus ? Icons.energy_savings_leaf_rounded : Icons.electric_bolt_rounded,
                      size: 20,
                      color: balance.isSurplus ? AppTheme.emeraldPrimary : AppTheme.electricCyan,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balance.isSurplus ? 'Net Metering Grid Credit' : 'Supplemental Grid Demand',
                          style: AppTypography.style(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          balance.isSurplus
                              ? '+${balance.gridExportKwh.toStringAsFixed(0)} surplus units sent to grid. Discom credit: ${Formatters.formatCurrency(balance.exportEarnings, symbol: currency)}.'
                              : 'Your solar system covers ${balance.offsetPercentage.toStringAsFixed(0)}% of demand. Only ${balance.gridImportKwh.toStringAsFixed(0)} units are billed by your Discom.',
                          style: AppTypography.style(fontSize: 11.5, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Actual Bill Comparison & Variance Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.compare_arrows_rounded, color: AppTheme.electricCyan, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Actual DISCOM Bill Check',
                            style: AppTypography.style(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => setState(() => _isEditingActual = !_isEditingActual),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            _isEditingActual ? 'Done' : 'Update Bill',
                            style: AppTypography.style(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.emeraldPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_isEditingActual) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _actualBillController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Your DISCOM Bill Amount ($currency)',
                              prefixText: '$currency ',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () async {
                            NativeChannel.triggerHaptic();
                            final val = double.tryParse(_actualBillController.text);
                            await energy.updateActiveHousehold(
                              energy.activeHousehold.copyWith(actualLastMonthBill: val),
                            );
                            setState(() => _isEditingActual = false);
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (bill.actualBill != null && bill.actualBill! > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Actual Bill: $currency${bill.actualBill!.toStringAsFixed(0)}',
                          style: AppTypography.style(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          'Variance: ${(bill.billVariance! >= 0 ? '+' : '')}$currency${bill.billVariance!.toStringAsFixed(0)}',
                          style: AppTypography.style(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: bill.billVariance! > 0 ? AppTheme.alertCoral : AppTheme.emeraldPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Text(
                        bill.varianceDiagnosis,
                        style: AppTypography.style(
                          fontSize: 12,
                          height: 1.4,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Enter your actual bill to detect unmetered standby power and calibrate appliance estimates.',
                      style: AppTypography.style(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Itemized Bill Components
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ITEMIZED CHARGES',
                    style: AppTypography.style(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildBillItem(
                    'Energy Charges',
                    Formatters.formatCurrency(bill.energyCharges, symbol: currency),
                    'Based on ${summary.totalMonthlyKwh.toStringAsFixed(1)} units consumption',
                  ),
                  const Divider(height: 20),
                  _buildBillItem(
                    'Fixed Meter Charges',
                    Formatters.formatCurrency(bill.fixedCharge, symbol: currency),
                    'Monthly sanctioned connection fee',
                  ),
                  const Divider(height: 20),
                  _buildBillItem(
                    'FPPPA / Fuel Surcharge',
                    Formatters.formatCurrency(bill.fpppaCharges, symbol: currency),
                    '$currency${tariff.fpppaRatePerKwh.toStringAsFixed(2)} per unit adjustment',
                  ),
                  const Divider(height: 20),
                  _buildBillItem(
                    'Electricity Duty & Tax',
                    Formatters.formatCurrency(bill.taxAmount, symbol: currency),
                    '${tariff.taxPercentage.toStringAsFixed(1)}% statutory duty',
                  ),
                  const Divider(height: 24, thickness: 1.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Estimated Bill',
                        style: AppTypography.style(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        Formatters.formatCurrency(bill.totalBill, symbol: currency),
                        style: AppTypography.style(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: AppTheme.emeraldPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Slab Distribution Breakdown Table
            if (tariff.type == TariffType.tieredSlab && bill.slabBreakdown.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SLAB DISTRIBUTION',
                      style: AppTypography.style(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(3),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(2.5),
                      },
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                          ),
                          children: [
                            _buildTableHead('Slab'),
                            _buildTableHead('Units'),
                            _buildTableHead('Rate'),
                            _buildTableHead('Cost'),
                          ],
                        ),
                        ...bill.slabBreakdown.map((s) {
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  s.toUnits.isInfinite
                                      ? '${s.fromUnits.toStringAsFixed(0)}+'
                                      : '${s.fromUnits.toStringAsFixed(0)}-${s.toUnits.toStringAsFixed(0)}',
                                  style: AppTypography.style(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  '${s.unitsInSlab.toStringAsFixed(1)} u',
                                  style: AppTypography.style(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  '$currency${s.ratePerKwh.toStringAsFixed(2)}',
                                  style: AppTypography.style(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  Formatters.formatCurrency(s.cost, symbol: currency),
                                  style: AppTypography.style(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTableHead(String title) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        title,
        style: AppTypography.style(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _buildBillItem(String title, String amount, String description) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.style(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: AppTypography.style(
                fontSize: 11.5,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        Text(
          amount,
          style: AppTypography.style(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}
