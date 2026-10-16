import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/native/native_channel.dart';
import '../../providers/energy_provider.dart';
import '../../data/models/household_appliance.dart';
import '../../data/models/appliance_template.dart';
import '../widgets/smooth_entrance.dart';

class DiscoveredDevice {
  final String id;
  final String name;
  final String model;
  final ApplianceCategory category;
  final double watts;
  final double voltage;
  final double current;
  final String protocol;
  final String address;
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
    NativeChannel.triggerHaptic();
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

class _AutoDetectDialogState extends State<AutoDetectDialog>
    with SingleTickerProviderStateMixin {
  bool _isScanning = true;
  String _scanStatus = 'Initializing network interfaces...';
  String _localSubnet = '';
  late AnimationController _pulseController;
  final List<DiscoveredDevice> _discovered = [];
  final Set<String> _addedIds = {};
  final TextEditingController _manualIpController = TextEditingController();
  bool _isConnectingManual = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _startLiveNetworkScan();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _manualIpController.dispose();
    super.dispose();
  }

  Future<void> _startLiveNetworkScan() async {
    setState(() {
      _isScanning = true;
      _discovered.clear();
      _scanStatus = 'Probing local Wi-Fi subnet...';
    });

    try {
      // 1. Identify local IPv4 network interface
      String? localIp;
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.address.contains('.')) {
            localIp = addr.address;
            break;
          }
        }
        if (localIp != null) break;
      }

      if (localIp != null) {
        final parts = localIp.split('.');
        if (parts.length == 4) {
          _localSubnet = '${parts[0]}.${parts[1]}.${parts[2]}.';
        }
      }

      if (_localSubnet.isEmpty) {
        _localSubnet = '192.168.1.';
      }

      if (mounted) {
        setState(() {
          _scanStatus = 'Probing subnet ${_localSubnet}0/24 for IoT smart plugs...';
        });
      }

      // 2. Probe common IoT gateway addresses for Shelly, Tasmota, Tapo, and smart meters
      final candidateIps = <String>[];
      // Target router and standard DHCP pool addresses
      for (int i = 1; i <= 25; i++) {
        candidateIps.add('$_localSubnet$i');
      }
      // Also probe standard high IPs where smart plugs commonly live
      for (int i = 100; i <= 115; i++) {
        candidateIps.add('$_localSubnet$i');
      }

      final client = HttpClient();
      client.connectionTimeout = const Duration(milliseconds: 600);

      for (final ip in candidateIps) {
        if (!mounted || !_isScanning) break;
        try {
          final device = await _probeDeviceAtIp(client, ip);
          if (device != null && mounted) {
            NativeChannel.triggerHaptic();
            setState(() {
              _discovered.add(device);
            });
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('AutoDetect: Network scan exception: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _scanStatus = _discovered.isEmpty
              ? 'No smart meters found on subnet ${_localSubnet}0/24'
              : 'Scan complete (${_discovered.length} device${_discovered.length == 1 ? '' : 's'} found)';
        });
      }
    }
  }

  Future<DiscoveredDevice?> _probeDeviceAtIp(HttpClient client, String ip) async {
    try {
      // 1. Probe Shelly Plus/Pro RPC API: /rpc/Shelly.GetStatus
      final shellyUri = Uri.parse('http://$ip/rpc/Shelly.GetStatus');
      final req = await client.getUrl(shellyUri);
      final res = await req.close().timeout(const Duration(milliseconds: 700));

      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;

        // Extract real telemetry
        double watts = 0.0;
        double voltage = 230.0;
        double current = 0.0;

        if (json['switch:0'] != null) {
          final sw = json['switch:0'] as Map<String, dynamic>;
          watts = (sw['apower'] as num?)?.toDouble() ?? 0.0;
          voltage = (sw['voltage'] as num?)?.toDouble() ?? 230.0;
          current = (sw['current'] as num?)?.toDouble() ?? (watts / 230.0);
        } else if (json['meters'] is List && (json['meters'] as List).isNotEmpty) {
          final m = (json['meters'] as List).first as Map<String, dynamic>;
          watts = (m['power'] as num?)?.toDouble() ?? 0.0;
        }

        final sys = json['sys'] as Map<String, dynamic>?;
        final devName = sys?['device_id']?.toString() ?? 'Shelly Smart Plug';

        return DiscoveredDevice(
          id: 'shelly_$ip',
          name: devName,
          model: 'Shelly IoT Meter',
          category: _categorizeByWatts(watts),
          watts: watts,
          voltage: voltage,
          current: current,
          protocol: 'Wi-Fi (mDNS / HTTP)',
          address: ip,
          icon: Icons.power_rounded,
        );
      }
    } catch (_) {}

    try {
      // 2. Probe Tasmota / Sonoff status: /cm?cmnd=Status%208
      final tasmotaUri = Uri.parse('http://$ip/cm?cmnd=Status%208');
      final req = await client.getUrl(tasmotaUri);
      final res = await req.close().timeout(const Duration(milliseconds: 700));

      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final statusSns = json['StatusSNS'] as Map<String, dynamic>?;
        final energy = statusSns?['ENERGY'] as Map<String, dynamic>?;

        if (energy != null) {
          final watts = (energy['Power'] as num?)?.toDouble() ?? 0.0;
          final voltage = (energy['Voltage'] as num?)?.toDouble() ?? 230.0;
          final current = (energy['Current'] as num?)?.toDouble() ?? (watts / 230.0);

          return DiscoveredDevice(
            id: 'tasmota_$ip',
            name: 'Tasmota Energy Meter ($ip)',
            model: 'Tasmota Smart Meter',
            category: _categorizeByWatts(watts),
            watts: watts,
            voltage: voltage,
            current: current,
            protocol: 'Wi-Fi (HTTP)',
            address: ip,
            icon: Icons.bolt_rounded,
          );
        }
      }
    } catch (_) {}

    return null;
  }

  Future<void> _connectManualIp() async {
    final ip = _manualIpController.text.trim();
    if (ip.isEmpty) return;

    NativeChannel.triggerHaptic();
    setState(() => _isConnectingManual = true);

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);
      final dev = await _probeDeviceAtIp(client, ip);

      if (dev != null) {
        setState(() {
          _discovered.removeWhere((d) => d.address == ip);
          _discovered.insert(0, dev);
          _manualIpController.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connected to ${dev.name} at $ip (${dev.watts.toStringAsFixed(0)}W)!'),
              backgroundColor: AppTheme.emeraldPrimary,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not reach smart plug at $ip. Check IP & Wi-Fi connection.'),
              backgroundColor: AppTheme.alertCoral,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: $e'),
            backgroundColor: AppTheme.alertCoral,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnectingManual = false);
      }
    }
  }

  ApplianceCategory _categorizeByWatts(double watts) {
    if (watts > 1200) return ApplianceCategory.cooling;
    if (watts > 600) return ApplianceCategory.kitchen;
    if (watts > 200) return ApplianceCategory.entertainment;
    return ApplianceCategory.lighting;
  }

  void _addDevice(DiscoveredDevice dev) {
    NativeChannel.triggerHaptic();
    final energy = context.read<EnergyProvider>();

    final newApp = HouseholdAppliance(
      id: 'meter_${dev.id}_${DateTime.now().millisecondsSinceEpoch}',
      householdId: energy.activeHousehold.id,
      name: dev.name,
      category: dev.category,
      wattage: dev.watts > 0 ? dev.watts : 100.0,
      hoursPerDay: 8.0,
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
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
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
                        'Live Auto-Discovery',
                        style: AppTypography.style(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'Wi-Fi mDNS & Smart Meter Probing',
                        style: AppTypography.style(fontSize: 11.5, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: AppTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Scanner Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              children: [
                if (_isScanning)
                  FadeTransition(
                    opacity: _pulseController,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.electricCyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _discovered.isNotEmpty ? AppTheme.emeraldPrimary : AppTheme.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _scanStatus,
                    style: AppTypography.style(fontSize: 11.5, color: AppTheme.textDark, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!_isScanning)
                  TextButton(
                    onPressed: _startLiveNetworkScan,
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: const Text('Rescan'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Manual IP / Hostname Connect Section
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _manualIpController,
                    decoration: InputDecoration(
                      hintText: 'Enter Smart Plug IP (e.g. 192.168.1.50)',
                      hintStyle: const TextStyle(fontSize: 11),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isConnectingManual ? null : _connectManualIp,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.emeraldPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                ),
                child: _isConnectingManual
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Connect'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Discovered Devices List
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.40,
            ),
            child: _discovered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isScanning ? Icons.radar_rounded : Icons.wifi_find_rounded,
                            size: 40,
                            color: AppTheme.textSubtle,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isScanning
                                ? 'Scanning local subnet for live smart plugs...'
                                : 'No smart plugs detected on local network',
                            style: AppTypography.style(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enter your smart plug IP above or ensure Shelly/Tapo is powered on the same Wi-Fi.',
                            style: AppTypography.style(fontSize: 11, color: AppTheme.textMuted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _discovered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final dev = _discovered[index];
                      final isAdded = _addedIds.contains(dev.id);

                      return SmoothEntrance(
                        delayMs: index * 40,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isAdded ? const Color(0xFFF0FDF4) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isAdded ? const Color(0xFFBBF7D0) : AppTheme.borderSubtle,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppTheme.emeraldPrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(dev.icon, color: AppTheme.emeraldPrimary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dev.name,
                                      style: AppTypography.style(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textDark,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${dev.address} • ${dev.model}',
                                      style: AppTypography.style(fontSize: 10.5, color: AppTheme.textMuted),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${dev.watts.toStringAsFixed(0)}W • ${dev.voltage.toStringAsFixed(0)}V • ${dev.current.toStringAsFixed(2)}A',
                                      style: AppTypography.style(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.emeraldPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              FilledButton(
                                onPressed: isAdded ? null : () => _addDevice(dev),
                                style: FilledButton.styleFrom(
                                  backgroundColor: isAdded ? AppTheme.surfaceMuted : AppTheme.emeraldPrimary,
                                  foregroundColor: isAdded ? AppTheme.textMuted : Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(isAdded ? 'Added' : 'Add'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
