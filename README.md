# UnitWise ⚡☀️

**Smart Household Electricity Calculator & Rooftop Solar Sizing Platform**

UnitWise is a practical Flutter & Kotlin cross-platform application that calculates household electricity consumption, estimates monthly bills with tiered slab tariffs, and models real-time rooftop solar generation and net energy balance.

---

## 🌟 Key Features (v0.0.1)

### 1. Clean-Slate Appliance Management
- **Zero Pre-Seeded Boilerplate**: Every household begins with a clean slate for true personalization.
- **Floating Onboarding Guide**: Interactive, animated glassmorphic modal introducing the 3 core pillars.
- **Rich Appliance Catalogue**: Pre-configured categories (Cooling, Kitchen, Lighting, Laundry, Entertainment, Water Pumps) with continuous, duty-cycle (refrigerators, inverter ACs), and per-cycle (washing machines) consumption patterns.
- **Custom Appliance Wizard**: Add non-standard equipment with user-defined wattages and duty cycles.

### 2. Tiered Slab Bill Estimator
- **Tiered Electricity Tariffs**: Accurate cumulative slab calculators (e.g. 0–100, 100–200, 200–400+ kWh units).
- **DISCOM Charges**: Fixed meter charges, fuel surcharges (FPPPA), and state electricity taxes.
- **Variance Diagnosis**: Compare your estimated load against actual electricity bills to detect unmetered standby power and phantom loads.

### 3. Rooftop Solar & Net Energy Balance
- **Live Net Metering Flow**: Real-time subtraction of household consumption from solar generation:
  $$\text{Net Grid Balance (kWh)} = \text{Solar Generation (kWh)} - \text{Household Consumption (kWh)}$$
- **Inverter Electrical Specs**: Direct Volts ($V$) $\times$ Amps ($A$) calculation mode or monthly kWh generation overrides.
- **Financial Audit**: Gross savings, utility export feed-in credits, net payable bill, and payback estimation with panel degradation modeling.

### 4. Native Kotlin OTA Updater
- **100% In-App Package Engine**: Checks, downloads, and invokes Android package installer internally via native Kotlin platform channels.
- **Zero Browser Redirection**: Downloads directly to app cache without opening Chrome or external browsers.
- **`FileProvider` Secure Installation**: Fully compliant with Android 14 (API 34) package installation guidelines.

---

## 🏗️ Architecture & Tech Stack

- **Framework**: Flutter 3.29+ / Dart 3.7+
- **Platform Engine**: Native Kotlin (`MainActivity.kt`, `FileProvider`, `BatteryManager`, `MethodChannel`)
- **State Management**: `provider` (MultiProvider with reactive ChangeNotifier)
- **Local Storage**: `shared_preferences` (Offline-first key-value persistence)
- **Design System**: Luminous Minimalist Theme, Plus Jakarta Sans typography, WCAG 2.2 compliant contrast
- **Reporting**: Native PDF generator (`pdf`, `printing`) with exportable audit logs

---

## 🚀 Building & Testing

### Run Tests
```bash
flutter test
```

### Run Static Analysis
```bash
flutter analyze
```

### Build Web Release
```bash
flutter build web --base-href /
```

### Build Android APK
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

---

## 📄 License
MIT License. Crafted for resilient offline home energy management.
