import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance/screens/main_scaffold.dart';
import 'package:finance/utils/app_theme.dart';

class FinanceTrackerApp extends StatefulWidget {
  const FinanceTrackerApp({super.key});

  @override
  State<FinanceTrackerApp> createState() => _FinanceTrackerAppState();
}

class _FinanceTrackerAppState extends State<FinanceTrackerApp> {
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDark = prefs.getBool('dark_mode') ?? false);
  }

  Future<void> _toggleTheme(bool val) async {
    setState(() => _isDark = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', val);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: MainScaffold(
        isDarkMode: _isDark,
        onThemeToggle: _toggleTheme,
      ),
    );
  }
}
