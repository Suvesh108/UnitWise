import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import 'package:provider/provider.dart';
import '../../providers/energy_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/native/native_channel.dart';
import '../dashboard/dashboard_screen.dart';
import '../appliances/appliances_screen.dart';
import '../bill/bill_screen.dart';
import '../solar/solar_screen.dart';
import '../reports/reports_screen.dart';
import '../widgets/floating_onboarding_card.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    NativeChannel.triggerHaptic();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final energy = context.watch<EnergyProvider>();
    final settings = context.watch<SettingsProvider>();

    final screens = [
      DashboardScreen(onNavigateTab: _navigateToTab),
      const AppliancesScreen(),
      const BillScreen(),
      const SolarScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: _currentIndex == 0
          ? AppBar(
              backgroundColor: AppTheme.backgroundLight,
              title: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 34,
                      height: 34,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldPrimary,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Center(
                          child: Icon(Icons.bolt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: TextSpan(
                      text: 'Unit',
                      style: AppTypography.style(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                        letterSpacing: -0.6,
                      ),
                      children: [
                        TextSpan(
                          text: 'Wise',
                          style: AppTypography.style(
                            color: AppTheme.emeraldPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                // Minimalist Household Chip Selector
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: PopupMenuButton<String>(
                    tooltip: 'Switch Household',
                    initialValue: energy.activeHouseholdId,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppTheme.emeraldPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 85),
                            child: Text(
                              energy.activeHousehold.name,
                              style: AppTypography.style(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.textMuted),
                        ],
                      ),
                    ),
                    itemBuilder: (ctx) => energy.households.map((h) {
                      final isSelected = h.id == energy.activeHouseholdId;
                      return PopupMenuItem<String>(
                        value: h.id,
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle : Icons.circle_outlined,
                              size: 16,
                              color: isSelected ? AppTheme.emeraldPrimary : AppTheme.textSubtle,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              h.name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onSelected: (id) {
                      NativeChannel.triggerHaptic();
                      energy.switchHousehold(id);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Reports & Preferences',
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: const Icon(Icons.tune_outlined, size: 17, color: AppTheme.textDark),
                  ),
                  onPressed: () {
                    NativeChannel.triggerHaptic();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportsScreen()),
                    );
                  },
                ),
                const SizedBox(width: 12),
              ],
            )
          : null,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          if (!settings.hasCompletedOnboarding)
            FloatingOnboardingCard(
              onDismiss: () => settings.completeOnboarding(),
              onAddAppliance: () {
                settings.completeOnboarding();
                _navigateToTab(1);
              },
            ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 74 + MediaQuery.of(context).padding.bottom,
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppTheme.borderSubtle, width: 1.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(child: _buildNavItem(0, Icons.grid_view_outlined, Icons.grid_view_rounded, 'Dashboard')),
                Expanded(child: _buildNavItem(1, Icons.devices_outlined, Icons.devices_rounded, 'Appliances')),
                Expanded(child: _buildNavItem(2, Icons.receipt_outlined, Icons.receipt_long_rounded, 'Bill')),
                Expanded(child: _buildNavItem(3, Icons.wb_sunny_outlined, Icons.wb_sunny_rounded, 'Solar')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData unselectedIcon, IconData selectedIcon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => _navigateToTab(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.emeraldPrimary.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                size: 22,
                color: isSelected ? AppTheme.emeraldPrimary : AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.style(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppTheme.emeraldPrimary : AppTheme.textMuted,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
