import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/native/native_channel.dart';
import '../../../domain/energy_calculator.dart';
import '../../../core/utils/formatters.dart';

class EnergyDonutChart extends StatefulWidget {
  final double solarKwh;
  final double loadKwh;
  final double netKwh;
  final bool isSurplus;
  final List<CategoryConsumptionResult> categoryResults;
  final String currency;
  final VoidCallback? onNavigateSolar;
  final VoidCallback? onNavigateAppliances;

  const EnergyDonutChart({
    super.key,
    required this.solarKwh,
    required this.loadKwh,
    required this.netKwh,
    required this.isSurplus,
    required this.categoryResults,
    required this.currency,
    this.onNavigateSolar,
    this.onNavigateAppliances,
  });

  @override
  State<EnergyDonutChart> createState() => _EnergyDonutChartState();
}

class _EnergyDonutChartState extends State<EnergyDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  bool _showCategories = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant EnergyDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.solarKwh != widget.solarKwh ||
        oldWidget.loadKwh != widget.loadKwh ||
        oldWidget.categoryResults.length != widget.categoryResults.length) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleMode(bool categories) {
    if (_showCategories == categories) return;
    NativeChannel.triggerHaptic();
    setState(() => _showCategories = categories);
    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final hasData = widget.solarKwh > 0 || widget.loadKwh > 0;
    final accentColor = widget.isSurplus ? AppTheme.emeraldPrimary : AppTheme.warmAmber;

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
          // Header: Title & Minimalist Mode Switcher
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
              // Segmented Pill: Flow vs Devices
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeButton(
                      label: 'Flow',
                      isSelected: !_showCategories,
                      onTap: () => _toggleMode(false),
                    ),
                    _buildModeButton(
                      label: 'Devices',
                      isSelected: _showCategories,
                      onTap: () => _toggleMode(true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Central Donut Graph with Middle Metric Hole
          Center(
            child: SizedBox(
              width: 190,
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(190, 190),
                        painter: _DonutChartPainter(
                          progress: _animation.value,
                          showCategories: _showCategories,
                          solarKwh: widget.solarKwh,
                          loadKwh: widget.loadKwh,
                          isSurplus: widget.isSurplus,
                          categoryResults: widget.categoryResults,
                        ),
                      );
                    },
                  ),
                  // Center Metric in the Hole
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          !hasData
                              ? '0'
                              : _showCategories
                                  ? widget.loadKwh.toStringAsFixed(0)
                                  : '${widget.isSurplus ? '+' : ''}${widget.netKwh.toStringAsFixed(0)}',
                          style: AppTypography.style(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: !hasData
                                ? AppTheme.textDark
                                : (_showCategories
                                    ? AppTheme.textDark
                                    : (widget.isSurplus
                                        ? AppTheme.emeraldPrimary
                                        : AppTheme.textDark)),
                            letterSpacing: -1.0,
                          ),
                        ),
                      ),
                      Text(
                        _showCategories ? 'kWh total' : 'kWh / mo',
                        style: AppTypography.style(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: !hasData
                              ? AppTheme.surfaceMuted
                              : (_showCategories
                                  ? AppTheme.electricCyan.withValues(alpha: 0.1)
                                  : (widget.isSurplus
                                      ? AppTheme.emeraldPrimary.withValues(alpha: 0.1)
                                      : AppTheme.warmAmber.withValues(alpha: 0.1))),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          !hasData
                              ? 'STANDBY'
                              : _showCategories
                                  ? '${widget.categoryResults.length} CATEGORIES'
                                  : (widget.isSurplus ? 'SURPLUS' : 'GRID DEMAND'),
                          style: AppTypography.style(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: !hasData
                                ? AppTheme.textMuted
                                : (_showCategories
                                    ? AppTheme.electricCyan
                                    : (widget.isSurplus
                                        ? AppTheme.emeraldPrimary
                                        : AppTheme.warmAmber)),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bottom Legend Pills
          if (!_showCategories) ...[
            Row(
              children: [
                Expanded(
                  child: _buildLegendChip(
                    icon: Icons.wb_sunny_rounded,
                    label: 'Solar',
                    value: '+${widget.solarKwh.toStringAsFixed(0)}',
                    color: AppTheme.solarGold,
                    onTap: widget.onNavigateSolar,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildLegendChip(
                    icon: Icons.power_rounded,
                    label: 'Load',
                    value: '−${widget.loadKwh.toStringAsFixed(0)}',
                    color: AppTheme.electricCyan,
                    onTap: widget.onNavigateAppliances,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildLegendChip(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Bill',
                    value: widget.isSurplus
                        ? '₹0'
                        : Formatters.formatCurrency(
                            widget.netKwh.abs() * 7.5,
                            symbol: widget.currency,
                          ),
                    color: widget.isSurplus ? AppTheme.emeraldPrimary : AppTheme.alertCoral,
                    onTap: widget.onNavigateSolar,
                  ),
                ),
              ],
            ),
          ] else ...[
            if (widget.categoryResults.isEmpty) ...[
              Center(
                child: Text(
                  'No active appliance categories',
                  style: AppTypography.style(fontSize: 11, color: AppTheme.textMuted),
                ),
              ),
            ] else ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: widget.categoryResults.take(4).map((cat) {
                  final col = _getCategoryColor(cat.category);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: col.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
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
                          '${Formatters.getCategoryName(cat.category)} ${cat.percentageOfTotal.toStringAsFixed(0)}%',
                          style: AppTypography.style(
                            fontSize: 10,
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
          ],
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.style(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppTheme.textDark : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          NativeChannel.triggerHaptic();
          onTap();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 11, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.style(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: AppTypography.style(
                  fontSize: 12.5,
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

  static Color _getCategoryColor(dynamic category) {
    final name = category.toString().toLowerCase();
    if (name.contains('cooling')) return const Color(0xFF0F766E);
    if (name.contains('kitchen')) return const Color(0xFFD97706);
    if (name.contains('lighting')) return const Color(0xFF0284C7);
    if (name.contains('entertainment') || name.contains('tech')) return const Color(0xFF8B5CF6);
    if (name.contains('water') || name.contains('pump')) return const Color(0xFF06B6D4);
    return const Color(0xFF64748B);
  }
}

// -------------------------------------------------------------
// DONUT CHART CUSTOM PAINTER
// -------------------------------------------------------------
class _DonutChartPainter extends CustomPainter {
  final double progress;
  final bool showCategories;
  final double solarKwh;
  final double loadKwh;
  final bool isSurplus;
  final List<CategoryConsumptionResult> categoryResults;

  _DonutChartPainter({
    required this.progress,
    required this.showCategories,
    required this.solarKwh,
    required this.loadKwh,
    required this.isSurplus,
    required this.categoryResults,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 18.0;

    // 1. Background Ring Track
    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2; // Start from top 12 o'clock

    if (showCategories) {
      _paintCategories(canvas, rect, startAngle, strokeWidth);
    } else {
      _paintFlow(canvas, rect, startAngle, strokeWidth);
    }
  }

  void _paintFlow(Canvas canvas, Rect rect, double startAngle, double strokeWidth) {
    final total = solarKwh + loadKwh;
    if (total <= 0) return;

    final solarFrac = (solarKwh / total).clamp(0.0, 1.0);
    final loadFrac = (loadKwh / total).clamp(0.0, 1.0);

    const gap = 0.06; // gap in radians
    final effectiveProgress = progress.clamp(0.0, 1.0);

    if (solarKwh > 0 && loadKwh > 0) {
      final solarSweep = (2 * math.pi * solarFrac - gap) * effectiveProgress;
      final loadSweep = (2 * math.pi * loadFrac - gap) * effectiveProgress;

      final solarPaint = Paint()
        ..color = AppTheme.solarGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle + gap / 2, solarSweep, false, solarPaint);

      final loadPaint = Paint()
        ..color = AppTheme.electricCyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final loadStart = startAngle + (2 * math.pi * solarFrac) + gap / 2;
      canvas.drawArc(rect, loadStart, loadSweep, false, loadPaint);
    } else if (solarKwh > 0) {
      final sweep = (2 * math.pi * effectiveProgress);
      final solarPaint = Paint()
        ..color = AppTheme.solarGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweep, false, solarPaint);
    } else if (loadKwh > 0) {
      final sweep = (2 * math.pi * effectiveProgress);
      final loadPaint = Paint()
        ..color = AppTheme.electricCyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweep, false, loadPaint);
    }
  }

  void _paintCategories(Canvas canvas, Rect rect, double startAngle, double strokeWidth) {
    if (categoryResults.isEmpty) return;

    const gap = 0.05;
    double currentAngle = startAngle;
    final effectiveProgress = progress.clamp(0.0, 1.0);

    for (final cat in categoryResults) {
      final frac = (cat.percentageOfTotal / 100.0).clamp(0.02, 1.0);
      final sweep = (2 * math.pi * frac - gap) * effectiveProgress;
      if (sweep <= 0) continue;

      final paint = Paint()
        ..color = _EnergyDonutChartState._getCategoryColor(cat.category)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, currentAngle + gap / 2, sweep, false, paint);
      currentAngle += (2 * math.pi * frac);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.showCategories != showCategories ||
        oldDelegate.solarKwh != solarKwh ||
        oldDelegate.loadKwh != loadKwh ||
        oldDelegate.isSurplus != isSurplus ||
        oldDelegate.categoryResults.length != categoryResults.length;
  }
}
