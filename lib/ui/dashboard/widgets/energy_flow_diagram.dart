import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/native/native_channel.dart';

class EnergyFlowDiagram extends StatefulWidget {
  final double solarKwh;
  final double loadKwh;
  final double netKwh;
  final bool isSurplus;
  final String currency;
  final double? effectiveRate;
  final VoidCallback? onNavigateSolar;
  final VoidCallback? onNavigateAppliances;
  final VoidCallback? onNavigateBill;

  const EnergyFlowDiagram({
    super.key,
    required this.solarKwh,
    required this.loadKwh,
    required this.netKwh,
    required this.isSurplus,
    required this.currency,
    this.effectiveRate,
    this.onNavigateSolar,
    this.onNavigateAppliances,
    this.onNavigateBill,
  });

  @override
  State<EnergyFlowDiagram> createState() => _EnergyFlowDiagramState();
}

class _EnergyFlowDiagramState extends State<EnergyFlowDiagram>
    with SingleTickerProviderStateMixin {
  late AnimationController _flowController;

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _flowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSolar = widget.solarKwh > 0;
    final hasLoad = widget.loadKwh > 0;
    final isExporting = widget.isSurplus && widget.netKwh > 0;
    final isImporting = !widget.isSurplus && widget.netKwh < 0;

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
          // Header Row with Live Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: hasSolar || hasLoad ? AppTheme.emeraldPrimary : AppTheme.textSubtle,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE ENERGY FLOW',
                    style: AppTypography.style(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: (widget.isSurplus ? AppTheme.emeraldPrimary : AppTheme.warmAmber).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.isSurplus ? '⚡ 100% Self-Sufficient' : '🔌 Grid Supplemental',
                  style: AppTypography.style(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: widget.isSurplus ? AppTheme.emeraldPrimary : AppTheme.warmAmber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Energy Flow Topology Layout
          SizedBox(
            height: 190,
            child: AnimatedBuilder(
              animation: _flowController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _EnergyFlowPainter(
                    progress: _flowController.value,
                    hasSolar: hasSolar,
                    hasLoad: hasLoad,
                    isExporting: isExporting,
                    isImporting: isImporting,
                  ),
                  child: Stack(
                    children: [
                      // Node 1: Solar (Top Left)
                      Align(
                        alignment: const Alignment(-0.85, -0.9),
                        child: _buildFlowNode(
                          icon: Icons.wb_sunny_rounded,
                          title: 'Solar Yield',
                          value: '${widget.solarKwh.toStringAsFixed(0)} u',
                          color: AppTheme.solarGold,
                          onTap: widget.onNavigateSolar,
                        ),
                      ),

                      // Node 2: Discom Grid (Top Right)
                      Align(
                        alignment: const Alignment(0.85, -0.9),
                        child: _buildFlowNode(
                          icon: isExporting ? Icons.upload_rounded : Icons.electric_meter_rounded,
                          title: isExporting ? 'Grid Credit' : 'Grid Import',
                          value: '${widget.netKwh.abs().toStringAsFixed(0)} u',
                          color: isExporting ? AppTheme.emeraldPrimary : AppTheme.electricCyan,
                          onTap: widget.onNavigateBill,
                        ),
                      ),

                      // Central Bus: Smart Inverter / Net Meter Hub
                      Align(
                        alignment: const Alignment(0.0, -0.05),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.isSurplus ? AppTheme.emeraldPrimary : AppTheme.electricCyan,
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (widget.isSurplus ? AppTheme.emeraldPrimary : AppTheme.electricCyan).withValues(alpha: 0.15),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.sync_alt_rounded,
                              size: 20,
                              color: widget.isSurplus ? AppTheme.emeraldPrimary : AppTheme.electricCyan,
                            ),
                          ),
                        ),
                      ),

                      // Node 3: Home Consumption (Bottom Center)
                      Align(
                        alignment: const Alignment(0.0, 0.95),
                        child: _buildFlowNode(
                          icon: Icons.home_rounded,
                          title: 'Home Demand',
                          value: '${widget.loadKwh.toStringAsFixed(0)} u',
                          color: AppTheme.textDark,
                          onTap: widget.onNavigateAppliances,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Bottom Flow Telemetry Summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryCol(
                  label: 'Solar Generated',
                  value: '${widget.solarKwh.toStringAsFixed(0)} kWh',
                  color: AppTheme.solarGold,
                ),
                Container(width: 1, height: 26, color: AppTheme.borderSubtle),
                _buildSummaryCol(
                  label: 'Home Used',
                  value: '${widget.loadKwh.toStringAsFixed(0)} kWh',
                  color: AppTheme.textDark,
                ),
                Container(width: 1, height: 26, color: AppTheme.borderSubtle),
                _buildSummaryCol(
                  label: isExporting ? 'Net Feed-in' : 'Grid Balance',
                  value: isExporting
                      ? '+${widget.netKwh.toStringAsFixed(0)} kWh'
                      : '-${widget.netKwh.abs().toStringAsFixed(0)} kWh',
                  color: isExporting ? AppTheme.emeraldPrimary : AppTheme.alertCoral,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCol({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTypography.style(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: AppTypography.style(fontSize: 13, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }

  Widget _buildFlowNode({
    required IconData icon,
    required String title,
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSubtle, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.style(fontSize: 9.5, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                ),
                Text(
                  value,
                  style: AppTypography.style(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EnergyFlowPainter extends CustomPainter {
  final double progress;
  final bool hasSolar;
  final bool hasLoad;
  final bool isExporting;
  final bool isImporting;

  _EnergyFlowPainter({
    required this.progress,
    required this.hasSolar,
    required this.hasLoad,
    required this.isExporting,
    required this.isImporting,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 5);
    final solarPos = Offset(size.width * 0.22, size.height * 0.18);
    final gridPos = Offset(size.width * 0.78, size.height * 0.18);
    final homePos = Offset(size.width / 2, size.height * 0.78);

    final trackPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw baseline tracks
    final solarPath = Path()
      ..moveTo(solarPos.dx, solarPos.dy)
      ..quadraticBezierTo(size.width * 0.32, center.dy, center.dx, center.dy);
    canvas.drawPath(solarPath, trackPaint);

    final gridPath = Path()
      ..moveTo(gridPos.dx, gridPos.dy)
      ..quadraticBezierTo(size.width * 0.68, center.dy, center.dx, center.dy);
    canvas.drawPath(gridPath, trackPaint);

    final homePath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(homePos.dx, homePos.dy);
    canvas.drawPath(homePath, trackPaint);

    // Draw dynamic animated particles
    if (hasSolar) {
      _drawParticlesOnPath(canvas, solarPath, progress, AppTheme.solarGold, reverse: false);
    }

    if (hasLoad) {
      _drawParticlesOnPath(canvas, homePath, progress, AppTheme.emeraldPrimary, reverse: false);
    }

    if (isExporting) {
      // Flow from Center to Grid
      final exportPath = Path()
        ..moveTo(center.dx, center.dy)
        ..quadraticBezierTo(size.width * 0.68, center.dy, gridPos.dx, gridPos.dy);
      _drawParticlesOnPath(canvas, exportPath, progress, AppTheme.emeraldPrimary, reverse: false);
    } else if (isImporting) {
      // Flow from Grid to Center
      final importPath = Path()
        ..moveTo(gridPos.dx, gridPos.dy)
        ..quadraticBezierTo(size.width * 0.68, center.dy, center.dx, center.dy);
      _drawParticlesOnPath(canvas, importPath, progress, AppTheme.warmAmber, reverse: false);
    }
  }

  void _drawParticlesOnPath(
    Canvas canvas,
    Path path,
    double progress,
    Color color, {
    required bool reverse,
  }) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final pathLen = metric.length;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const particleCount = 4;
    for (int i = 0; i < particleCount; i++) {
      double t = (progress + (i / particleCount)) % 1.0;
      if (reverse) t = 1.0 - t;
      final distance = t * pathLen;
      final tangent = metric.getTangentForOffset(distance);
      if (tangent != null) {
        canvas.drawCircle(tangent.position, 3.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyFlowPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
