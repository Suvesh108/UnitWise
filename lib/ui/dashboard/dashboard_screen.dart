import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../core/native/native_channel.dart';
import '../../core/utils/formatters.dart';
import '../../domain/energy_calculator.dart';
import '../../domain/solar_calculator.dart';
import '../../providers/energy_provider.dart';
import '../../providers/settings_provider.dart';
import '../appliances/auto_detect_dialog.dart';
import '../widgets/smooth_entrance.dart';
import 'widgets/energy_donut_chart.dart';
import 'widgets/energy_flow_diagram.dart';
import 'widgets/vampire_load_card.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigateTab;

  const DashboardScreen({super.key, required this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _heroViewIndex = 0; // 0 = Donut Breakdown, 1 = Live Power Flow

  @override
  Widget build(BuildContext context) {
    final energy = context.watch<EnergyProvider>();
    final settings = context.watch<SettingsProvider>();
    final summary = energy.consumptionSummary;
    final balance = energy.netEnergyBalance;
    final currency = settings.currency;
    final effectiveRate = energy.billResult.effectiveRatePerKwh > 0
        ? energy.billResult.effectiveRatePerKwh
        : energy.tariff.flatRatePerKwh;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: RefreshIndicator(
        color: AppTheme.emeraldPrimary,
        backgroundColor: Colors.white,
        onRefresh: () async {
          await settings.refreshDeviceStats();
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero View Mode Toggle
              Center(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderSubtle),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeroTabItem(0, 'Breakdown', Icons.pie_chart_outline_rounded),
                      _buildHeroTabItem(1, 'Power Flow', Icons.alt_route_rounded),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 1. Hero Card: Animated Donut Breakdown or Live Particle Power Flow
              SmoothEntrance(
                delayMs: 0,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _heroViewIndex == 0
                      ? EnergyDonutChart(
                          key: const ValueKey('donut_chart'),
                          solarKwh: balance.solarMonthlyKwh,
                          loadKwh: balance.applianceMonthlyKwh,
                          netKwh: balance.netBalanceKwh,
                          isSurplus: balance.isSurplus,
                          categoryResults: summary.categoryResults,
                          currency: currency,
                          onNavigateSolar: () => widget.onNavigateTab(3),
                          onNavigateAppliances: () => widget.onNavigateTab(1),
                        )
                      : EnergyFlowDiagram(
                          key: const ValueKey('flow_diagram'),
                          solarKwh: balance.solarMonthlyKwh,
                          loadKwh: balance.applianceMonthlyKwh,
                          netKwh: balance.netBalanceKwh,
                          isSurplus: balance.isSurplus,
                          currency: currency,
                          effectiveRate: effectiveRate,
                          onNavigateSolar: () => widget.onNavigateTab(3),
                          onNavigateAppliances: () => widget.onNavigateTab(1),
                        ),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Compact Auto-Discovery Banner (Clean Slate)
              if (summary.applianceResults.isEmpty) ...[
                SmoothEntrance(
                  delayMs: 40,
                  child: _buildAutoDetectBanner(context),
                ),
                const SizedBox(height: 14),
              ],

              // 3. Ergonomic Minimal Quick Action Dock
              SmoothEntrance(
                delayMs: 80,
                child: _buildQuickActions(context),
              ),
              const SizedBox(height: 14),

              // 4. Clean 2-Card Metrics Row
              SmoothEntrance(
                delayMs: 120,
                child: _buildPrimaryMetrics(context, summary, balance, currency),
              ),
              const SizedBox(height: 14),

              // 4b. Standby / Vampire Load Disaggregation Card
              if (summary.standbySummary.totalStandbyWatts > 0) ...[
                SmoothEntrance(
                  delayMs: 140,
                  child: VampireLoadCard(
                    summary: summary.standbySummary,
                    currency: currency,
                    effectiveRate: effectiveRate,
                    onInspectOffenders: () => widget.onNavigateTab(1),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 5. Minimalist Top Consuming Appliances
              SmoothEntrance(
                delayMs: 160,
                child: _buildTopAppliances(context, summary, energy, currency),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroTabItem(int index, String label, IconData icon) {
    final isSelected = _heroViewIndex == index;
    return GestureDetector(
      onTap: () {
        if (_heroViewIndex != index) {
          NativeChannel.triggerHaptic();
          setState(() => _heroViewIndex = index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.emeraldPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.style(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // AUTO-DETECT DISCOVERY BANNER (Clean & Compact)
  // -------------------------------------------------------------
  Widget _buildAutoDetectBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.emeraldPrimary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.radar_rounded, color: AppTheme.emeraldPrimary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Auto-Detect Appliances',
                  style: AppTypography.style(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  'Scan smart plugs & meters via Wi-Fi + BLE',
                  style: AppTypography.style(fontSize: 10.5, color: AppTheme.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              NativeChannel.triggerHaptic();
              AutoDetectDialog.show(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.emeraldPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Scan'),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // QUICK ACTIONS DOCK
  // -------------------------------------------------------------
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionItem(
            icon: Icons.add_rounded,
            label: 'Add',
            color: AppTheme.emeraldPrimary,
            isPrimary: true,
            onTap: () => widget.onNavigateTab(1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionItem(
            icon: Icons.radar_rounded,
            label: 'Scan',
            color: AppTheme.electricCyan,
            onTap: () => AutoDetectDialog.show(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionItem(
            icon: Icons.wb_sunny_rounded,
            label: 'Solar',
            color: AppTheme.solarGold,
            onTap: () => widget.onNavigateTab(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionItem(
            icon: Icons.tune_rounded,
            label: 'Tariff',
            color: AppTheme.textDark,
            onTap: () => widget.onNavigateTab(2),
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: () {
        NativeChannel.triggerHaptic();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? color : AppTheme.borderSubtle,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isPrimary ? Colors.white : color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.style(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isPrimary ? Colors.white : AppTheme.textDark,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // PRIMARY METRIC TILES (Estimated Bill & Solar Coverage)
  // -------------------------------------------------------------
  Widget _buildPrimaryMetrics(
    BuildContext context,
    HouseholdConsumptionSummary summary,
    NetEnergyBalance balance,
    String currency,
  ) {
    return Row(
      children: [
        // Card 1: Estimated Bill
        Expanded(
          child: _buildMetricTile(
            title: 'ESTIMATED BILL',
            value: Formatters.formatCurrency(balance.solarNetBill, symbol: currency),
            subtitle: balance.isSurplus ? 'Net Zero' : '${summary.totalMonthlyKwh.toStringAsFixed(0)} u used',
            badgeColor: balance.isSurplus ? AppTheme.emeraldPrimary : AppTheme.warmAmber,
            icon: Icons.receipt_long_rounded,
            onTap: () => widget.onNavigateTab(2),
          ),
        ),
        const SizedBox(width: 10),
        // Card 2: Solar Coverage
        Expanded(
          child: _buildMetricTile(
            title: 'SOLAR COVERAGE',
            value: '${balance.offsetPercentage.toStringAsFixed(0)}%',
            subtitle: balance.isSurplus ? '100% Self-Powered' : '${balance.solarMonthlyKwh.toStringAsFixed(0)} u generated',
            badgeColor: AppTheme.solarGold,
            icon: Icons.solar_power_rounded,
            onTap: () => widget.onNavigateTab(3),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required Color badgeColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
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
                    Text(
                      title,
                      style: AppTypography.style(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Icon(icon, size: 16, color: badgeColor),
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
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.style(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
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
  // TOP APPLIANCES SPOTLIGHT
  // -------------------------------------------------------------
  Widget _buildTopAppliances(
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
                  widget.onNavigateTab(1);
                },
                child: Text(
                  summary.applianceResults.isEmpty ? '' : 'View All',
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
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  children: [
                    const Icon(Icons.devices_other_rounded, size: 26, color: AppTheme.textSubtle),
                    const SizedBox(height: 6),
                    Text(
                      'No appliances added yet',
                      style: AppTypography.style(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () {
                        NativeChannel.triggerHaptic();
                        widget.onNavigateTab(1);
                      },
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
                padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      // Simple numeric rank
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: rank == 1 ? AppTheme.warmAmber : AppTheme.surfaceMuted,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$rank',
                            style: AppTypography.style(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: rank == 1 ? Colors.white : AppTheme.textDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Appliance name & wattage
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
                            Text(
                              '${app.appliance.wattage.toStringAsFixed(0)}W • ${app.appliance.hoursPerDay.toStringAsFixed(1)}h/d',
                              style: AppTypography.style(
                                fontSize: 10.5,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Consumption units & cost
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${app.monthlyKwh.toStringAsFixed(0)} kWh',
                            style: AppTypography.style(
                              fontSize: 12.5,
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
                              fontSize: 10,
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
}
