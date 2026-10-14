import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/energy_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/native/native_channel.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigateTab;

  const DashboardScreen({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final energy = context.watch<EnergyProvider>();
    final settings = context.watch<SettingsProvider>();
    final summary = energy.consumptionSummary;
    final bill = energy.billResult;
    final balance = energy.netEnergyBalance;
    final currency = settings.currency;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: RefreshIndicator(
        color: AppTheme.emeraldPrimary,
        backgroundColor: Colors.white,
        onRefresh: () async {
          await settings.refreshDeviceStats();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Unified Solar vs Appliance Energy Balance Bento Card
              _buildHeroConsumptionCard(context, summary, bill, balance, currency, () => onNavigateTab(3)),
              const SizedBox(height: 12),

              // 2. Bento Secondary Metrics (Net Bill & Daily Average / Solar Yield)
              Row(
                children: [
                  Expanded(
                    child: _buildBentoStatCard(
                      context,
                      title: 'ESTIMATED BILL',
                      value: Formatters.formatCurrency(balance.solarNetBill, symbol: currency),
                      subtitle: balance.isSurplus ? 'Zero bill (100% solar offset)' : 'Saves $currency${balance.monthlySavings.toStringAsFixed(0)}/mo',
                      icon: Icons.receipt_long_outlined,
                      iconColor: balance.isSurplus ? AppTheme.emeraldPrimary : AppTheme.warmAmber,
                      onTap: () => onNavigateTab(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBentoStatCard(
                      context,
                      title: 'DAILY AVERAGE',
                      value: '${summary.averageDailyKwh.toStringAsFixed(1)} kWh',
                      subtitle: 'Solar generates ${(balance.solarMonthlyKwh / energy.activeHousehold.daysInMonth).toStringAsFixed(1)} u/d',
                      icon: Icons.solar_power_outlined,
                      iconColor: AppTheme.solarGold,
                      onTap: () => onNavigateTab(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Actual Bill Comparison (if recorded)
              if (bill.actualBill != null && bill.actualBill! > 0) ...[
                _buildVarianceMinimalCard(context, bill, currency),
                const SizedBox(height: 12),
              ],

              // 4. Solar Generation & Net Balance Card
              _buildSolarMinimalCard(context, balance, currency, () => onNavigateTab(3)),
              const SizedBox(height: 16),

              // 5. Quick Minimalist Navigation Action Bar
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionBtn(
                      label: 'Add Appliance',
                      icon: Icons.add_circle_outline,
                      onTap: () => onNavigateTab(1),
                      isPrimary: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickActionBtn(
                      label: 'Bill Slabs',
                      icon: Icons.tune_outlined,
                      onTap: () => onNavigateTab(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickActionBtn(
                      label: 'Solar Flow',
                      icon: Icons.solar_power_outlined,
                      onTap: () => onNavigateTab(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 6. Top Energy Consuming Appliances
              _buildTopConsumersMinimal(context, summary, energy),
              const SizedBox(height: 16),

              // 7. Category Distribution
              if (summary.categoryResults.isNotEmpty)
                _buildCategoryDonutCard(context, summary),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroConsumptionCard(
    BuildContext context,
    dynamic summary,
    dynamic bill,
    dynamic balance,
    String currency,
    VoidCallback onGoSolar,
  ) {
    final isSurplus = balance.isSurplus;
    final statusColor = isSurplus ? AppTheme.emeraldPrimary : AppTheme.warmAmber;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'MONTHLY CONSUMPTION & SOLAR FLOW',
                        style: AppTypography.style(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onGoSolar,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isSurplus ? Icons.verified : Icons.solar_power_outlined, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        isSurplus ? 'NET ZERO' : '${balance.offsetPercentage.toStringAsFixed(0)}% SOLAR',
                        style: AppTypography.style(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Central Net Energy Flow Equation: Solar Gen - Appliances = Net Balance
          Row(
            children: [
              // 1. Solar Produced
              Expanded(
                flex: 4,
                child: InkWell(
                  onTap: onGoSolar,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SOLAR GEN',
                          style: AppTypography.style(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppTheme.solarGold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '+${balance.solarMonthlyKwh.toStringAsFixed(0)}',
                            style: AppTypography.style(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textDark, letterSpacing: -0.5),
                          ),
                        ),
                        Text(
                          'kWh / mo',
                          style: AppTypography.style(fontSize: 9.5, color: AppTheme.textMuted),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 3),
                child: Text('−', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              ),

              // 2. Appliances Consumed
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'APPLIANCES',
                        style: AppTypography.style(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppTheme.emeraldPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '−${summary.totalMonthlyKwh.toStringAsFixed(0)}',
                          style: AppTypography.style(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textDark, letterSpacing: -0.5),
                        ),
                      ),
                      Text(
                        '${summary.applianceResults.length} items',
                        style: AppTypography.style(fontSize: 9.5, color: AppTheme.textMuted),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 3),
                child: Text('=', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              ),

              // 3. Net Grid Position
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSurplus ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: statusColor, width: 1.3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSurplus ? 'NET SURPLUS' : 'GRID DEMAND',
                        style: AppTypography.style(fontSize: 8.5, fontWeight: FontWeight.w800, color: statusColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${isSurplus ? '+' : ''}${balance.netBalanceKwh.toStringAsFixed(0)} kWh',
                          style: AppTypography.style(fontSize: 16, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: -0.5),
                        ),
                      ),
                      Text(
                        isSurplus ? 'Grid Export' : 'Import Needed',
                        style: AppTypography.style(fontSize: 9.5, color: AppTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Solar Self-Sufficiency Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (balance.offsetPercentage / 100.0).clamp(0.05, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              color: statusColor,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Solar: ${balance.offsetPercentage.toStringAsFixed(0)}%',
                  style: AppTypography.style(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSurplus
                      ? '100% Slashed (Zero Bill)'
                      : '$currency${balance.originalBill.toStringAsFixed(0)} ➔ $currency${balance.solarNetBill.toStringAsFixed(0)} net',
                  textAlign: TextAlign.end,
                  style: AppTypography.style(fontSize: 10.5, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.style(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTypography.style(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.style(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVarianceMinimalCard(BuildContext context, dynamic bill, String currency) {
    final variance = bill.billVariance ?? 0.0;
    final isHigher = variance > 0;
    final accent = isHigher ? AppTheme.alertCoral : AppTheme.emeraldPrimary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(isHigher ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Actual vs Estimate',
                        style: AppTypography.style(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${isHigher ? '+' : ''}$currency${variance.toStringAsFixed(0)}',
                      style: AppTypography.style(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  bill.varianceDiagnosis,
                  style: AppTypography.style(
                    fontSize: 11.5,
                    height: 1.35,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolarMinimalCard(
    BuildContext context,
    dynamic balance,
    String currency,
    VoidCallback onTap,
  ) {
    final isSurplus = balance.isSurplus;
    final statusColor = isSurplus ? AppTheme.emeraldPrimary : AppTheme.solarGold;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSurplus ? const Color(0xFFECFDF5) : AppTheme.solarGoldLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      isSurplus ? Icons.check_circle_outline : Icons.solar_power_outlined,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Solar Net Balance',
                              style: AppTypography.style(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isSurplus ? 'NET SURPLUS' : 'DEFICIT',
                              style: AppTypography.style(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${balance.solarMonthlyKwh.toStringAsFixed(0)} kWh solar • ${balance.netKwh.abs().toStringAsFixed(0)} kWh ${isSurplus ? 'surplus export' : 'grid import'}',
                        style: AppTypography.style(
                          fontSize: 11.5,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.textSubtle, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      color: isPrimary ? AppTheme.emeraldPrimary : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          NativeChannel.triggerHaptic();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: isPrimary ? null : Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isPrimary ? Colors.white : AppTheme.textDark,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: AppTypography.style(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isPrimary ? Colors.white : AppTheme.textDark,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopConsumersMinimal(BuildContext context, dynamic summary, EnergyProvider energy) {
    final top = summary.topConsumers;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOP ENERGY CONSUMERS',
                style: AppTypography.style(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'Top 3 items',
                style: AppTypography.style(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSubtle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No appliances added yet.',
                  style: AppTypography.style(color: AppTheme.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            ...top.asMap().entries.map((entry) {
              final idx = entry.key;
              final r = entry.value;
              final catColor = Formatters.getCategoryColor(r.appliance.category);
              final solarShare = energy.getApplianceSolarShare(r.appliance);
              final isCovered = energy.isApplianceSolarCovered(r.appliance);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: AppTypography.style(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.appliance.name,
                                style: AppTypography.style(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppTheme.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 5,
                                runSpacing: 2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    '${r.appliance.quantity} unit(s) • ${r.appliance.hoursPerDay.toStringAsFixed(1)}h daily',
                                    style: AppTypography.style(
                                      fontSize: 10.5,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: (isCovered ? AppTheme.emeraldPrimary : AppTheme.solarGold).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      '☀️ ${solarShare.toStringAsFixed(0)}% solar',
                                      style: AppTypography.style(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: isCovered ? AppTheme.emeraldPrimary : AppTheme.solarGold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${r.monthlyKwh.toStringAsFixed(1)} kWh',
                              style: AppTypography.style(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Text(
                              '${r.percentageOfTotal.toStringAsFixed(1)}% home load',
                              style: AppTypography.style(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: catColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (r.percentageOfTotal / 100.0).clamp(0.01, 1.0),
                        minHeight: 5,
                        backgroundColor: const Color(0xFFF1F5F9),
                        color: catColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCategoryDonutCard(BuildContext context, dynamic summary) {
    final categories = summary.categoryResults;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CATEGORY ALLOCATION',
            style: AppTypography.style(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 26,
                      sections: categories.map<PieChartSectionData>((c) {
                        final color = Formatters.getCategoryColor(c.category);
                        return PieChartSectionData(
                          color: color,
                          value: c.monthlyKwh,
                          title: '${c.percentageOfTotal.toStringAsFixed(0)}%',
                          radius: 30,
                          titleStyle: AppTypography.style(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: categories.map<Widget>((c) {
                        final color = Formatters.getCategoryColor(c.category);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  Formatters.getCategoryName(c.category),
                                  style: AppTypography.style(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${c.monthlyKwh.toStringAsFixed(0)}u',
                                style: AppTypography.style(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
