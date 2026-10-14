import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import 'package:provider/provider.dart';
import '../../data/models/tariff_config.dart';
import '../../providers/energy_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/native/native_channel.dart';

class TariffSettingsDialog extends StatefulWidget {
  const TariffSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const TariffSettingsDialog(),
    );
  }

  @override
  State<TariffSettingsDialog> createState() => _TariffSettingsDialogState();
}

class _TariffSettingsDialogState extends State<TariffSettingsDialog> {
  late TariffType _tariffType;
  late TextEditingController _flatRateController;
  late TextEditingController _fixedChargeController;
  late TextEditingController _taxController;
  late TextEditingController _fpppaController;
  late List<TariffSlab> _slabs;

  @override
  void initState() {
    super.initState();
    final tariff = context.read<EnergyProvider>().tariff;
    _tariffType = tariff.type;
    _flatRateController = TextEditingController(text: tariff.flatRatePerKwh.toStringAsFixed(2));
    _fixedChargeController = TextEditingController(text: tariff.fixedCharge.toStringAsFixed(0));
    _taxController = TextEditingController(text: tariff.taxPercentage.toStringAsFixed(1));
    _fpppaController = TextEditingController(text: tariff.fpppaRatePerKwh.toStringAsFixed(2));
    _slabs = List.from(tariff.slabs);
  }

  @override
  void dispose() {
    _flatRateController.dispose();
    _fixedChargeController.dispose();
    _taxController.dispose();
    _fpppaController.dispose();
    super.dispose();
  }

  void _applyPreset(String presetKey) {
    NativeChannel.triggerHaptic();
    switch (presetKey) {
      case 'national_standard':
        setState(() {
          _tariffType = TariffType.tieredSlab;
          _slabs = [
            const TariffSlab(fromUnits: 0, toUnits: 100, ratePerKwh: 3.50),
            const TariffSlab(fromUnits: 100, toUnits: 200, ratePerKwh: 5.50),
            const TariffSlab(fromUnits: 200, toUnits: 400, ratePerKwh: 7.50),
            const TariffSlab(fromUnits: 400, toUnits: double.infinity, ratePerKwh: 9.50),
          ];
          _fixedChargeController.text = '120';
          _taxController.text = '9.0';
          _fpppaController.text = '0.35';
        });
        break;

      case 'delhi_subsidized':
        setState(() {
          _tariffType = TariffType.tieredSlab;
          _slabs = [
            const TariffSlab(fromUnits: 0, toUnits: 200, ratePerKwh: 3.00),
            const TariffSlab(fromUnits: 200, toUnits: 400, ratePerKwh: 4.50),
            const TariffSlab(fromUnits: 400, toUnits: double.infinity, ratePerKwh: 6.50),
          ];
          _fixedChargeController.text = '50';
          _taxController.text = '5.0';
          _fpppaController.text = '0.20';
        });
        break;

      case 'msedcl_maharashtra':
        setState(() {
          _tariffType = TariffType.tieredSlab;
          _slabs = [
            const TariffSlab(fromUnits: 0, toUnits: 100, ratePerKwh: 4.71),
            const TariffSlab(fromUnits: 100, toUnits: 300, ratePerKwh: 8.87),
            const TariffSlab(fromUnits: 300, toUnits: 500, ratePerKwh: 12.04),
            const TariffSlab(fromUnits: 500, toUnits: double.infinity, ratePerKwh: 13.82),
          ];
          _fixedChargeController.text = '138';
          _taxController.text = '16.0';
          _fpppaController.text = '0.65';
        });
        break;

      case 'flat_rate':
        setState(() {
          _tariffType = TariffType.flat;
          _flatRateController.text = '6.50';
          _fixedChargeController.text = '100';
          _taxController.text = '6.0';
          _fpppaController.text = '0.25';
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currency;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.emeraldPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tune, color: AppTheme.emeraldPrimary, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'Tariff Configuration',
            style: AppTypography.style(fontWeight: FontWeight.w800, fontSize: 17),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REGIONAL PRESET',
                style: AppTypography.style(
                  fontWeight: FontWeight.w800,
                  fontSize: 10.5,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(11)),
                hint: const Text('Select a preset template'),
                items: const [
                  DropdownMenuItem(value: 'national_standard', child: Text('Standard Slabs (India Avg)')),
                  DropdownMenuItem(value: 'msedcl_maharashtra', child: Text('Maharashtra (MSEDCL)')),
                  DropdownMenuItem(value: 'delhi_subsidized', child: Text('Delhi (BRPL/BYPL)')),
                  DropdownMenuItem(value: 'flat_rate', child: Text('Simple Flat Rate')),
                ],
                onChanged: (v) {
                  if (v != null) _applyPreset(v);
                },
              ),
              const SizedBox(height: 16),

              // Segmented Button
              SegmentedButton<TariffType>(
                segments: const [
                  ButtonSegment(value: TariffType.tieredSlab, label: Text('Tiered Slabs')),
                  ButtonSegment(value: TariffType.flat, label: Text('Flat Rate')),
                ],
                selected: {_tariffType},
                onSelectionChanged: (val) {
                  NativeChannel.triggerHaptic();
                  setState(() => _tariffType = val.first);
                },
              ),
              const SizedBox(height: 16),

              if (_tariffType == TariffType.flat) ...[
                TextField(
                  controller: _flatRateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Flat Rate per kWh ($currency)',
                    prefixText: '$currency ',
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Slab Tiers',
                      style: AppTypography.style(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 15),
                      label: const Text('Add Slab'),
                      onPressed: () {
                        setState(() {
                          final lastTo = _slabs.isNotEmpty && !_slabs.last.toUnits.isInfinite
                              ? _slabs.last.toUnits
                              : 400.0;
                          _slabs.add(TariffSlab(
                            fromUnits: lastTo,
                            toUnits: double.infinity,
                            ratePerKwh: 8.5,
                          ));
                        });
                      },
                    ),
                  ],
                ),
                ..._slabs.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final slab = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              slab.toUnits.isInfinite
                                  ? '${slab.fromUnits.toStringAsFixed(0)}+ units'
                                  : '${slab.fromUnits.toStringAsFixed(0)} - ${slab.toUnits.toStringAsFixed(0)} units',
                              style: AppTypography.style(fontWeight: FontWeight.w600, fontSize: 12.5),
                            ),
                          ),
                          Text(
                            '$currency${slab.ratePerKwh.toStringAsFixed(2)}/u',
                            style: AppTypography.style(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.emeraldPrimary,
                              fontSize: 12.5,
                            ),
                          ),
                          if (_slabs.length > 1)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.close, size: 16, color: AppTheme.alertCoral),
                              onPressed: () {
                                setState(() => _slabs.removeAt(idx));
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fixedChargeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Fixed ($currency/mo)',
                        prefixText: '$currency ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _fpppaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'FPPPA ($currency/u)',
                        prefixText: '$currency ',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _taxController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Duty / Tax (%)',
                  suffixText: '%',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            NativeChannel.triggerHaptic();
            final flatRate = double.tryParse(_flatRateController.text) ?? 6.5;
            final fixed = double.tryParse(_fixedChargeController.text) ?? 100.0;
            final tax = double.tryParse(_taxController.text) ?? 9.0;
            final fpppa = double.tryParse(_fpppaController.text) ?? 0.35;

            final newTariff = TariffConfig(
              id: 'custom_tariff',
              name: _tariffType == TariffType.flat ? 'Custom Flat Rate' : 'Configured Slab Tariff',
              type: _tariffType,
              flatRatePerKwh: flatRate,
              slabs: _slabs,
              fixedCharge: fixed,
              taxPercentage: tax,
              fpppaRatePerKwh: fpppa,
              currencySymbol: currency,
            );

            await context.read<EnergyProvider>().updateTariff(newTariff);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save Tariff'),
        ),
      ],
    );
  }
}
