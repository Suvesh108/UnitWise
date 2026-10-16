import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_typography.dart';
import 'package:provider/provider.dart';
import '../../providers/energy_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/native/native_channel.dart';
import 'pdf_preview_dialog.dart';
import 'app_update_dialog.dart';
import '../../core/constants/app_constants.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController _newHouseholdNameController = TextEditingController();
  final TextEditingController _newHouseholdLocationController = TextEditingController();
  bool _isCheckingUpdate = false;

  @override
  void dispose() {
    _newHouseholdNameController.dispose();
    _newHouseholdLocationController.dispose();
    super.dispose();
  }

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

  void _showAddHouseholdDialog(BuildContext context) {
    _newHouseholdNameController.clear();
    _newHouseholdLocationController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Add Household Profile',
          style: AppTypography.style(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newHouseholdNameController,
              decoration: const InputDecoration(labelText: 'Profile Name', hintText: 'e.g. Vacation Villa / Parents Flat'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newHouseholdLocationController,
              decoration: const InputDecoration(labelText: 'Location / City', hintText: 'e.g. Pune, Maharashtra'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final name = _newHouseholdNameController.text.trim();
              final loc = _newHouseholdLocationController.text.trim();
              if (name.isNotEmpty) {
                NativeChannel.triggerHaptic();
                await context.read<EnergyProvider>().createHousehold(
                  name,
                  loc.isEmpty ? 'Default Location' : loc,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Create Profile'),
          ),
        ],
      ),
    );
  }

  void _showImportJsonDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Import Backup JSON',
          style: AppTypography.style(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Paste UnitWise JSON backup content here...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final ok = await context.read<EnergyProvider>().importJson(controller.text.trim());
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Backup imported successfully!' : 'Invalid JSON backup format'),
                      backgroundColor: ok ? AppTheme.emeraldPrimary : AppTheme.alertCoral,
                    ),
                  );
                }
              }
            },
            child: const Text('Import'),
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
    final devStats = settings.deviceStats;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        title: Text(
          'Reports & Preferences',
          style: AppTypography.style(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PDF Audit Report Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.emeraldPrimary.withValues(alpha: 0.3), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.emeraldPrimary.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(Icons.picture_as_pdf_outlined, color: AppTheme.emeraldPrimary, size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Full Audit PDF',
                          style: AppTypography.style(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Generate shareable PDF report with solar feasibility specs.',
                          style: AppTypography.style(
                            fontSize: 11.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      NativeChannel.triggerHaptic();
                      PdfPreviewDialog.show(context);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Generate'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Household Profiles Manager
            Container(
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
                        'HOUSEHOLD PROFILES',
                        style: AppTypography.style(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Profile'),
                        onPressed: () => _showAddHouseholdDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...energy.households.map((h) {
                    final isSelected = h.id == activeH.id;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFBBF7D0) : AppTheme.borderSubtle,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.home_outlined,
                            size: 20,
                            color: isSelected ? AppTheme.emeraldPrimary : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  h.name,
                                  style: AppTypography.style(
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 13.5,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                Text(
                                  '${h.location} • ${h.daysInMonth} days/cycle',
                                  style: AppTypography.style(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.emeraldPrimary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Active',
                                style: AppTypography.style(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          else
                            OutlinedButton(
                              onPressed: () {
                                NativeChannel.triggerHaptic();
                                energy.switchHousehold(h.id);
                              },
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                              child: const Text('Switch'),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Billing Days in Month',
                        style: AppTypography.style(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      DropdownButton<int>(
                        value: activeH.daysInMonth,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 28, child: Text('28 Days (Feb)')),
                          DropdownMenuItem(value: 29, child: Text('29 Days (Leap Feb)')),
                          DropdownMenuItem(value: 30, child: Text('30 Days (Standard)')),
                          DropdownMenuItem(value: 31, child: Text('31 Days (Full Month)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            energy.updateActiveHousehold(activeH.copyWith(daysInMonth: val));
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Regional & Currency Settings
            Container(
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
                      letterSpacing: 1.0,
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
            const SizedBox(height: 16),

            // Native Android Bridge Diagnostics
            Container(
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
                    children: [
                      const Icon(Icons.android, color: AppTheme.emeraldPrimary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'NATIVE KOTLIN BRIDGE',
                        style: AppTypography.style(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDiagRow('Device Model', devStats['deviceModel']?.toString() ?? 'Android Hardware'),
                  _buildDiagRow('Android Version', devStats['androidVersion']?.toString() ?? 'Android 14'),
                  _buildDiagRow(
                    'Battery Capacity',
                    '${devStats['batteryLevel'] ?? 85}% (${devStats['isCharging'] == true ? 'Charging' : 'On Battery'})',
                  ),
                  _buildDiagRow('Offline Storage', 'Key-Value SharedPreferences & Room Entity Schema'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Backup Portability
            Container(
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
                    'DATA BACKUP & RESTORE',
                    style: AppTypography.style(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.copy_outlined, size: 16),
                          label: const Text('Export JSON'),
                          onPressed: () {
                            NativeChannel.triggerHaptic();
                            final json = energy.exportJson();
                            Clipboard.setData(ClipboardData(text: json));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Backup JSON copied to clipboard!')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.file_upload_outlined, size: 16),
                          label: const Text('Import JSON'),
                          onPressed: () => _showImportJsonDialog(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // In-App Software Updates (Internal Kotlin OTA)
            Container(
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
                            'IN-APP SOFTWARE UPDATES',
                            style: AppTypography.style(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textMuted,
                              letterSpacing: 1.0,
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
                    'Direct in-app package updates via Kotlin platform engine. Downloads and installs internally without launching Chrome or external web browser.',
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
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isCheckingUpdate ? null : _handleCheckForUpdate,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Clean Slate & Factory Management
            Container(
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
                    children: [
                      const Icon(Icons.cleaning_services_outlined, color: AppTheme.alertCoral, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'CLEAN SLATE & ONBOARDING',
                        style: AppTypography.style(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Reset your data to an empty clean slate or re-open the initial floating onboarding card anytime.',
                    style: AppTypography.style(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.info_outline, size: 16),
                          label: const Text('View Guide'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.borderSubtle),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () async {
                            NativeChannel.triggerHaptic();
                            await settings.resetOnboarding();
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.alertCoral),
                          label: Text(
                            'Reset Data',
                            style: AppTypography.style(color: AppTheme.alertCoral, fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppTheme.alertCoral.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => _showClearAllDataConfirmation(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // App Branding & Version Footer
            Center(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 52,
                      height: 52,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.bolt, color: AppTheme.emeraldPrimary, size: 40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'UnitWise',
                    style: AppTypography.style(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Home Electricity & Rooftop Solar Sizing • v${AppConstants.appVersion}',
                    style: AppTypography.style(fontSize: 11.5, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.style(fontSize: 12, color: AppTheme.textMuted)),
          Text(value, style: AppTypography.style(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
        ],
      ),
    );
  }
}
