import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import 'package:provider/provider.dart';
import '../../data/catalogue/default_appliances.dart';
import '../../data/models/appliance_template.dart';
import '../../data/models/household_appliance.dart';
import '../../domain/energy_calculator.dart';
import '../../providers/energy_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/native/native_channel.dart';
import 'edit_appliance_bottom_sheet.dart';
import 'add_appliance_dialog.dart';
import 'auto_detect_dialog.dart';

class AppliancesScreen extends StatefulWidget {
  const AppliancesScreen({super.key});

  @override
  State<AppliancesScreen> createState() => _AppliancesScreenState();
}

class _AppliancesScreenState extends State<AppliancesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ApplianceCategory? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final energy = context.watch<EnergyProvider>();
    final settings = context.watch<SettingsProvider>();
    final myAppliances = energy.currentAppliances;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        title: Text(
          'Appliances',
          style: AppTypography.style(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Auto-Detect Appliances (Wi-Fi/BLE)',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.electricCyan.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.electricCyan.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.radar_rounded, size: 18, color: AppTheme.electricCyan),
            ),
            onPressed: () => AutoDetectDialog.show(context),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Add Custom Appliance',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: const Icon(Icons.add, size: 18, color: AppTheme.textDark),
            ),
            onPressed: () => AddCustomApplianceDialog.show(context),
          ),
          const SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 40,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                labelColor: AppTheme.textDark,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: AppTypography.style(fontSize: 12.5, fontWeight: FontWeight.w700),
                unselectedLabelStyle: AppTypography.style(fontSize: 12.5, fontWeight: FontWeight.w500),
                tabs: [
                  Tab(text: 'Catalogue (${DefaultAppliances.list.length})'),
                  Tab(text: 'My Household (${myAppliances.length})'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Search & Category Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search appliances (AC, fridge, fans, pumps)...',
                    prefixIcon: const Icon(Icons.search, size: 19, color: AppTheme.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip(null, 'All', Icons.apps_outlined),
                      const SizedBox(width: 6),
                      ...ApplianceCategory.values.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _buildCategoryChip(
                            cat,
                            Formatters.getCategoryName(cat),
                            Formatters.getCategoryIcon(cat),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCatalogueTab(context, energy, settings),
                _buildMyAppliancesTab(context, energy, settings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(ApplianceCategory? cat, String label, IconData icon) {
    final isSelected = _selectedCategory == cat;
    return InkWell(
      onTap: () {
        NativeChannel.triggerHaptic();
        setState(() => _selectedCategory = isSelected ? null : cat);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.emeraldPrimary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.emeraldPrimary : AppTheme.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.style(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogueTab(
    BuildContext context,
    EnergyProvider energy,
    SettingsProvider settings,
  ) {
    var items = DefaultAppliances.list;

    if (_selectedCategory != null) {
      items = items.where((i) => i.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      items = items
          .where((i) =>
              i.name.toLowerCase().contains(_searchQuery) ||
              i.description.toLowerCase().contains(_searchQuery))
          .toList();
    }

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No matching appliances found in catalogue.',
          style: AppTypography.style(color: AppTheme.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, idx) {
        final template = items[idx];
        final catColor = Formatters.getCategoryColor(template.category);

        final existingCount = energy.currentAppliances
            .where((a) => a.templateId == template.id)
            .fold(0, (sum, a) => sum + a.quantity);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(Formatters.getCategoryIcon(template.category), color: catColor, size: 20),
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
                            template.name,
                            style: AppTypography.style(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        if (existingCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.emeraldPrimary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$existingCount added',
                              style: AppTypography.style(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.emeraldPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      template.description,
                      style: AppTypography.style(
                        fontSize: 11.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildBadge('${template.defaultWatts.toStringAsFixed(0)}W', Icons.bolt, Colors.amber.shade800),
                        if (template.calculationType == CalculationType.dutyCycle)
                          _buildBadge(
                            '${(template.defaultDutyCycle * 100).toStringAsFixed(0)}% Inverter Duty',
                            Icons.sync,
                            AppTheme.electricCyan,
                          )
                        else if (template.calculationType == CalculationType.perCycle)
                          _buildBadge(
                            '${template.defaultKwhPerCycle} kWh/cycle',
                            Icons.repeat,
                            Colors.purple,
                          )
                        else
                          _buildBadge('Continuous', Icons.power, AppTheme.emeraldPrimary),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () {
                  NativeChannel.triggerHaptic();
                  final newApp = HouseholdAppliance(
                    id: 'app_${DateTime.now().millisecondsSinceEpoch}_${template.id}',
                    householdId: energy.activeHousehold.id,
                    templateId: template.id,
                    name: template.name,
                    category: template.category,
                    calculationType: template.calculationType,
                    quantity: 1,
                    wattage: template.defaultWatts,
                    dutyCycle: template.defaultDutyCycle,
                    kwhPerCycle: template.defaultKwhPerCycle,
                    hoursPerDay: template.defaultHoursPerDay,
                    daysPerMonth: template.defaultDaysPerMonth,
                    cyclesPerMonth: template.defaultCyclesPerMonth,
                  );
                  EditApplianceBottomSheet.show(context, appliance: newApp, isNew: true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.emeraldPrimary,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyAppliancesTab(
    BuildContext context,
    EnergyProvider energy,
    SettingsProvider settings,
  ) {
    var items = energy.currentAppliances;

    if (_selectedCategory != null) {
      items = items.where((i) => i.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      items = items.where((i) => i.name.toLowerCase().contains(_searchQuery)).toList();
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.devices_outlined, size: 44, color: AppTheme.textSubtle),
            const SizedBox(height: 12),
            Text(
              'No appliances in this household yet.',
              style: AppTypography.style(
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text('Browse Catalogue'),
            ),
          ],
        ),
      );
    }

    final rate = energy.billResult.effectiveRatePerKwh > 0
        ? energy.billResult.effectiveRatePerKwh
        : energy.tariff.flatRatePerKwh;
    final balance = energy.netEnergyBalance;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length + 1,
      itemBuilder: (context, idx) {
        if (idx == 0) {
          // Top Net Energy Balance Header Pill
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: balance.isSurplus ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: balance.isSurplus ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  balance.isSurplus ? Icons.wb_sunny_rounded : Icons.info_outline,
                  size: 16,
                  color: balance.isSurplus ? AppTheme.emeraldPrimary : AppTheme.solarGold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    balance.isSurplus
                        ? 'Solar Generation covers all appliances (+${balance.netBalanceKwh.toStringAsFixed(0)} kWh surplus units)'
                        : 'Solar offsets ${balance.offsetPercentage.toStringAsFixed(0)}% of home load (${balance.gridImportKwh.toStringAsFixed(0)} kWh needed from grid)',
                    style: AppTypography.style(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: balance.isSurplus ? AppTheme.emeraldPrimary : AppTheme.solarGold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final app = items[idx - 1];
        final catColor = Formatters.getCategoryColor(app.category);
        final monthlyKwh = EnergyCalculator.calculateApplianceMonthlyKwh(
          app,
          monthDays: energy.activeHousehold.daysInMonth,
        );
        final cost = monthlyKwh * rate;
        final solarShare = energy.getApplianceSolarShare(app);
        final isCovered = energy.isApplianceSolarCovered(app);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => EditApplianceBottomSheet.show(context, appliance: app, isNew: false),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(Formatters.getCategoryIcon(app.category), color: catColor, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.name,
                                style: AppTypography.style(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                app.calculationType == CalculationType.perCycle
                                    ? '${app.cyclesPerMonth} washes/mo • ${app.kwhPerCycle} kWh/cycle'
                                    : '${app.wattage.toStringAsFixed(0)}W • ${app.hoursPerDay.toStringAsFixed(1)} hrs/day',
                                style: AppTypography.style(
                                  fontSize: 11.5,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Solar Share Tag
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isCovered ? AppTheme.emeraldPrimary : AppTheme.solarGold).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (isCovered ? AppTheme.emeraldPrimary : AppTheme.solarGold).withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  isCovered
                                      ? '⚡ 100% Solar-Powered (${solarShare.toStringAsFixed(0)}% load)'
                                      : '☀️ Draws ${solarShare.toStringAsFixed(0)}% Solar Yield',
                                  style: AppTypography.style(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isCovered ? AppTheme.emeraldPrimary : AppTheme.solarGold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${monthlyKwh.toStringAsFixed(1)} kWh',
                              style: AppTypography.style(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Text(
                              '~${Formatters.formatCurrency(cost, symbol: settings.currency)}/mo',
                              style: AppTypography.style(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 6),
                    // Minimalist Stepper & Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Qty: ',
                              style: AppTypography.style(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            InkWell(
                              onTap: app.quantity > 1
                                  ? () {
                                      NativeChannel.triggerHaptic();
                                      energy.updateAppliance(app.copyWith(quantity: app.quantity - 1));
                                    }
                                  : () {
                                      NativeChannel.triggerHaptic();
                                      energy.deleteAppliance(app.id);
                                    },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: const Icon(Icons.remove, size: 14, color: AppTheme.textDark),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                '${app.quantity}',
                                style: AppTypography.style(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                NativeChannel.triggerHaptic();
                                energy.updateAppliance(app.copyWith(quantity: app.quantity + 1));
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: const Icon(Icons.add, size: 14, color: AppTheme.textDark),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Duplicate',
                              icon: const Icon(Icons.copy_outlined, size: 17, color: AppTheme.textMuted),
                              onPressed: () {
                                NativeChannel.triggerHaptic();
                                energy.duplicateAppliance(app);
                              },
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Configure',
                              icon: const Icon(Icons.tune_outlined, size: 17, color: AppTheme.textMuted),
                              onPressed: () => EditApplianceBottomSheet.show(context, appliance: app, isNew: false),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline, size: 17, color: AppTheme.alertCoral),
                              onPressed: () {
                                NativeChannel.triggerHaptic();
                                energy.deleteAppliance(app.id);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTypography.style(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
