import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import 'package:provider/provider.dart';
import '../../providers/energy_provider.dart';
import '../../providers/settings_provider.dart';
import '../../domain/solar_calculator.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/native/native_channel.dart';
import '../widgets/smooth_entrance.dart';

class SolarScreen extends StatefulWidget {
  const SolarScreen({super.key});

  @override
  State<SolarScreen> createState() => _SolarScreenState();
}

class _SolarScreenState extends State<SolarScreen> {
  int _inputMode = 0; // 0 = Daily Units, 1 = Volts x Amps (Inverter), 2 = System kW, 3 = Monthly Units

  late TextEditingController _dailyUnitsController;
  late TextEditingController _voltageController;
  late TextEditingController _currentController;
  late TextEditingController _systemKwController;
  late TextEditingController _monthlyUnitsController;
  late TextEditingController _customLoadController;
  late TextEditingController _exportTariffController;

  bool _useHouseholdLoad = true;

  @override
  void initState() {
    super.initState();
    final energy = context.read<EnergyProvider>();
    final solar = energy.solar;

    final initialMonthly = energy.effectiveSolarMonthlyKwh;
    final initialDaily = initialMonthly / 30.0;
    _dailyUnitsController = TextEditingController(text: initialDaily.toStringAsFixed(1));
    _voltageController = TextEditingController(text: energy.voltageVolts.toStringAsFixed(0));
    _currentController = TextEditingController(text: energy.currentAmps.toStringAsFixed(1));
    _systemKwController = TextEditingController(
      text: (initialDaily / (solar.peakSunHours * solar.performanceRatio)).clamp(0.5, 50.0).toStringAsFixed(1),
    );
    _monthlyUnitsController = TextEditingController(text: initialMonthly.toStringAsFixed(0));
    _customLoadController = TextEditingController(text: energy.consumptionSummary.totalMonthlyKwh.toStringAsFixed(0));
    _exportTariffController = TextEditingController(text: solar.exportTariffPerKwh.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _dailyUnitsController.dispose();
    _voltageController.dispose();
    _currentController.dispose();
    _systemKwController.dispose();
    _monthlyUnitsController.dispose();
    _customLoadController.dispose();
    _exportTariffController.dispose();
    super.dispose();
  }

  void _syncControllersWithMonthly(double monthlyKwh, double peakSunHours, double performanceRatio) {
    final daily = monthlyKwh / 30.0;
    final denominator = peakSunHours * performanceRatio;
    final kw = denominator > 0 ? daily / denominator : 1.0;

    _dailyUnitsController.text = daily.toStringAsFixed(1);
    _monthlyUnitsController.text = monthlyKwh.toStringAsFixed(0);
    _systemKwController.text = kw.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final energy = context.watch<EnergyProvider>();
    final settings = context.watch<SettingsProvider>();
    final solar = energy.solar;
    final balance = energy.netEnergyBalance;
    final currency = settings.currency;
    final summary = energy.consumptionSummary;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        title: Text(
          'Solar',
          style: AppTypography.style(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Outcome Diagnosis Banner
            SmoothEntrance(
              delayMs: 0,
              child: _buildNetOutcomeBanner(context, balance, currency),
            ),
            const SizedBox(height: 16),

            // 3. Solar Generation Input Section (with Volts x Amps, Daily Units, kW)
            SmoothEntrance(
              delayMs: 60,
              child: _buildSolarInputSection(context, energy, solar.peakSunHours, solar.performanceRatio),
            ),
            const SizedBox(height: 16),

            // 4. Household Appliance Load Sync / Custom Load
            SmoothEntrance(
              delayMs: 120,
              child: _buildApplianceLoadSyncSection(context, energy, summary),
            ),
            const SizedBox(height: 16),

            // 5. Before vs After Financial Bento Grid
            SmoothEntrance(
              delayMs: 180,
              child: _buildNetFinancialGrid(context, balance, currency),
            ),
            const SizedBox(height: 16),

            // 6. Itemized Net Metering & Feed-in Audit Table
            SmoothEntrance(
              delayMs: 240,
              child: _buildNetAuditTable(context, energy, solar, balance, currency),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // NET ENERGY BALANCE WIDGETS
  // -------------------------------------------------------------

  Widget _buildNetOutcomeBanner(BuildContext context, NetEnergyBalance balance, String currency) {
    final isEmptyCleanSlate = balance.solarMonthlyKwh == 0 && balance.applianceMonthlyKwh == 0;
    final isSurplus = balance.isSurplus;
    final bgColor = isEmptyCleanSlate
        ? const Color(0xFFF8FAFC)
        : (isSurplus ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF));
    final borderColor = isEmptyCleanSlate
        ? AppTheme.borderSubtle
        : (isSurplus ? const Color(0xFFBBF7D0) : const Color(0xFFBFDBFE));
    final accentColor = isEmptyCleanSlate
        ? AppTheme.solarGold
        : (isSurplus ? AppTheme.emeraldPrimary : AppTheme.electricCyan);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEmptyCleanSlate
                  ? Icons.wb_sunny_outlined
                  : (isSurplus ? Icons.verified_rounded : Icons.trending_down_rounded),
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEmptyCleanSlate
                      ? '☀️ Clean Slate Active'
                      : (isSurplus
                          ? '🏆 100% Net Zero Offset'
                          : '⚡ Slashes ${balance.offsetPercentage.toStringAsFixed(0)}% Grid Draw'),
                  style: AppTypography.style(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildOutcomeBadge('☀️ +${balance.solarMonthlyKwh.toStringAsFixed(0)} u', AppTheme.solarGold),
                    _buildOutcomeBadge('⚡ −${balance.applianceMonthlyKwh.toStringAsFixed(0)} u', AppTheme.electricCyan),
                    if (isSurplus)
                      _buildOutcomeBadge('📤 +${balance.gridExportKwh.toStringAsFixed(0)} u Export', AppTheme.emeraldPrimary)
                    else
                      _buildOutcomeBadge('📥 ${balance.gridImportKwh.toStringAsFixed(0)} u Draw', AppTheme.warmAmber),
                    _buildOutcomeBadge(
                      isSurplus
                          ? '💰 Saved ${Formatters.formatCurrency(balance.monthlySavings, symbol: currency)}'
                          : '💰 Bill: ${Formatters.formatCurrency(balance.solarNetBill, symbol: currency)}',
                      isSurplus ? AppTheme.emeraldPrimary : AppTheme.alertCoral,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomeBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: AppTypography.style(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSolarInputSection(
    BuildContext context,
    EnergyProvider energy,
    double peakSunHours,
    double performanceRatio,
  ) {
    return Container(
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
                'YOUR SOLAR SYSTEM GENERATION',
                style: AppTypography.style(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  NativeChannel.triggerHaptic();
                  energy.resetNetBalanceInputs();
                  _syncControllersWithMonthly(energy.effectiveSolarMonthlyKwh, peakSunHours, performanceRatio);
                },
                icon: const Icon(Icons.restart_alt, size: 15),
                label: const Text('Reset', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Input Mode Pills: Daily Units vs Volts x Amps vs System kW vs Monthly
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildInputModeChip(0, 'Daily Units (kWh/d)', Icons.speed_rounded),
                const SizedBox(width: 8),
                _buildInputModeChip(1, 'Inverter (V × A)', Icons.electric_bolt_rounded),
                const SizedBox(width: 8),
                _buildInputModeChip(2, 'System Size (kW)', Icons.solar_power_rounded),
                const SizedBox(width: 8),
                _buildInputModeChip(3, 'Monthly (kWh)', Icons.calendar_month_rounded),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Interactive Input Form based on selected mode
          if (_inputMode == 0) ...[
            // Mode 0: Daily Units
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _dailyUnitsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Daily Generation',
                      suffixText: 'units/day',
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final daily = double.tryParse(v);
                      if (daily != null && daily >= 0) {
                        energy.setCustomSolarGeneration(daily * 30.0);
                        _monthlyUnitsController.text = (daily * 30.0).toStringAsFixed(0);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly: ${(energy.effectiveSolarMonthlyKwh).toStringAsFixed(0)} kWh',
                        style: AppTypography.style(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.solarGold),
                      ),
                      Text(
                        'Typical reading on digital solar meter',
                        style: AppTypography.style(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else if (_inputMode == 1) ...[
            // Mode 1: Volts x Amps (The user's direct requested idea!)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        'Inverter Output / Battery Voltage × Current',
                        style: AppTypography.style(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _voltageController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Voltage',
                            hintText: '230',
                            suffixText: 'V',
                            isDense: true,
                          ),
                          onChanged: (v) {
                            final volts = double.tryParse(v) ?? energy.voltageVolts;
                            final amps = double.tryParse(_currentController.text) ?? energy.currentAmps;
                            energy.setElectricalSpecs(voltage: volts, current: amps);
                            _syncControllersWithMonthly(energy.effectiveSolarMonthlyKwh, peakSunHours, performanceRatio);
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('×', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _currentController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Current',
                            hintText: '10',
                            suffixText: 'A',
                            isDense: true,
                          ),
                          onChanged: (v) {
                            final amps = double.tryParse(v) ?? energy.currentAmps;
                            final volts = double.tryParse(_voltageController.text) ?? energy.voltageVolts;
                            energy.setElectricalSpecs(voltage: volts, current: amps);
                            _syncControllersWithMonthly(energy.effectiveSolarMonthlyKwh, peakSunHours, performanceRatio);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${energy.voltageVolts.toStringAsFixed(0)}V × ${energy.currentAmps.toStringAsFixed(1)}A = ${(energy.voltageVolts * energy.currentAmps).toStringAsFixed(0)}W ➔ ${(energy.effectiveSolarMonthlyKwh / 30.0).toStringAsFixed(1)} u/d (${energy.effectiveSolarMonthlyKwh.toStringAsFixed(0)} u/mo)',
                        style: AppTypography.style(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.emeraldPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_inputMode == 2) ...[
            // Mode 2: System kW
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _systemKwController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Installed Capacity',
                      suffixText: 'kW',
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final kw = double.tryParse(v);
                      if (kw != null && kw >= 0) {
                        final monthly = kw * peakSunHours * performanceRatio * 30.0;
                        energy.setCustomSolarGeneration(monthly);
                        _dailyUnitsController.text = (monthly / 30.0).toStringAsFixed(1);
                        _monthlyUnitsController.text = monthly.toStringAsFixed(0);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Yields ~${(energy.effectiveSolarMonthlyKwh).toStringAsFixed(0)} kWh/mo at ${peakSunHours.toStringAsFixed(1)} sun-hours',
                    style: AppTypography.style(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Mode 3: Direct Monthly kWh
            TextField(
              controller: _monthlyUnitsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Total Monthly Generation',
                suffixText: 'kWh / month',
                isDense: true,
              ),
              onChanged: (v) {
                final monthly = double.tryParse(v);
                if (monthly != null && monthly >= 0) {
                  energy.setCustomSolarGeneration(monthly);
                  _dailyUnitsController.text = (monthly / 30.0).toStringAsFixed(1);
                }
              },
            ),
          ],

          const SizedBox(height: 14),
          // Quick Presets Row
          Text(
            'Quick Capacity Presets:',
            style: AppTypography.style(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildPresetChip('1 kW (4 u/d)', 120.0, energy, peakSunHours, performanceRatio),
              _buildPresetChip('2 kW (8 u/d)', 240.0, energy, peakSunHours, performanceRatio),
              _buildPresetChip('3 kW (12 u/d)', 360.0, energy, peakSunHours, performanceRatio),
              _buildPresetChip('5 kW (20 u/d)', 600.0, energy, peakSunHours, performanceRatio),
              _buildPresetChip('10 kW (40 u/d)', 1200.0, energy, peakSunHours, performanceRatio),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputModeChip(int modeIndex, String label, IconData icon) {
    final isSelected = _inputMode == modeIndex;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isSelected ? Colors.white : AppTheme.textDark),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
      selected: isSelected,
      onSelected: (sel) {
        if (sel) {
          NativeChannel.triggerHaptic();
          setState(() => _inputMode = modeIndex);
        }
      },
      selectedColor: AppTheme.emeraldPrimary,
      labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textDark),
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildPresetChip(
    String label,
    double monthlyKwh,
    EnergyProvider energy,
    double peakSunHours,
    double performanceRatio,
  ) {
    return ActionChip(
      label: Text(label, style: AppTypography.style(fontSize: 11, fontWeight: FontWeight.w700)),
      backgroundColor: const Color(0xFFF8FAFC),
      side: const BorderSide(color: AppTheme.borderSubtle),
      onPressed: () {
        NativeChannel.triggerHaptic();
        energy.setCustomSolarGeneration(monthlyKwh);
        _syncControllersWithMonthly(monthlyKwh, peakSunHours, performanceRatio);
      },
    );
  }

  Widget _buildApplianceLoadSyncSection(
    BuildContext context,
    EnergyProvider energy,
    dynamic summary,
  ) {
    return Container(
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
                'HOUSEHOLD APPLIANCE CONSUMPTION',
                style: AppTypography.style(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              Switch(
                value: _useHouseholdLoad,
                onChanged: (val) {
                  NativeChannel.triggerHaptic();
                  setState(() => _useHouseholdLoad = val);
                  if (val) {
                    energy.setCustomApplianceLoad(null);
                  } else {
                    final custom = double.tryParse(_customLoadController.text) ?? 200.0;
                    energy.setCustomApplianceLoad(custom);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_useHouseholdLoad) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, color: AppTheme.emeraldPrimary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Synced with ${energy.activeHousehold.name}',
                          style: AppTypography.style(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                        ),
                        Text(
                          '${summary.totalMonthlyKwh.toStringAsFixed(1)} kWh/mo from ${energy.currentAppliances.length} configured appliances',
                          style: AppTypography.style(fontSize: 11, color: AppTheme.emeraldPrimary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customLoadController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Custom Household Consumption',
                      suffixText: 'kWh / mo',
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final custom = double.tryParse(v);
                      if (custom != null && custom >= 0) {
                        energy.setCustomApplianceLoad(custom);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Simulation Mode',
                  style: AppTypography.style(fontSize: 11.5, color: AppTheme.warmAmber, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNetFinancialGrid(BuildContext context, NetEnergyBalance balance, String currency) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildBentoTile(
                'PRE-SOLAR UTILITY BILL',
                Formatters.formatCurrency(balance.originalBill, symbol: currency),
                'Without solar offsets',
                AppTheme.textDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoTile(
                'NEW POST-SOLAR BILL',
                Formatters.formatCurrency(balance.solarNetBill, symbol: currency),
                balance.isSurplus ? '100% Slashed! (Zero bill)' : 'Remaining grid charges',
                balance.isSurplus ? AppTheme.emeraldPrimary : AppTheme.warmAmber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildBentoTile(
                'MONTHLY RELIEF',
                Formatters.formatCurrency(balance.monthlySavings, symbol: currency),
                '${Formatters.formatCurrency(balance.monthlySavings * 12, symbol: currency)}/year saved',
                AppTheme.emeraldPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoTile(
                balance.isSurplus ? 'DISCOM EXPORT CREDIT' : 'GRID IMPORT NEEDED',
                balance.isSurplus
                    ? Formatters.formatCurrency(balance.exportEarnings, symbol: currency)
                    : '${balance.gridImportKwh.toStringAsFixed(0)} kWh',
                balance.isSurplus ? '${balance.gridExportKwh.toStringAsFixed(0)} kWh fed to grid' : 'Supplemental units',
                AppTheme.electricCyan,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNetAuditTable(
    BuildContext context,
    EnergyProvider energy,
    dynamic solar,
    NetEnergyBalance balance,
    String currency,
  ) {
    return Container(
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
            'NET METERING AUDIT & EXPORT RATE',
            style: AppTypography.style(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          _buildSpecRow('Total Solar Generated', '${balance.solarMonthlyKwh.toStringAsFixed(1)} kWh/mo'),
          const Divider(height: 18),
          _buildSpecRow('Total Appliance Load', '${balance.applianceMonthlyKwh.toStringAsFixed(1)} kWh/mo'),
          const Divider(height: 18),
          _buildSpecRow(
            'Net Energy Balance',
            '${balance.isSurplus ? '+' : ''}${balance.netBalanceKwh.toStringAsFixed(1)} kWh',
            isHighlighted: true,
          ),
          const Divider(height: 18),
          _buildSpecRow('Solar Coverage Ratio', '${balance.offsetPercentage.toStringAsFixed(1)}%'),
          const Divider(height: 18),
          _buildSpecRow('Net Monthly Bill Reduction', Formatters.formatCurrency(balance.monthlySavings, symbol: currency)),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Discom Export Credit Rate',
                style: AppTypography.style(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _exportTariffController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    suffixText: '$currency/u',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  onChanged: (v) {
                    final rate = double.tryParse(v);
                    if (rate != null && rate >= 0) {
                      energy.updateSolar(solar.copyWith(exportTariffPerKwh: rate));
                    }
                  },
                ),
              ),
            ],
          ),
          if (balance.exportEarnings > 0) ...[
            const Divider(height: 18),
            _buildSpecRow('Discom Feed-in Earnings', Formatters.formatCurrency(balance.exportEarnings, symbol: currency)),
          ],
        ],
      ),
    );
  }

  Widget _buildBentoTile(String title, String mainValue, String subValue, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.style(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              mainValue,
              style: AppTypography.style(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
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
    );
  }

  Widget _buildSpecRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.style(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: AppTypography.style(
            fontSize: 13,
            fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w700,
            color: isHighlighted ? AppTheme.emeraldPrimary : AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}
