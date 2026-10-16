import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/native/native_channel.dart';
import '../../data/models/household.dart';
import '../../providers/energy_provider.dart';

class PropertySwitcherSheet extends StatelessWidget {
  const PropertySwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    NativeChannel.triggerHaptic();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PropertySwitcherSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final energy = context.watch<EnergyProvider>();
    final properties = energy.households;
    final activeId = energy.activeHouseholdId;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          const SizedBox(height: 14),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Properties',
                    style: AppTypography.style(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    'Manage residences, offices & shops separately',
                    style: AppTypography.style(
                      fontSize: 11.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: AppTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // List of Properties
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: properties.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final prop = properties[index];
                final isActive = prop.id == activeId;
                final appCount = energy.getApplianceCountForHousehold(prop.id);
                final monthlyKwh = energy.getMonthlyKwhForHousehold(prop.id);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      NativeChannel.triggerHaptic();
                      energy.switchHousehold(prop.id);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isActive ? prop.propertyType.color.withValues(alpha: 0.06) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive ? prop.propertyType.color : AppTheme.borderSubtle,
                          width: isActive ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Property Type Icon
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: prop.propertyType.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              prop.propertyType.icon,
                              size: 20,
                              color: prop.propertyType.color,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Property details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        prop.name,
                                        style: AppTypography.style(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: prop.propertyType.color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        prop.propertyType.displayName,
                                        style: AppTypography.style(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: prop.propertyType.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$appCount appliances • ${monthlyKwh.toStringAsFixed(0)} kWh/mo',
                                  style: AppTypography.style(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Active Badge or Delete action
                          if (isActive) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: prop.propertyType.color,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check, size: 12, color: Colors.white),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Active',
                                    style: AppTypography.style(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (properties.length > 1) ...[
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.textSubtle),
                              tooltip: 'Delete Property',
                              onPressed: () {
                                _confirmDelete(context, energy, prop);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Add New Property Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                AddPropertyDialog.show(context);
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add New Property'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.emeraldPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, EnergyProvider energy, Household prop) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${prop.name}?'),
        content: const Text('This will delete this property and all of its associated appliances locally.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.alertCoral),
            onPressed: () {
              Navigator.pop(ctx);
              energy.deleteHousehold(prop.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// ADD PROPERTY DIALOG
// -------------------------------------------------------------
class AddPropertyDialog extends StatefulWidget {
  const AddPropertyDialog({super.key});

  static Future<void> show(BuildContext context) {
    NativeChannel.triggerHaptic();
    return showDialog(
      context: context,
      builder: (_) => const AddPropertyDialog(),
    );
  }

  @override
  State<AddPropertyDialog> createState() => _AddPropertyDialogState();
}

class _AddPropertyDialogState extends State<AddPropertyDialog> {
  PropertyType _selectedType = PropertyType.residence;
  final TextEditingController _nameController = TextEditingController(text: 'Home Residence');
  final TextEditingController _locationController = TextEditingController(text: 'Main Grid');

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onTypeChanged(PropertyType type) {
    setState(() {
      _selectedType = type;
      switch (type) {
        case PropertyType.residence:
          _nameController.text = 'Residence';
          break;
        case PropertyType.office:
          _nameController.text = 'Workplace Office';
          break;
        case PropertyType.shop:
          _nameController.text = 'Retail Shop';
          break;
        case PropertyType.industrial:
          _nameController.text = 'Industrial Unit';
          break;
        case PropertyType.other:
          _nameController.text = 'New Property';
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final energy = context.read<EnergyProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add New Property',
                    style: AppTypography.style(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                      letterSpacing: -0.4,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Property Type Selection Chips
              Text(
                'PROPERTY TYPE',
                style: AppTypography.style(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PropertyType.values.map((type) {
                  final isSelected = type == _selectedType;
                  return InkWell(
                    onTap: () {
                      NativeChannel.triggerHaptic();
                      _onTypeChanged(type);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? type.color.withValues(alpha: 0.12) : AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? type.color : AppTheme.borderSubtle,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(type.icon, size: 16, color: isSelected ? type.color : AppTheme.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            type.displayName,
                            style: AppTypography.style(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? type.color : AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Property Name Field
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Property Name',
                  hintText: 'e.g. Downtown Store, Green Villa',
                ),
              ),
              const SizedBox(height: 12),

              // Location Field
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location / Area',
                  hintText: 'e.g. Metro Grid, Sector 4',
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () async {
                        final name = _nameController.text.trim();
                        if (name.isEmpty) return;
                        NativeChannel.triggerHaptic();
                        await energy.createProperty(
                          name: name,
                          propertyType: _selectedType,
                          location: _locationController.text.trim().isEmpty
                              ? 'Default Location'
                              : _locationController.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Switched to $name (${_selectedType.displayName})'),
                              backgroundColor: AppTheme.emeraldPrimary,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.emeraldPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Create Property'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
