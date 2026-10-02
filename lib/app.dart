import 'package:flutter/material.dart';
import 'package:finance/screens/main_scaffold.dart';
import 'package:finance/state/app_state.dart';
import 'package:finance/utils/app_theme.dart';

class FinanceTrackerApp extends StatefulWidget {
  const FinanceTrackerApp({super.key});

  @override
  State<FinanceTrackerApp> createState() => _FinanceTrackerAppState();
}

class _FinanceTrackerAppState extends State<FinanceTrackerApp> {
  @override
  void initState() {
    super.initState();
    // Rebuild app when AppState notifies (e.g., theme change)
    AppState.instance.addListener(_onStateChange);
  }

  void _onStateChange() => setState(() {});

  @override
  void dispose() {
    AppState.instance.removeListener(_onStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return MaterialApp(
      title: 'Finance Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const MainScaffold(),
    );
  }
}
