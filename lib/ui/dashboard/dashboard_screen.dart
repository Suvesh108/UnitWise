import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import 'package:provider/provider.dart';
import '../../providers/energy_provider.dart';
import '../../providers/settings_provider.dart';
import '../../domain/solar_calculator.dart';
import '../../domain/energy_calculator.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/native/native_channel.dart';
import '../reports/reports_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigateTab;

  const DashboardScreen({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final energy = context.watch<EnergyProvider>();
    final settings = context.watch<SettingsProvider>();
    final summary = energy.consumptionSummary;
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
              // 1. Hero Power Arc & Live Energy Balance Card
              _buildHeroPowerDial(context, balance, summary, currency),
              const SizedBox(height: 14),

              // 2. Bento Stat Grid (2x2)
              _buildBentoGrid(context, summary, balance, currency),
              const SizedBox(height: 14),

              // 3. Ergonomic Quick Action Dock
              _buildQuickActionDock(context),
              const SizedBox(height: 16),

              // 4. Category Load Distribution Strip
              if (summary.categoryResults.isNotEmpty) ...[
                _buildCategoryLoadSection(context, summary),
                const SizedBox(height: 16),
              ],

              // 5. Top Power Consumers Spotlight
              _buildTopConsumersSection(context, summary, energy, currency),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. HERO POWER DIAL CARD
  // -------------------------------------------------------------
  Widget _buildHeroPowerDial(
    BuildContext context,
    NetEnergyBalance balance,
    HouseholdConsumptionSummary summary,
    String currency,
  ) {
    final isSurplus = balance.isSurplus;
    final solarKwh = balance.solarMonthlyKwh;
    final loadKwh = balance.applianceMonthlyKwh;
    final netKwh = balance.netBalanceKwh;
    final accentColor = isSurplus ? AppTheme.emeraldPrimary : AppTheme.warmAmber;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          // Header Row: Status badge & Tap action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ENERGY BALANCE',
                    style: AppTypography.style(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  NativeChannel.triggerHaptic();
                  onNavigateTab(3);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSurplus ? Icons.verified_rounded : Icons.bolt_rounded,
                        size: 13,
                        color: accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSurplus ? 'NET ZERO' : '${balance.offsetPercentage.toStringAsFixed(0)}% SOLAR',
                        style: AppTypography.style(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Central Power Dial Visualization
          Center(
            child: SizedBox(
              width: 170,
              height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(170, 130),
                    painter: _PowerDialPainter(
                      solarKwh: solarKwh,
                      loadKwh: loadKwh,
                      isSurplus: isSurplus,
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${isSurplus ? '+' : ''}${netKwh.toStringAsFixed(0)}',
                            style: AppTypography.style(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: isSurplus ? AppTheme.emeraldPrimary : AppTheme.textDark,
                              letterSpacing: -1.0,
                            ),
                          ),
                        ),
                        Text(
                          'kWh / month',
                          style: AppTypography.style(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isSurplus
                                ? AppTheme.emeraldPrimary.withValues(alpha: 0.1)
                                : AppTheme.warmAmber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isSurplus ? 'SURPLUS EXPORT' : 'GRID DEMAND',
                            style: AppTypography.style(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: isSurplus ? AppTheme.emeraldPrimary : AppTheme.warmAmber,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3 Bottom Metric Chips (Solar Gen, Home Load, Net Cost)
          Row(
            children: [
              Expanded(
                child: _buildDialChip(
                  label: 'SOLAR',
                  value: '+${solarKwh.toStringAsFixed(0)} u',
                  color: AppTheme.solarGold,
                  icon: Icons.wb_sunny_rounded,
                  onTap: () => onNavigateTab(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDialChip(
                  label: 'LOAD',
                  value: '−${loadKwh.toStringAsFixed(0)} u',
                  color: AppTheme.electricCyan,
                  icon: Icons.devices_rounded,
                  onTap: () => onNavigateTab(1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDialChip(
                  label: 'BILL',
                  value: Formatters.formatCurrency(balance.solarNetBill, symbol: currency),
                  color: isSurplus ? AppTheme.emeraldPrimary : AppTheme.alertCoral,
                  icon: Icons.receipt_rounded,
                  onTap: () => onNavigateTab(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDialChip({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        NativeChannel.triggerHaptic();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.style(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppTypography.style(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. BENTO STAT GRID (2x2)
  // -------------------------------------------------------------
  Widget _buildBentoGrid(
    BuildContext context,
    HouseholdConsumptionSummary summary,
    NetEnergyBalance balance,
    String currency,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                title: 'MONTHLY USAGE',
                value: '${summary.totalMonthlyKwh.toStringAsFixed(0)} kWh',
                subtitle: '${summary.applianceResults.length} active devices',
                icon: Icons.bolt_rounded,
                iconColor: AppTheme.electricCyan,
                onTap: () => onNavigateTab(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoCard(
                title: 'ESTIMATED BILL',
                value: Formatters.formatCurrency(balance.solarNetBill, symbol: currency),
                subtitle: balance.isSurplus
                    ? '100% offset (Zero bill)'
                    : 'Save $currency${balance.monthlySavings.toStringAsFixed(0)}/mo',
                icon: Icons.receipt_long_rounded,
                iconColor: balance.isSurplus ? AppTheme.emeraldPrimary : AppTheme.warmAmber,
                onTap: () => onNavigateTab(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                title: 'SOLAR COVERAGE',
                value: '${balance.offsetPercentage.toStringAsFixed(0)}%',
                subtitle: balance.isSurplus
                    ? '+${balance.gridExportKwh.toStringAsFixed(0)} u fed into grid'
                    : '${balance.gridImportKwh.toStringAsFixed(0)} u from utility',
                icon: Icons.solar_power_rounded,
                iconColor: AppTheme.solarGold,
                onTap: () => onNavigateTab(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoCard(
                title: 'DAILY AVERAGE',
                value: '${summary.averageDailyKwh.toStringAsFixed(1)} u/d',
                subtitle: 'Solar generates ${(balance.solarMonthlyKwh / 30.0).toStringAsFixed(1)} u/d',
                icon: Icons.speed_rounded,
                iconColor: AppTheme.emeraldPrimary,
                onTap: () => onNavigateTab(0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
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
          onTap: () {
            NativeChannel.triggerHaptic();
            onTap();
          },
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
                          fontSize: 9.5,
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
                        color: iconColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTypography.style(
                      fontSize: 18,
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
                    fontSize: 10.5,
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

  // -------------------------------------------------------------
  // 3. ERGONOMIC QUICK ACTION DOCK
  // -------------------------------------------------------------
  Widget _buildQuickActionDock(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Add Device',
            icon: Icons.add_circle_outline_rounded,
            color: AppTheme.emeraldPrimary,
            isFilled: true,
            onTap: () => onNavigateTab(1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            label: 'Solar/Inv',
            icon: Icons.wb_sunny_outlined,
            color: AppTheme.solarGold,
            onTap: () => onNavigateTab(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            label: 'Tariffs',
            icon: Icons.tune_rounded,
            color: AppTheme.electricCyan,
            onTap: () => onNavigateTab(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            label: 'Reports',
            icon: Icons.analytics_outlined,
            color: AppTheme.textDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isFilled = false,
  }) {
    return InkWell(
      onTap: () {
        NativeChannel.triggerHaptic();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          color: isFilled ? color : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFilled ? color : AppTheme.borderSubtle,
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isFilled ? Colors.white : color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.style(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isFilled ? Colors.white : AppTheme.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 4. CATEGORY LOAD DISTRIBUTION SECTION
  // -------------------------------------------------------------
  Widget _buildCategoryLoadSection(
    BuildContext context,
    HouseholdConsumptionSummary summary,
  ) {
    final catList = summary.categoryResults.take(4).toList();
    if (catList.isEmpty) return const SizedBox.shrink();

    final colors = [
      AppTheme.emeraldPrimary,
      AppTheme.solarGold,
      AppTheme.electricCyan,
      AppTheme.warmAmber,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LOAD DISTRIBUTION',
                style: AppTypography.style(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                '${summary.totalMonthlyKwh.toStringAsFixed(0)} u Total',
                style: AppTypography.style(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.emeraldPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Multi-color segmented progress line
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 7,
              child: Row(
                children: catList.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final cat = entry.value;
                  final flex = (cat.percentageOfTotal * 10).round().clamp(1, 1000);
                  return Expanded(
                    flex: flex,
                    child: Container(color: colors[idx % colors.length]),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Category Chips Row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: catList.asMap().entries.map((entry) {
              final idx = entry.key;
              final cat = entry.value;
              final col = colors[idx % colors.length];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: col.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${Formatters.getCategoryName(cat.category)}: ${cat.percentageOfTotal.toStringAsFixed(0)}%',
                      style: AppTypography.style(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 5. TOP CONSUMERS SPOTLIGHT SECTION
  // -------------------------------------------------------------
  Widget _buildTopConsumersSection(
    BuildContext context,
    HouseholdConsumptionSummary summary,
    EnergyProvider energy,
    String currency,
  ) {
    final topList = summary.applianceResults.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOP CONSUMING DEVICES',
                style: AppTypography.style(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
              InkWell(
                onTap: () {
                  NativeChannel.triggerHaptic();
                  onNavigateTab(1);
                },
                child: Text(
                  'View All (${summary.applianceResults.length})',
                  style: AppTypography.style(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.emeraldPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (topList.isEmpty) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const Icon(Icons.devices_other_rounded, size: 28, color: AppTheme.textSubtle),
                    const SizedBox(height: 6),
                    Text(
                      'No appliances added yet',
                      style: AppTypography.style(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => onNavigateTab(1),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Add Appliance'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.emeraldPrimary,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ...topList.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final app = entry.value;
              final isLast = rank == topList.length;

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      // Rank Badge
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: rank == 1 ? AppTheme.warmAmber : AppTheme.surfaceMuted,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$rank',
                            style: AppTypography.style(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: rank == 1 ? Colors.white : AppTheme.textDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Device Name & Badges
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.appliance.name,
                              style: AppTypography.style(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                _buildMiniBadge('⚡ ${app.appliance.wattage.toStringAsFixed(0)}W'),
                                const SizedBox(width: 5),
                                _buildMiniBadge('⏱️ ${app.appliance.hoursPerDay.toStringAsFixed(1)}h/d'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Units & Cost
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${app.monthlyKwh.toStringAsFixed(0)} u',
                            style: AppTypography.style(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(
                              app.monthlyKwh *
                                  (energy.billResult.effectiveRatePerKwh > 0
                                      ? energy.billResult.effectiveRatePerKwh
                                      : energy.tariff.flatRatePerKwh),
                              symbol: currency,
                            ),
                            style: AppTypography.style(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Text(
        text,
        style: AppTypography.style(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// POWER DIAL CUSTOM PAINTER
// -------------------------------------------------------------
class _PowerDialPainter extends CustomPainter {
  final double solarKwh;
  final double loadKwh;
  final bool isSurplus;

  _PowerDialPainter({
    required this.solarKwh,
    required this.loadKwh,
    required this.isSurplus,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 12;

    const startAngle = math.pi;
    const sweepTotal = math.pi;

    // 1. Background Arc Track
    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      bgPaint,
    );

    final total = (solarKwh + loadKwh);
    if (total <= 0) return;

    final solarFrac = (solarKwh / total).clamp(0.05, 0.95);
    final loadFrac = 1.0 - solarFrac;

    // 2. Solar Segment (Left)
    final solarPaint = Paint()
      ..color = AppTheme.solarGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final solarSweep = sweepTotal * solarFrac;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      solarSweep,
      false,
      solarPaint,
    );

    // 3. Load Segment (Right)
    final loadPaint = Paint()
      ..color = AppTheme.emeraldPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final loadSweep = sweepTotal * loadFrac;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + solarSweep,
      loadSweep,
      false,
      loadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PowerDialPainter oldDelegate) {
    return oldDelegate.solarKwh != solarKwh ||
        oldDelegate.loadKwh != loadKwh ||
        oldDelegate.isSurplus != isSurplus;
  }
}
