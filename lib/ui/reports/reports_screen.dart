import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import 'package:provider/provider.dart';
import '../../providers/energy_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/native/native_channel.dart';
import 'app_update_dialog.dart';
import '../../core/constants/app_constants.dart';
import '../properties/property_switcher_sheet.dart';
import '../widgets/smooth_entrance.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isCheckingUpdate = false;

  Future<void> _handleCheckForUpdate() async {
    NativeChannel.triggerHaptic();
    setState(() => _isCheckingUpdate = true);
    try {
      final info = await NativeChannel.checkForUpdate();
      if (!mounted) return;
      setState(() => _isCheckingUpdate = false);

      if (info.hasUpdate) {
        showDialog(
          context: context,
          builder: (_) => AppUpdateDialog(updateInfo: info),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('UnitWise is up to date (v${info.currentVersion})'),
            backgroundColor: AppTheme.emeraldPrimary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingUpdate = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to check for updates: $e'),
          backgroundColor: AppTheme.alertCoral,
        ),
      );
    }
  }

  void _showClearAllDataConfirmation(BuildContext context) {
    NativeChannel.triggerHaptic();
    final energy = context.read<EnergyProvider>();
    final settings = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Reset to Clean Slate?',
          style: AppTypography.style(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Text(
          'This will remove all appliances and custom solar inputs so you can enter your fresh household data from scratch.',
          style: AppTypography.style(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.alertCoral),
            onPressed: () async {
              NativeChannel.triggerHaptic();
              await energy.clearAllData();
              await settings.resetOnboarding();
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('All data cleared. Welcome to your clean slate!'),
                  backgroundColor: AppTheme.emeraldPrimary,
                ),
              );
            },
            child: const Text('Reset All Data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final energy = context.watch<EnergyProvider>();
    final settings = context.watch<SettingsProvider>();
    final activeH = energy.activeHousehold;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        title: Text(
          'Settings',
          style: AppTypography.style(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Property Management Card
            SmoothEntrance(
              delayMs: 0,
              child: Container(
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
                        Text(
                          'ACTIVE PROPERTY',
                          style: AppTypography.style(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        TextButton(
                          onPressed: () => PropertySwitcherSheet.show(context),
                          child: const Text('Switch / Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: activeH.propertyType.color.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: activeH.propertyType.color.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(activeH.propertyType.icon, color: activeH.propertyType.color, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeH.name,
                                  style: AppTypography.style(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                Text(
                                  '${activeH.propertyType.displayName} • ${activeH.daysInMonth} billing days',
                                  style: AppTypography.style(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ],
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

            // 2. Currency & Regional Display
            SmoothEntrance(
              delayMs: 60,
              child: Container(
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
                      'CURRENCY & DISPLAY',
                      style: AppTypography.style(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Currency Symbol',
                          style: AppTypography.style(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        DropdownButton<String>(
                          value: settings.currency,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: '₹', child: Text('₹ (INR - Rupee)')),
                            DropdownMenuItem(value: '\$', child: Text('\$ (USD / AUD)')),
                            DropdownMenuItem(value: '€', child: Text('€ (EUR - Euro)')),
                            DropdownMenuItem(value: '£', child: Text('£ (GBP - Pound)')),
                            DropdownMenuItem(value: 'AED ', child: Text('AED (Dirham)')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              NativeChannel.triggerHaptic();
                              settings.setCurrency(v);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 3. In-App Software Updates (Live GitHub OTA)
            SmoothEntrance(
              delayMs: 120,
              child: Container(
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
                            const Icon(Icons.system_update_rounded, color: AppTheme.emeraldPrimary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'SOFTWARE UPDATE',
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.emeraldPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'v${AppConstants.appVersion}',
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
                    Text(
                      'Live in-app package updates via GitHub REST API. Downloads and updates internally without launching external web browsers.',
                      style: AppTypography.style(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isCheckingUpdate
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(_isCheckingUpdate ? 'Checking for updates...' : 'Check for Updates'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emeraldPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isCheckingUpdate ? null : _handleCheckForUpdate,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 4. Data Management & Reset
            SmoothEntrance(
              delayMs: 180,
              child: Container(
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
                      'DATA MANAGEMENT',
                      style: AppTypography.style(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Purge all local appliance data and custom solar measurements to start fresh.',
                      style: AppTypography.style(fontSize: 12, color: AppTheme.textMuted, height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.restart_alt_rounded, size: 16, color: AppTheme.alertCoral),
                      label: Text(
                        'Reset to Clean Slate',
                        style: AppTypography.style(color: AppTheme.alertCoral, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFECDD3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () => _showClearAllDataConfirmation(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
