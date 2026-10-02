import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:finance/app.dart';
import 'package:finance/state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    // TransactionService.init() is called INSIDE AppState.init().
    // The order is:
    //   1. Hive.initFlutter() + openBox  (TransactionService)
    //   2. SharedPreferences load        (profile, settings, budgets)
    //   3. _refreshTransactions()        (reads from open box)
    await AppState.instance.init();
  } catch (e, st) {
    debugPrint('App init failed: $e\n$st');
    runApp(_ErrorApp(error: e.toString()));
    return;
  }

  runApp(const FinanceTrackerApp());
}

class _ErrorApp extends StatelessWidget {
  final String error;
  const _ErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _ErrorScreen(error: error),
    );
  }
}

class _ErrorScreen extends StatefulWidget {
  final String error;
  const _ErrorScreen({required this.error});

  @override
  State<_ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<_ErrorScreen> {
  bool _retrying = false;
  String? _retryError;

  Future<void> _retry() async {
    setState(() {
      _retrying = true;
      _retryError = null;
    });
    try {
      await AppState.instance.init();
      if (mounted) {
        // Replace the error app with the real app
        runApp(const FinanceTrackerApp());
      }
    } catch (e) {
      setState(() {
        _retrying = false;
        _retryError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 72, color: Color(0xFFEF4444)),
              const SizedBox(height: 16),
              const Text(
                'Failed to initialise storage',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _retryError ?? widget.error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 24),
              _retrying
                  ? const CircularProgressIndicator()
                  : FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
