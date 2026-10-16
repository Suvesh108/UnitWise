import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/native/native_channel.dart';
import '../../providers/energy_provider.dart';
import '../../data/models/household_appliance.dart';
import '../../data/models/appliance_template.dart';

class DiscoveredDevice {
  final String id;
  final String name;
  final String model;
  final ApplianceCategory category;
  final double watts;
  final double voltage;
  final double current;
  final String protocol; // 'Wi-Fi (mDNS)' or 'Bluetooth (BLE)'
  final String address;  // IP or MAC
  final IconData icon;

  DiscoveredDevice({
    required this.id,
    required this.name,
    required this.model,
    required this.category,
    required this.watts,
    required this.voltage,
    required this.current,
    required this.protocol,
    required this.address,
    required this.icon,
  });
}

class AutoDetectDialog extends StatefulWidget {
  const AutoDetectDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AutoDetectDialog(),
    );
  }

  @override
  State<AutoDetectDialog> createState() => _AutoDetectDialogState();
}

class _AutoDetectDialogState extends State<AutoDetectDialog> with SingleTickerProviderStateMixin {
  bool _isScanning = true;
  late AnimationController _pulseController;
  final List<DiscoveredDevice> _discovered = [];
  final Set<String> _addedIds = {};
  Timer? _scanTimer;

  // Realistic sample appliances discovered across local network (mDNS) & BLE
  final List<DiscoveredDevice> _candidates = [
    DiscoveredDevice(
      id: 'shelly_1pm_ac',
      name: 'Master Bed Split AC',
      model: 'Shelly Plus 1PM',
      category: ApplianceCategory.cooling,
      watts: 1450.0,
      voltage: 230.0,
      current: 6.3,
      protocol: 'Wi-Fi (mDNS)',
      address: '192.168.1.104',
      icon: Icons.ac_unit_rounded,
    ),
    DiscoveredDevice(
      id: 'tapo_p110_fridge',
      name: 'Kitchen Double-Door Refrigerator',
      model: 'Tapo P110 Meter',
      category: ApplianceCategory.kitchen,
      watts: 180.0,
      voltage: 231.0,
      current: 0.78,
      protocol: 'Wi-Fi (mDNS)',
      address: '192.168.1.118',
      icon: Icons.kitchen_rounded,
    ),
    DiscoveredDevice(
      id: 'ble_meter_cooktop',
      name: 'Induction Cooktop',
      model: 'BLE Energy Meter v2',
      category: ApplianceCategory.kitchen,
      watts: 1800.0,
      voltage: 230.0,
      current: 7.8,
      protocol: 'Bluetooth (BLE)',
      address: 'RSSI -62 dBm',
      icon: Icons.soup_kitchen_rounded,
    ),
    DiscoveredDevice(
      id: 'tuya_desk_pc',
      name: 'Workstation & Monitors',
      model: 'Tuya Smart Plug',
      category: ApplianceCategory.entertainment,
      watts: 320.0,
      voltage: 229.0,
      current: 1.4,
      protocol: 'Wi-Fi (mDNS)',
      address: '192.168.1.142',
      icon: Icons.computer_rounded,
    ),
    DiscoveredDevice(
      id: 'smart_inverter_solar',
      name: 'Rooftop Solar Inverter Telemetry',
      model: 'Hybrid Inverter Wi-Fi',
      category: ApplianceCategory.other,
      watts: 2400.0,
      voltage: 230.0,
      current: 10.4,
      protocol: 'Wi-Fi (mDNS)',
      address: '192.168.1.150',
      icon: Icons.solar_power_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _startDiscovery();
  }

  void _startDiscovery() {
    setState(() {
      _isScanning = true;
      _discovered.clear();
    });

    int index = 0;
    _scanTimer = Timer.periodic(const Duration(milliseconds: 650), (timer) {
      if (index < _candidates.length) {
        if (mounted) {
          NativeChannel.triggerHaptic();
          setState(() {
            _discovered.add(_candidates[index]);
          });
        }
        index++;
      } else {
        timer.cancel();
        if (mounted) {
          setState(() => _isScanning = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _addDevice(DiscoveredDevice dev) {
    NativeChannel.triggerHaptic();
    final energy = context.read<EnergyProvider>();

    final newApp = HouseholdAppliance(
      id: 'auto_${dev.id}_${DateTime.now().millisecondsSinceEpoch}',
      householdId: energy.activeHousehold.id,
      name: dev.name,
      category: dev.category,
      wattage: dev.watts,
      hoursPerDay: dev.category == ApplianceCategory.kitchen ? 3.0 : 6.0,
      daysPerMonth: energy.activeHousehold.daysInMonth,
      quantity: 1,
      calculationType: dev.category == ApplianceCategory.cooling
          ? CalculationType.dutyCycle
          : CalculationType.continuous,
      dutyCycle: 0.65,
    );

    energy.addAppliance(newApp);

    setState(() {
      _addedIds.add(dev.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${dev.name}" (${dev.watts.toStringAsFixed(0)}W) to household!'),
        backgroundColor: AppTheme.emeraldPrimary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.electricCyan.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.radar_rounded, color: AppTheme.electricCyan, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Detect Appliances',
                        style: AppTypography.style(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        'Scanning Dual-Mode: Wi-Fi (mDNS) + BLE',
                        style: AppTypography.style(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_isScanning)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.electricCyan.withValues(alpha: 0.15 + (_pulseController.value * 0.15)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.electricCyan,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Scanning...',
                            style: AppTypography.style(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.electricCyan,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              else
                IconButton(
                  tooltip: 'Rescan',
                  icon: const Icon(Icons.refresh_rounded, size: 20, color: AppTheme.textDark),
                  onPressed: _startDiscovery,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 15, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Discovered smart devices appear automatically. Tap "Add" to sync live telemetry into UnitWise.',
                    style: AppTypography.style(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Device List
          Expanded(
            child: _discovered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppTheme.electricCyan,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Broadcasting mDNS & BLE beacons...',
                          style: AppTypography.style(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _discovered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final dev = _discovered[index];
                      final isAdded = _addedIds.contains(dev.id);

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isAdded ? const Color(0xFFF0FDF4) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isAdded ? const Color(0xFFBBF7D0) : AppTheme.borderSubtle,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: (dev.protocol.contains('BLE') ? AppTheme.warmAmber : AppTheme.electricCyan)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                dev.icon,
                                color: dev.protocol.contains('BLE') ? AppTheme.warmAmber : AppTheme.electricCyan,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          dev.name,
                                          style: AppTypography.style(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.textDark,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: dev.protocol.contains('BLE')
                                              ? AppTheme.warmAmber.withValues(alpha: 0.1)
                                              : AppTheme.electricCyan.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          dev.protocol,
                                          style: AppTypography.style(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: dev.protocol.contains('BLE')
                                                ? AppTheme.warmAmber
                                                : AppTheme.electricCyan,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        dev.model,
                                        style: AppTypography.style(fontSize: 10.5, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '⚡ ${dev.watts.toStringAsFixed(0)}W',
                                        style: AppTypography.style(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.emeraldPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${dev.voltage.toStringAsFixed(0)}V • ${dev.current.toStringAsFixed(1)}A',
                                        style: AppTypography.style(fontSize: 11, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            isAdded
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.emeraldPrimary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check, size: 14, color: AppTheme.emeraldPrimary),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Added',
                                          style: AppTypography.style(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.emeraldPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : FilledButton(
                                    onPressed: () => _addDevice(dev),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppTheme.emeraldPrimary,
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Add'),
                                  ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),

          // Bottom Close button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.borderSubtle),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
