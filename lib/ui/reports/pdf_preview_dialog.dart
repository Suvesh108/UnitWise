import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import 'package:provider/provider.dart';
import '../../providers/energy_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/utils/pdf_generator.dart';
import '../../core/native/native_channel.dart';
import '../../core/theme/app_theme.dart';

class PdfPreviewDialog extends StatefulWidget {
  const PdfPreviewDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const PdfPreviewDialog(),
    );
  }

  @override
  State<PdfPreviewDialog> createState() => _PdfPreviewDialogState();
}

class _PdfPreviewDialogState extends State<PdfPreviewDialog> {
  bool _isGenerating = true;
  Uint8List? _pdfBytes;
  String _summaryText = '';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    final energy = context.read<EnergyProvider>();
    final settings = context.read<SettingsProvider>();

    try {
      final balance = energy.netEnergyBalance;

      final bytes = await PdfReportGenerator.generateAuditReport(
        household: energy.activeHousehold,
        consumption: energy.consumptionSummary,
        bill: energy.billResult,
        solar: energy.solarResult,
        netBalance: balance,
        currencySymbol: settings.currency,
      );

      final s = energy.consumptionSummary;
      final sol = energy.solarResult;

      final summary = '''
*UnitWise Household Energy & Solar Report*
Profile: ${energy.activeHousehold.name} (${energy.activeHousehold.location})
Monthly Load: ${s.totalMonthlyKwh.toStringAsFixed(1)} kWh (${s.averageDailyKwh.toStringAsFixed(1)} units/day)
Solar Generation: ${balance.solarMonthlyKwh.toStringAsFixed(0)} kWh/mo
Net Grid Position: ${balance.isSurplus ? '+' : ''}${balance.netBalanceKwh.toStringAsFixed(0)} kWh (${balance.isSurplus ? 'Export Surplus' : 'Import Needed'})
Net Monthly Bill: ${settings.currency}${balance.solarNetBill.toStringAsFixed(0)} (Saves ${settings.currency}${balance.monthlySavings.toStringAsFixed(0)}/mo)

*Top Energy Consumers:*
${s.topConsumers.map((t) => '• ${t.appliance.name}: ${t.monthlyKwh.toStringAsFixed(1)} kWh (${t.percentageOfTotal.toStringAsFixed(0)}% load, ${energy.getApplianceSolarShare(t.appliance).toStringAsFixed(0)}% solar)').join('\n')}

*Rooftop Solar Recommendation:*
Recommended System: ${sol.effectiveInstalledKw.toStringAsFixed(1)} kW
Monthly Solar Generation: ${sol.monthlyGenerationKwh.toStringAsFixed(0)} kWh
Net System Cost: ${settings.currency}${sol.netCost.toStringAsFixed(0)} (after subsidy)
Annual Savings: ${settings.currency}${sol.annualSavings.toStringAsFixed(0)}
Payback Period: ${sol.paybackPeriodYears.toStringAsFixed(1)} Years
Lifetime Net Return: ${settings.currency}${sol.lifetimeNetSavings25Years.toStringAsFixed(0)}

Generated via UnitWise Android App (Kotlin + Flutter)
''';

      setState(() {
        _pdfBytes = bytes;
        _summaryText = summary;
        _isGenerating = false;
      });
    } catch (e) {
      debugPrint('Error generating PDF report: $e');
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.alertCoral.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.picture_as_pdf, color: AppTheme.alertCoral, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'Audit Report Preview',
            style: AppTypography.style(fontWeight: FontWeight.w800, fontSize: 17),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _isGenerating
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppTheme.emeraldPrimary),
                      const SizedBox(height: 12),
                      Text(
                        'Generating audit PDF...',
                        style: AppTypography.style(fontSize: 13, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppTheme.emeraldPrimary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'PDF ready (${((_pdfBytes?.lengthInBytes ?? 0) / 1024).toStringAsFixed(1)} KB)',
                              style: AppTypography.style(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: AppTheme.emeraldPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'AUDIT SUMMARY PREVIEW',
                      style: AppTypography.style(
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: SelectableText(
                        _summaryText,
                        style: AppTypography.style(fontSize: 11.5, height: 1.4, color: AppTheme.textDark),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.share, size: 15),
          label: const Text('Share Summary'),
          onPressed: _summaryText.isEmpty
              ? null
              : () async {
                  NativeChannel.triggerHaptic();
                  await NativeChannel.shareText(
                    text: _summaryText,
                    title: 'UnitWise Energy & Solar Report',
                  );
                },
        ),
      ],
    );
  }
}
