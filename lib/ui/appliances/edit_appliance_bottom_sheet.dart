import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import 'package:provider/provider.dart';
import '../../data/models/household_appliance.dart';
import '../../data/models/appliance_template.dart';
import '../../domain/energy_calculator.dart';
import '../../providers/energy_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/native/native_channel.dart';

class EditApplianceBottomSheet extends StatefulWidget {
  final HouseholdAppliance appliance;
  final bool isNew;

  const EditApplianceBottomSheet({
    super.key,
    required this.appliance,
    this.isNew = false,
  });

  static Future<void> show(
    BuildContext context, {
    required HouseholdAppliance appliance,
    bool isNew = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => EditApplianceBottomSheet(appliance: appliance, isNew: isNew),
    );
  }

  @override
  State<EditApplianceBottomSheet> createState() => _EditApplianceBottomSheetState();
}

class _EditApplianceBottomSheetState extends State<EditApplianceBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _wattageController;
  late int _quantity;
  late double _hoursPerDay;
  late int _daysPerMonth;
  late int _cyclesPerMonth;
  late double _dutyCycle;
  late double _kwhPerCycle;
  late UsageProfile _usageProfile;
  late CalculationType _calculationType;
  bool _isAdvancedExpanded = false;

  @override
  void initState() {
    super.initState();
    final a = widget.appliance;
    _nameController = TextEditingController(text: a.name);
    _wattageController = TextEditingController(text: a.wattage.toStringAsFixed(0));
    _quantity = a.quantity;
    _hoursPerDay = a.hoursPerDay;
    _daysPerMonth = a.daysPerMonth;
    _cyclesPerMonth = a.cyclesPerMonth;
    _dutyCycle = a.dutyCycle;
    _kwhPerCycle = a.kwhPerCycle;
    _usageProfile = a.usageProfile;
    _calculationType = a.calculationType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wattageController.dispose();
    super.dispose();
  }

  HouseholdAppliance _buildCurrentAppliance() {
    final parsedWatts = double.tryParse(_wattageController.text) ?? widget.appliance.wattage;
    return widget.appliance.copyWith(
      name: _nameController.text.trim().isEmpty ? widget.appliance.name : _nameController.text.trim(),
      wattage: parsedWatts,
      quantity: _quantity,
      hoursPerDay: _hoursPerDay,
      daysPerMonth: _daysPerMonth,
      cyclesPerMonth: _cyclesPerMonth,
      dutyCycle: _dutyCycle,
      kwhPerCycle: _kwhPerCycle,
      usageProfile: _usageProfile,
      calculationType: _calculationType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final energy = context.watch<EnergyProvider>();
    final settings = context.watch<SettingsProvider>();
    final tempAppliance = _buildCurrentAppliance();
    final monthlyKwh = EnergyCalculator.calculateApplianceMonthlyKwh(
      tempAppliance,
      monthDays: energy.activeHousehold.daysInMonth,
    );
    final rate = energy.billResult.effectiveRatePerKwh > 0
        ? energy.billResult.effectiveRatePerKwh
        : energy.tariff.flatRatePerKwh;
    final estimatedCost = monthlyKwh * rate;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 14,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Formatters.getCategoryColor(widget.appliance.category).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Formatters.getCategoryIcon(widget.appliance.category),
                    color: Formatters.getCategoryColor(widget.appliance.category),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isNew ? 'Add Appliance' : 'Configure Appliance',
                        style: AppTypography.style(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        Formatters.getCategoryName(widget.appliance.category),
                        style: AppTypography.style(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Real-time Consumption Preview Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESTIMATED IMPACT',
                        style: AppTypography.style(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.emeraldPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${monthlyKwh.toStringAsFixed(1)} kWh / month',
                        style: AppTypography.style(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '~${Formatters.formatCurrency(estimatedCost, symbol: settings.currency)}/mo',
                    style: AppTypography.style(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.emeraldPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Appliance Name Field
            TextField(
              controller: _nameController,
              style: AppTypography.style(fontWeight: FontWeight.w600, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Appliance Name',
                prefixIcon: Icon(Icons.label_outline, size: 19, color: AppTheme.textMuted),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Quantity Stepper
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quantity Owned',
                  style: AppTypography.style(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppTheme.textDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: _quantity > 1
                            ? () {
                                NativeChannel.triggerHaptic();
                                setState(() => _quantity--);
                              }
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 16,
                            color: _quantity > 1 ? AppTheme.textDark : AppTheme.textSubtle,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '$_quantity',
                          style: AppTypography.style(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          NativeChannel.triggerHaptic();
                          setState(() => _quantity++);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, size: 16, color: AppTheme.textDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Usage Controls
            if (_calculationType == CalculationType.perCycle) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Washes per Month',
                    style: AppTypography.style(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Text(
                    '$_cyclesPerMonth washes',
                    style: AppTypography.style(fontWeight: FontWeight.w800, color: AppTheme.emeraldPrimary),
                  ),
                ],
              ),
              Slider(
                value: _cyclesPerMonth.toDouble(),
                min: 1,
                max: 60,
                divisions: 59,
                label: '$_cyclesPerMonth washes',
                onChanged: (v) => setState(() => _cyclesPerMonth = v.round()),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Operating Hours',
                    style: AppTypography.style(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Text(
                    '${_hoursPerDay.toStringAsFixed(1)} hrs/day',
                    style: AppTypography.style(fontWeight: FontWeight.w800, color: AppTheme.emeraldPrimary),
                  ),
                ],
              ),
              Slider(
                value: _hoursPerDay,
                min: 0.25,
                max: 24.0,
                divisions: 95,
                label: '${_hoursPerDay.toStringAsFixed(1)} hrs',
                onChanged: (v) => setState(() => _hoursPerDay = v),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Days Active per Month',
                    style: AppTypography.style(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Text(
                    '$_daysPerMonth days',
                    style: AppTypography.style(fontWeight: FontWeight.w800, color: AppTheme.textDark),
                  ),
                ],
              ),
              Slider(
                value: _daysPerMonth.toDouble(),
                min: 1,
                max: 31,
                divisions: 30,
                label: '$_daysPerMonth days',
                onChanged: (v) => setState(() => _daysPerMonth = v.round()),
              ),
            ],

            const SizedBox(height: 10),

            // Intensity Profile Chips
            Text(
              'Usage Intensity Profile',
              style: AppTypography.style(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildProfileChip(UsageProfile.low, 'Low (0.8x)'),
                const SizedBox(width: 8),
                _buildProfileChip(UsageProfile.normal, 'Normal (1.0x)'),
                const SizedBox(width: 8),
                _buildProfileChip(UsageProfile.heavy, 'Heavy (1.25x)'),
              ],
            ),
            const SizedBox(height: 14),

            // Optional Technical Specs
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Advanced Technical Specs (Optional)',
                  style: AppTypography.style(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                ),
                subtitle: Text(
                  'Default wattage: ${widget.appliance.wattage.toStringAsFixed(0)}W',
                  style: AppTypography.style(fontSize: 11, color: AppTheme.textSubtle),
                ),
                initiallyExpanded: _isAdvancedExpanded,
                onExpansionChanged: (v) => setState(() => _isAdvancedExpanded = v),
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: _wattageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Power Rating (Watts)',
                      suffixText: 'W',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_calculationType == CalculationType.dutyCycle) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Compressor Duty Cycle', style: AppTypography.style(fontWeight: FontWeight.w600, fontSize: 12.5)),
                        Text('${(_dutyCycle * 100).toStringAsFixed(0)}%', style: AppTypography.style(fontWeight: FontWeight.w800, color: AppTheme.electricCyan)),
                      ],
                    ),
                    Slider(
                      value: _dutyCycle,
                      min: 0.1,
                      max: 1.0,
                      divisions: 18,
                      label: '${(_dutyCycle * 100).toStringAsFixed(0)}%',
                      onChanged: (v) => setState(() => _dutyCycle = v),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bottom Action Buttons
            Row(
              children: [
                if (!widget.isNew) ...[
                  IconButton.outlined(
                    tooltip: 'Duplicate Appliance',
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    onPressed: () async {
                      NativeChannel.triggerHaptic();
                      await energy.duplicateAppliance(widget.appliance);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: 'Delete Appliance',
                    icon: const Icon(Icons.delete_outline, color: AppTheme.alertCoral, size: 18),
                    onPressed: () async {
                      NativeChannel.triggerHaptic();
                      await energy.deleteAppliance(widget.appliance.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      NativeChannel.triggerHaptic();
                      final app = _buildCurrentAppliance();
                      if (widget.isNew) {
                        await energy.addAppliance(app);
                      } else {
                        await energy.updateAppliance(app);
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppTheme.emeraldPrimary,
                    ),
                    child: Text(
                      widget.isNew ? 'Add to Household' : 'Save Changes',
                      style: AppTypography.style(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileChip(UsageProfile profile, String label) {
    final isSelected = _usageProfile == profile;
    return InkWell(
      onTap: () {
        NativeChannel.triggerHaptic();
        setState(() => _usageProfile = profile);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.emeraldPrimary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: AppTypography.style(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textDark,
          ),
        ),
      ),
    );
  }
}
