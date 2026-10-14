import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/native/native_channel.dart';

class FloatingOnboardingCard extends StatefulWidget {
  final VoidCallback onDismiss;
  final VoidCallback onAddAppliance;

  const FloatingOnboardingCard({
    super.key,
    required this.onDismiss,
    required this.onAddAppliance,
  });

  @override
  State<FloatingOnboardingCard> createState() => _FloatingOnboardingCardState();
}

class _FloatingOnboardingCardState extends State<FloatingOnboardingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _dismiss(VoidCallback action) async {
    NativeChannel.triggerHaptic();
    await _animController.reverse();
    action();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // Subtle touch backdrop
          GestureDetector(
            onTap: () => _dismiss(widget.onDismiss),
            child: Container(
              color: Colors.black.withValues(alpha: 0.38),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: AppTheme.borderSubtle, width: 1.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Badge & Close Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.emeraldPrimary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bolt, size: 13, color: AppTheme.emeraldPrimary),
                                const SizedBox(width: 4),
                                Text(
                                  'WELCOME TO UNITWISE',
                                  style: AppTypography.style(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.emeraldPrimary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => _dismiss(widget.onDismiss),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.surfaceMuted,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 15, color: AppTheme.textMuted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Heading
                      Text(
                        'Your Clean Slate',
                        style: AppTypography.style(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'All pre-seeded data has been removed. Add your appliances below to compute electricity bills and solar savings.',
                        style: AppTypography.style(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Feature Walkthrough
                      _buildStepRow(
                        icon: Icons.devices_outlined,
                        iconColor: AppTheme.emeraldPrimary,
                        bgColor: AppTheme.emeraldPrimary.withValues(alpha: 0.10),
                        title: '1. Add Household Appliances',
                        desc: 'Pick fans, ACs, fridge, lighting, or custom wattage ratings.',
                      ),
                      const SizedBox(height: 8),
                      _buildStepRow(
                        icon: Icons.receipt_long_outlined,
                        iconColor: const Color(0xFF2563EB),
                        bgColor: const Color(0xFF2563EB).withValues(alpha: 0.10),
                        title: '2. Bill & Tiered Slabs',
                        desc: 'Accurate tiered tariffs, fixed charges, and net taxes.',
                      ),
                      const SizedBox(height: 8),
                      _buildStepRow(
                        icon: Icons.solar_power_outlined,
                        iconColor: const Color(0xFFD97706),
                        bgColor: const Color(0xFFD97706).withValues(alpha: 0.10),
                        title: '3. Solar Net Balance',
                        desc: 'Measure real-time solar generation vs household load.',
                      ),
                      const SizedBox(height: 14),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _dismiss(widget.onDismiss),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textDark,
                                side: const BorderSide(color: AppTheme.borderSubtle),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Explore',
                                style: AppTypography.style(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () => _dismiss(widget.onAddAppliance),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.emeraldPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_rounded, size: 17),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Add Appliance',
                                      style: AppTypography.style(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.style(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppTypography.style(
                  fontSize: 11.5,
                  color: AppTheme.textMuted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
