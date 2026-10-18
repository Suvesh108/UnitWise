import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/solar_calculator.dart';

class SolarLoadShiftAdvisor extends StatelessWidget {
  final SolarShiftPlan plan;
  final String currency;
  final double solarMonthlyKwh;

  const SolarLoadShiftAdvisor({
    super.key,
    required this.plan,
    required this.currency,
    required this.solarMonthlyKwh,
  });

  @override
  Widget build(BuildContext context) {
    if (solarMonthlyKwh <= 0) {
      return const SizedBox.shrink();
    }

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
                      color: AppTheme.solarGold.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.schedule_rounded, color: AppTheme.solarGold, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SOLAR LOAD-SHIFTING ADVISOR',
                    style: AppTypography.style(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              if (plan.recommendations.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Save ~${Formatters.formatCurrency(plan.totalMonthlySavings, symbol: currency)}/mo',
                    style: AppTypography.style(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.emeraldPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Overview Text
          Text(
            'Run heavy discretionary loads during peak solar irradiance (10:00 AM – 3:00 PM) to utilize 100% free rooftop solar power instead of paying high utility grid rates.',
            style: AppTypography.style(
              fontSize: 12,
              height: 1.35,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),

          if (plan.recommendations.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppTheme.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add laundry, water pump, or geyser appliances to see personalized solar shift schedules.',
                      style: AppTypography.style(fontSize: 11.5, color: AppTheme.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...plan.recommendations.map((rec) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(16),
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
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.emeraldPrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.bolt, size: 14, color: AppTheme.emeraldPrimary),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              rec.appliance.name,
                              style: AppTypography.style(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.solarGold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            rec.optimalWindow,
                            style: AppTypography.style(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.solarGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rec.rationale,
                      style: AppTypography.style(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${rec.monthlyKwh.toStringAsFixed(1)} kWh shiftable',
                          style: AppTypography.style(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          'Saves +${Formatters.formatCurrency(rec.monthlyCostSavings, symbol: currency)}/mo',
                          style: AppTypography.style(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.emeraldPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
