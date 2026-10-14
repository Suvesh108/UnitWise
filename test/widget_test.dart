import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:unitwise/data/repositories/energy_repository.dart';
import 'package:unitwise/providers/energy_provider.dart';
import 'package:unitwise/providers/settings_provider.dart';
import 'package:unitwise/core/native/native_channel.dart';
import 'package:unitwise/ui/widgets/floating_onboarding_card.dart';
import 'package:unitwise/main.dart';

void main() {
  testWidgets('UnitWise dashboard smoke test, clean slate, and floating onboarding flow', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = await EnergyRepository.init();
    final energyProvider = EnergyProvider(repo);
    final settingsProvider = SettingsProvider(prefs);

    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: energyProvider),
          ChangeNotifierProvider.value(value: settingsProvider),
        ],
        child: const UnitWiseApp(),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Clean Slate: 0 appliances pre-seeded
    expect(energyProvider.currentAppliances.length, 0);
    expect(energyProvider.consumptionSummary.totalMonthlyKwh, 0.0);

    // 2. Verify Floating Onboarding Card is mounted for first-time user
    expect(find.byType(FloatingOnboardingCard), findsOneWidget);
    expect(find.text('WELCOME TO UNITWISE'), findsOneWidget);
    expect(find.text('Your Clean Slate'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FloatingOnboardingCard),
        matching: find.text('Add Appliance'),
      ),
      findsOneWidget,
    );
    expect(find.text('Explore'), findsOneWidget);

    // 3. Dismiss onboarding by tapping Explore
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();

    // Verify Onboarding Card is dismissed and marked complete
    expect(settingsProvider.hasCompletedOnboarding, true);
    expect(find.byType(FloatingOnboardingCard), findsNothing);

    // 4. Verify Dashboard displays clean slate with zero errors
    expect(find.textContaining('MONTHLY CONSUMPTION'), findsOneWidget);
    expect(find.text('ESTIMATED BILL'), findsOneWidget);
    expect(find.text('TOP ENERGY CONSUMERS'), findsOneWidget);
    expect(find.text('No appliances added yet.'), findsOneWidget);
  });

  test('NativeChannel update check delivers internal OTA metadata', () async {
    final update = await NativeChannel.checkForUpdate();
    expect(update.hasUpdate, true);
    expect(update.latestVersion, isNotEmpty);
    expect(update.downloadUrl, isNotEmpty);
    expect(update.fileSizeMb, greaterThan(0));
    expect(update.releaseNotes, isNotEmpty);
  });
}
