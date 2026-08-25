import 'package:flutter/material.dart';

/// Cool, modern health-app palette — deliberately distinct from the warm-paper
/// web dashboard. Slate surfaces, a teal→indigo accent pair, and vivid status
/// colors. Exposed as a [ThemeExtension] so any widget can read them via
/// `context.colors`.
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
    required this.accent2,
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
  final Color accent2;
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

  /// The signature hero gradient.
  List<Color> get heroGradient => [accent, accent2];

  static const light = AppColors(
    paper: Color(0xFFEEF2F7),
    panel: Color(0xFFFFFFFF),
    ink: Color(0xFF0F172A),
    muted: Color(0xFF64748B),
    faint: Color(0xFF94A3B8),
    line: Color(0xFFE2E8F0),
    lineStrong: Color(0xFFCBD5E1),
    accent: Color(0xFF0D9488),
    accent2: Color(0xFF4F46E5),
    accentInk: Color(0xFF0F766E),
    accentSoft: Color(0x1A0D9488),
    ok: Color(0xFF16A34A),
    okSoft: Color(0x1A16A34A),
    advisory: Color(0xFFD97706),
    advisorySoft: Color(0x1FD97706),
    warning: Color(0xFFEA580C),
    warningSoft: Color(0x1FEA580C),
    critical: Color(0xFFDC2626),
    criticalSoft: Color(0x1FDC2626),
    tempTrace: Color(0xFF9333EA),
    onAccent: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    paper: Color(0xFF0A0F1C),
    panel: Color(0xFF141B2B),
    ink: Color(0xFFE7ECF3),
    muted: Color(0xFF94A3B8),
    faint: Color(0xFF64748B),
    line: Color(0xFF1F2937),
    lineStrong: Color(0xFF334155),
    accent: Color(0xFF2DD4BF),
    accent2: Color(0xFF818CF8),
    accentInk: Color(0xFF99F6E4),
    accentSoft: Color(0x212DD4BF),
    ok: Color(0xFF4ADE80),
    okSoft: Color(0x214ADE80),
    advisory: Color(0xFFFBBF24),
    advisorySoft: Color(0x21FBBF24),
    warning: Color(0xFFFB923C),
    warningSoft: Color(0x21FB923C),
    critical: Color(0xFFF87171),
    criticalSoft: Color(0x21F87171),
    tempTrace: Color(0xFFC084FC),
    onAccent: Color(0xFF06231F),
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
    Color? accent2,
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
      accent2: accent2 ?? this.accent2,
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
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      paper: l(paper, other.paper),
      panel: l(panel, other.panel),
      ink: l(ink, other.ink),
      muted: l(muted, other.muted),
      faint: l(faint, other.faint),
      line: l(line, other.line),
      lineStrong: l(lineStrong, other.lineStrong),
      accent: l(accent, other.accent),
      accent2: l(accent2, other.accent2),
      accentInk: l(accentInk, other.accentInk),
      accentSoft: l(accentSoft, other.accentSoft),
      ok: l(ok, other.ok),
      okSoft: l(okSoft, other.okSoft),
      advisory: l(advisory, other.advisory),
      advisorySoft: l(advisorySoft, other.advisorySoft),
      warning: l(warning, other.warning),
      warningSoft: l(warningSoft, other.warningSoft),
      critical: l(critical, other.critical),
      criticalSoft: l(criticalSoft, other.criticalSoft),
      tempTrace: l(tempTrace, other.tempTrace),
      onAccent: l(onAccent, other.onAccent),
    );
  }
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
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.panel,
        indicatorColor: c.accentSoft,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected) ? c.accent : c.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? c.accent : c.muted,
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme => _base(Brightness.light, AppColors.light);
  static ThemeData get darkTheme => _base(Brightness.dark, AppColors.dark);
}

/// Monospace stack for numeric readouts (resolves to the platform mono face).
const String kMonoFamily = 'monospace';
const List<String> kMonoFallback = <String>[
  'RobotoMono',
  'Menlo',
  'Consolas',
  'Courier New',
  'monospace',
];

const List<FontFeature> kTabularFigures = <FontFeature>[
  FontFeature.tabularFigures(),
];
