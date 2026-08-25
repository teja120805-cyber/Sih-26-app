import 'package:flutter/material.dart';

/// Semantic colors ported verbatim from the Companion Console web dashboard
/// (`dashboard/index.html` `:root` custom properties). Exposed as a
/// [ThemeExtension] so any widget can read them via `Theme.of(context).colors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.paper,
    required this.panel,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.line,
    required this.lineStrong,
    required this.accent,
    required this.accentInk,
    required this.accentSoft,
    required this.ok,
    required this.okSoft,
    required this.advisory,
    required this.advisorySoft,
    required this.warning,
    required this.warningSoft,
    required this.critical,
    required this.criticalSoft,
    required this.tempTrace,
    required this.onAccent,
  });

  final Color paper;
  final Color panel;
  final Color ink;
  final Color muted;
  final Color faint;
  final Color line;
  final Color lineStrong;
  final Color accent;
  final Color accentInk;
  final Color accentSoft;
  final Color ok;
  final Color okSoft;
  final Color advisory;
  final Color advisorySoft;
  final Color warning;
  final Color warningSoft;
  final Color critical;
  final Color criticalSoft;
  final Color tempTrace;
  final Color onAccent;

  /// Map a severity tier (0=ok .. 3=critical) to its color.
  Color tier(int t) => switch (t) {
        >= 3 => critical,
        2 => warning,
        1 => advisory,
        _ => ok,
      };

  Color tierSoft(int t) => switch (t) {
        >= 3 => criticalSoft,
        2 => warningSoft,
        1 => advisorySoft,
        _ => okSoft,
      };

  static const light = AppColors(
    paper: Color(0xFFF6F3EE),
    panel: Color(0xFFFBF9F5),
    ink: Color(0xFF1B1F23),
    muted: Color(0xFF6B6459),
    faint: Color(0xFF8C8478),
    line: Color(0xFFDCD5C9),
    lineStrong: Color(0xFFC7BEAF),
    accent: Color(0xFF1E6E68),
    accentInk: Color(0xFF0E3E3A),
    accentSoft: Color(0x1A1E6E68),
    ok: Color(0xFF3B7A4A),
    okSoft: Color(0x1F3B7A4A),
    advisory: Color(0xFFA9781F),
    advisorySoft: Color(0x24A9781F),
    warning: Color(0xFFB85A1E),
    warningSoft: Color(0x24B85A1E),
    critical: Color(0xFFAC3327),
    criticalSoft: Color(0x21AC3327),
    tempTrace: Color(0xFF8A6D3F),
    onAccent: Color(0xFFF6F3EE),
  );

  static const dark = AppColors(
    paper: Color(0xFF0F1215),
    panel: Color(0xFF171B20),
    ink: Color(0xFFECE7DC),
    muted: Color(0xFF9B9488),
    faint: Color(0xFF726C61),
    line: Color(0xFF2A2E33),
    lineStrong: Color(0xFF383D44),
    accent: Color(0xFF4FBDB2),
    accentInk: Color(0xFFBEEFE9),
    accentSoft: Color(0x214FBDB2),
    ok: Color(0xFF67AC72),
    okSoft: Color(0x2467AC72),
    advisory: Color(0xFFD9A544),
    advisorySoft: Color(0x24D9A544),
    warning: Color(0xFFE0813F),
    warningSoft: Color(0x24E0813F),
    critical: Color(0xFFE1685A),
    criticalSoft: Color(0x26E1685A),
    tempTrace: Color(0xFFC6A96E),
    onAccent: Color(0xFF0E1A18),
  );

  @override
  AppColors copyWith({
    Color? paper,
    Color? panel,
    Color? ink,
    Color? muted,
    Color? faint,
    Color? line,
    Color? lineStrong,
    Color? accent,
    Color? accentInk,
    Color? accentSoft,
    Color? ok,
    Color? okSoft,
    Color? advisory,
    Color? advisorySoft,
    Color? warning,
    Color? warningSoft,
    Color? critical,
    Color? criticalSoft,
    Color? tempTrace,
    Color? onAccent,
  }) {
    return AppColors(
      paper: paper ?? this.paper,
      panel: panel ?? this.panel,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      accentSoft: accentSoft ?? this.accentSoft,
      ok: ok ?? this.ok,
      okSoft: okSoft ?? this.okSoft,
      advisory: advisory ?? this.advisory,
      advisorySoft: advisorySoft ?? this.advisorySoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      critical: critical ?? this.critical,
      criticalSoft: criticalSoft ?? this.criticalSoft,
      tempTrace: tempTrace ?? this.tempTrace,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      paper: Color.lerp(paper, other.paper, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      faint: Color.lerp(faint, other.faint, t)!,
      line: Color.lerp(line, other.line, t)!,
      lineStrong: Color.lerp(lineStrong, other.lineStrong, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      ok: Color.lerp(ok, other.ok, t)!,
      okSoft: Color.lerp(okSoft, other.okSoft, t)!,
      advisory: Color.lerp(advisory, other.advisory, t)!,
      advisorySoft: Color.lerp(advisorySoft, other.advisorySoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      critical: Color.lerp(critical, other.critical, t)!,
      criticalSoft: Color.lerp(criticalSoft, other.criticalSoft, t)!,
      tempTrace: Color.lerp(tempTrace, other.tempTrace, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}

/// Convenience accessor: `Theme.of(context).colors`.
extension AppColorsX on ThemeData {
  AppColors get colors => extension<AppColors>()!;
}

extension AppColorsContextX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

class AppTheme {
  static ThemeData _base(Brightness brightness, AppColors c) {
    final scheme = ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: brightness,
    ).copyWith(
      surface: c.panel,
      primary: c.accent,
      onPrimary: c.onAccent,
    );

    final baseText = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;
    final textTheme = baseText.apply(bodyColor: c.ink, displayColor: c.ink);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.paper,
      canvasColor: c.paper,
      textTheme: textTheme,
      extensions: [c],
      dividerColor: c.line,
      splashFactory: InkSparkle.splashFactory,
    );
  }

  static ThemeData get lightTheme => _base(Brightness.light, AppColors.light);
  static ThemeData get darkTheme => _base(Brightness.dark, AppColors.dark);
}

/// Monospace font stack for numeric readouts (matches the web's IBM Plex Mono).
/// Not bundled — resolves to the platform monospace face, falling back safely.
const String kMonoFamily = 'monospace';
const List<String> kMonoFallback = <String>[
  'RobotoMono',
  'Menlo',
  'Consolas',
  'Courier New',
  'monospace',
];

/// Enable tabular (fixed-width) figures so numeric readouts don't jitter.
const List<FontFeature> kTabularFigures = <FontFeature>[
  FontFeature.tabularFigures(),
];
