import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/native/native_channel.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/energy_calculator.dart';

class VampireLoadCard extends StatelessWidget {
  final StandbyConsumptionSummary summary;
  final String currency;
  final double effectiveRate;
  final VoidCallback? onInspectOffenders;

  const VampireLoadCard({
    super.key,
    required this.summary,
    required this.currency,
    required this.effectiveRate,
    this.onInspectOffenders,
  });

  @override
  Widget build(BuildContext context) {
    if (summary.totalStandbyWatts <= 0) {
      return const SizedBox.shrink();
    }

    final monthlyCost = summary.monthlyStandbyKwh * effectiveRate;
    final annualCost = monthlyCost * 12.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.alertCoral.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.power_off_outlined,
                      size: 16,
                      color: AppTheme.alertCoral,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ALWAYS-ON VAMPIRE DRAW',
                    style: AppTypography.style(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.alertCoral.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${summary.percentageOfTotal.toStringAsFixed(1)}% of bill',
                  style: AppTypography.style(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.alertCoral,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main Metric Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${summary.totalStandbyWatts.toStringAsFixed(0)}W',
                style: AppTypography.style(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'continuous baseline idle power',
                style: AppTypography.style(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Financial Drain Summary Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECDD3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.savings_outlined, size: 16, color: AppTheme.alertCoral),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Drains ~${Formatters.formatCurrency(annualCost, symbol: currency)}/year (${summary.monthlyStandbyKwh.toStringAsFixed(1)} kWh/mo) while devices sit idle.',
                    style: AppTypography.style(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9F1239),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Top Vampire Offenders List
          if (summary.offenders.isNotEmpty) ...[
            Text(
              'TOP STANDBY OFFENDERS',
              style: AppTypography.style(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMuted,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            ...summary.offenders.take(3).map((offender) {
              final appCost = offender.monthlyStandbyKwh * effectiveRate;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.alertCoral,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        offender.appliance.name,
                        style: AppTypography.style(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${offender.standbyWatts.toStringAsFixed(0)}W idle • ~${Formatters.formatCurrency(appCost, symbol: currency)}/mo',
                      style: AppTypography.style(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
          ],

          // Actionable Recommendation Link
          InkWell(
            onTap: () {
              NativeChannel.triggerHaptic();
              _showVampireReductionSheet(context, summary, currency, effectiveRate);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'How to eliminate vampire standby power',
                    style: AppTypography.style(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.emeraldPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.emeraldPrimary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVampireReductionSheet(
    BuildContext context,
    StandbyConsumptionSummary summary,
    String currency,
    double rate,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.alertCoral.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tips_and_updates_rounded, color: AppTheme.alertCoral, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Eliminate Vampire Power',
                          style: AppTypography.style(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        Text(
                          'Save up to 15% on your monthly bill with zero sacrifice',
                          style: AppTypography.style(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTipRow(
                icon: Icons.power_rounded,
                title: 'Smart Power Strips for TV & Desktops',
                body: 'TVs, set-top boxes, and consoles draw 15-30W even when turned off with remote. A master-slave power strip turns off peripherals automatically.',
              ),
              const SizedBox(height: 12),
              _buildTipRow(
                icon: Icons.ac_unit_rounded,
                title: 'Isolate AC Stabilizers in Winter',
                body: 'Inverter AC crankcase heaters and standby PCBs draw 10-25W 24/7. Turn off the wall isolator switch during seasons you do not run ACs.',
              ),
              const SizedBox(height: 12),
              _buildTipRow(
                icon: Icons.cable_rounded,
                title: 'Unplug Idle Transformer Bricks',
                body: 'Laptop chargers and phone bricks continuously dissipate 2-5W in heat even when not connected to any device.',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.emeraldPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Got It'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTipRow({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.emeraldPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.style(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textDark),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: AppTypography.style(fontSize: 11.5, color: AppTheme.textMuted, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
