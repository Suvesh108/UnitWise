import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/repositories/energy_repository.dart';
import 'providers/energy_provider.dart';
import 'providers/settings_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/native/native_channel.dart';
import 'ui/navigation/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  NativeChannel.initialize();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize offline-first repositories
  final prefs = await SharedPreferences.getInstance();
  final repository = await EnergyRepository.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EnergyProvider(repository)),
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
      ],
      child: const UnitWiseApp(),
    ),
  );
}

class UnitWiseApp extends StatelessWidget {
  const UnitWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'UnitWise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      home: const MainScreen(),
    );
  }
}
