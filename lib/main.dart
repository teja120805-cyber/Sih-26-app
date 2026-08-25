import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'console_page.dart';
import 'state/console_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CompanionApp());
}

class CompanionApp extends StatefulWidget {
  const CompanionApp({super.key});

  @override
  State<CompanionApp> createState() => _CompanionAppState();
}

class _CompanionAppState extends State<CompanionApp> {
  final ConsoleState _state = ConsoleState();
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _state.load();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    final platformDark =
        MediaQuery.maybeOf(context)?.platformBrightness == Brightness.dark;
    setState(() {
      _themeMode = switch (_themeMode) {
        ThemeMode.system => platformDark ? ThemeMode.light : ThemeMode.dark,
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.light,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Companion Console',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: ConsoleScope(
          state: _state,
          child: ConsolePage(
            themeMode: _themeMode,
            onToggleTheme: _toggleTheme,
          ),
        ),
      ),
    );
  }
}
