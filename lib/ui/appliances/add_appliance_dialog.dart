import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import 'package:provider/provider.dart';
import '../../data/models/household_appliance.dart';
import '../../data/models/appliance_template.dart';
import '../../providers/energy_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/native/native_channel.dart';

class AddCustomApplianceDialog extends StatefulWidget {
  const AddCustomApplianceDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const AddCustomApplianceDialog(),
    );
  }

  @override
  State<AddCustomApplianceDialog> createState() => _AddCustomApplianceDialogState();
}

class _AddCustomApplianceDialogState extends State<AddCustomApplianceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _wattsController = TextEditingController(text: '100');
  final _hoursController = TextEditingController(text: '4.0');
  ApplianceCategory _category = ApplianceCategory.other;
  int _quantity = 1;

  @override
  void dispose() {
    _nameController.dispose();
    _wattsController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final energy = context.read<EnergyProvider>();

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
            child: const Icon(Icons.add_box_outlined, color: AppTheme.emeraldPrimary, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'Custom Appliance',
            style: AppTypography.style(fontWeight: FontWeight.w800, fontSize: 17),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                style: AppTypography.style(fontWeight: FontWeight.w600, fontSize: 13.5),
                decoration: const InputDecoration(
                  labelText: 'Appliance Name',
                  hintText: 'e.g. Wine Cooler / Aquarium Heater',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter appliance name' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ApplianceCategory>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category', contentPadding: EdgeInsets.all(12)),
                items: ApplianceCategory.values.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Icon(Formatters.getCategoryIcon(c), size: 16, color: Formatters.getCategoryColor(c)),
                        const SizedBox(width: 8),
                        Text(Formatters.getCategoryName(c), style: AppTypography.style(fontSize: 13)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _wattsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Power (Watts)', suffixText: 'W'),
                      validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _hoursController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Daily Hours', suffixText: 'h'),
                      validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quantity',
                    style: AppTypography.style(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove, size: 14),
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '$_quantity',
                          style: AppTypography.style(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add, size: 14),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ],
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
            if (_formKey.currentState?.validate() ?? false) {
              NativeChannel.triggerHaptic();
              final watts = double.parse(_wattsController.text);
              final hours = double.parse(_hoursController.text);
              final newApp = HouseholdAppliance(
                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                householdId: energy.activeHousehold.id,
                name: _nameController.text.trim(),
                category: _category,
                calculationType: CalculationType.continuous,
                quantity: _quantity,
                wattage: watts,
                hoursPerDay: hours,
                daysPerMonth: energy.activeHousehold.daysInMonth,
              );
              await energy.addAppliance(newApp);
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text('Add Appliance'),
        ),
      ],
    );
  }
}
