import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'screens/onboarding/login_screen.dart';
import 'state/console_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CompanionApp());
}

/// Holds the app's theme mode so any screen can toggle it via [ThemeScope].
class ThemeController extends ChangeNotifier {
  ThemeMode mode = ThemeMode.dark; // dark is the primary look
  void toggle() {
    mode = mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({super.key, required ThemeController controller, required super.child})
      : super(notifier: controller);
  static ThemeController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()!.notifier!;
}

class CompanionApp extends StatefulWidget {
  const CompanionApp({super.key});

  @override
  State<CompanionApp> createState() => _CompanionAppState();
}

class _CompanionAppState extends State<CompanionApp> {
  final ConsoleState _state = ConsoleState();
  final ThemeController _theme = ThemeController();

  @override
  void initState() {
    super.initState();
    _state.load();
  }

  @override
  void dispose() {
    _state.dispose();
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: _theme,
      child: AnimatedBuilder(
        animation: _theme,
        builder: (context, _) => MaterialApp(
          title: 'Health Companion',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _theme.mode,
          builder: (context, child) =>
              ConsoleScope(state: _state, child: child!),
          home: const _Root(),
        ),
      ),
    );
  }
}

/// Gates on data load, then shows the login/onboarding flow.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ConsoleScope.of(context);

    if (s.loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: c.critical, size: 40),
                const SizedBox(height: 12),
                Text('Could not load data',
                    style: TextStyle(
                        color: c.ink, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('${s.loadError}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.muted, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    if (s.loading) return const _Splash();
    return const LoginScreen();
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: c.heroGradient),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                      color: c.accent.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 10)),
                ],
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Companion Console',
                style: TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w800, color: c.ink)),
            const SizedBox(height: 6),
            Text('Loading sensor data & models…',
                style: TextStyle(fontSize: 13, color: c.muted)),
            const SizedBox(height: 20),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: c.accent),
            ),
          ],
        ),
      ),
    );
  }
}
