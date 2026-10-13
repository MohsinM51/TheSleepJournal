import 'package:flutter/material.dart';

/// Semantic colour set for the whole app. Implemented as a ThemeExtension so
/// that MaterialApp's AnimatedTheme smoothly interpolates every colour when the
/// user toggles light/dark (each field is lerped frame-by-frame).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Brightness brightness;
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color textPrimary;
  final Color textSecondary;
  final Color textFaint;
  final Color divider; // subtle internal hairlines
  final Color outline; // element borders (cards, pills, toggles, island)
  final Color green; // slept during goal / positive
  final Color greenSoft; // smiley & soft fills
  final Color red; // awake during goal
  final Color amber; // slept outside goal
  final Color sleepBg;
  final Color sleepFg;
  final Color wakeBg;
  final Color wakeFg;
  final Color island;
  final Color islandIcon;
  final Color chartLine;
  final Color accent; // sleep-time graph line/fill
  final List<Color> qualityBands; // low->high score ramp (length 5)
  final Color noData;
  final Color shadow;

  const AppPalette({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.textFaint,
    required this.divider,
    required this.outline,
    required this.green,
    required this.greenSoft,
    required this.red,
    required this.amber,
    required this.sleepBg,
    required this.sleepFg,
    required this.wakeBg,
    required this.wakeFg,
    required this.island,
    required this.islandIcon,
    required this.chartLine,
    required this.accent,
    required this.qualityBands,
    required this.noData,
    required this.shadow,
  });

  static const light = AppPalette(
    brightness: Brightness.light,
    bg: Color(0xFFF1EEE8),
    surface: Color(0xFFFAF8F3),
    surfaceAlt: Color(0xFFEAE6DD),
    textPrimary: Color(0xFF1C1B19),
    textSecondary: Color(0xFF6E6C66),
    textFaint: Color(0xFFA9A69E),
    divider: Color(0xFFE8E3DA),
    outline: Color(0xFF35332F),
    green: Color(0xFF7DAE66),
    greenSoft: Color(0xFFC6DAA4),
    red: Color(0xFFCF6E5F),
    amber: Color(0xFFDFA85F),
    sleepBg: Color(0xFFE3DED3),
    sleepFg: Color(0xFF2A2925),
    wakeBg: Color(0xFFEFEBE2),
    wakeFg: Color(0xFF8A5E27),
    island: Color(0xFF1A1917),
    islandIcon: Color(0xFFF4F1EA),
    chartLine: Color(0xFF26241F),
    accent: Color(0xFF7DAE66),
    qualityBands: [
      Color(0xFFD08A78), // very poor — clay red
      Color(0xFFDDA86B), // poor — warm orange
      Color(0xFFD9C56F), // average — gold
      Color(0xFFA8C77E), // good — sage
      Color(0xFF6FA152), // excellent — green
    ],
    noData: Color(0xFFE8E5DE),
    shadow: Color(0x14000000),
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF0E0F11),
    surface: Color(0xFF17191C),
    surfaceAlt: Color(0xFF202327),
    textPrimary: Color(0xFFF1EFEA),
    textSecondary: Color(0xFF9B9DA0),
    textFaint: Color(0xFF67696D),
    divider: Color(0xFF26292D),
    outline: Color(0xFFCDD0D4),
    green: Color(0xFF86C079),
    greenSoft: Color(0xFF7FB86E),
    red: Color(0xFFD2695C),
    amber: Color(0xFFE0A65B),
    sleepBg: Color(0xFF1E2125),
    sleepFg: Color(0xFFF1EFEA),
    wakeBg: Color(0xFF2B2E33),
    wakeFg: Color(0xFFE9B681),
    island: Color(0xFF1C1E21),
    islandIcon: Color(0xFFF1EFEA),
    chartLine: Color(0xFFEDEBE6),
    accent: Color(0xFF86C079),
    qualityBands: [
      Color(0xFFA1564A), // very poor — clay red
      Color(0xFFAB7740), // poor — warm orange
      Color(0xFF9C8A3B), // average — gold
      Color(0xFF5F8B43), // good — green
      Color(0xFF79AE4D), // excellent — bright green
    ],
    noData: Color(0xFF202225),
    shadow: Color(0x66000000),
  );

  /// Quality band colour for a composite score in 1..5.
  Color bandForScore(double score5) {
    if (score5 >= 4.5) return qualityBands[4];
    if (score5 >= 3.5) return qualityBands[3];
    if (score5 >= 2.5) return qualityBands[2];
    if (score5 >= 1.5) return qualityBands[1];
    return qualityBands[0];
  }

  @override
  AppPalette copyWith({Brightness? brightness}) => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      bg: c(bg, other.bg),
      surface: c(surface, other.surface),
      surfaceAlt: c(surfaceAlt, other.surfaceAlt),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textFaint: c(textFaint, other.textFaint),
      divider: c(divider, other.divider),
      outline: c(outline, other.outline),
      green: c(green, other.green),
      greenSoft: c(greenSoft, other.greenSoft),
      red: c(red, other.red),
      amber: c(amber, other.amber),
      sleepBg: c(sleepBg, other.sleepBg),
      sleepFg: c(sleepFg, other.sleepFg),
      wakeBg: c(wakeBg, other.wakeBg),
      wakeFg: c(wakeFg, other.wakeFg),
      island: c(island, other.island),
      islandIcon: c(islandIcon, other.islandIcon),
      chartLine: c(chartLine, other.chartLine),
      accent: c(accent, other.accent),
      qualityBands: [
        for (var i = 0; i < qualityBands.length; i++)
          c(qualityBands[i], other.qualityBands[i]),
      ],
      noData: c(noData, other.noData),
      shadow: c(shadow, other.shadow),
    );
  }
}

extension PaletteContext on BuildContext {
  AppPalette get pal => Theme.of(this).extension<AppPalette>()!;
}

/// Typography — Satoshi (bundled) for body/UI, Oswald (tall, condensed) for the
/// greeting, clock and page headings.
class AppText {
  static TextStyle _sat(double size, FontWeight w, Color c, {double? h, double? ls}) =>
      TextStyle(
          fontFamily: 'Satoshi', fontSize: size, fontWeight: w, color: c, height: h, letterSpacing: ls);
  static TextStyle _osw(double size, FontWeight w, Color c, {double? h, double? ls}) =>
      TextStyle(
          fontFamily: 'Oswald', fontSize: size, fontWeight: w, color: c, height: h, letterSpacing: ls);

  static TextStyle clock(Color c) => _osw(58, FontWeight.w300, c, h: 1.0, ls: 0.5);
  static TextStyle clockPeriod(Color c) => _osw(17, FontWeight.w400, c, ls: 0.5);
  static TextStyle greeting(Color c) => _osw(34, FontWeight.w300, c, h: 1.04, ls: 0.3);
  static TextStyle heading(Color c) => _osw(42, FontWeight.w400, c, h: 1.0, ls: 0.4);
  static TextStyle statNumber(Color c) => _sat(46, FontWeight.w300, c, h: 1.0, ls: -1.2);
  static TextStyle pillTime(Color c) => _sat(30, FontWeight.w400, c, h: 1.0, ls: -0.5);
  static TextStyle pillPeriod(Color c) => _sat(13, FontWeight.w500, c, ls: 0.3);
  static TextStyle cardTitle(Color c) => _sat(15.5, FontWeight.w500, c, ls: -0.1);
  static TextStyle sectionLabel(Color c) => _sat(13, FontWeight.w500, c, ls: 0.2);
  static TextStyle label(Color c) => _sat(13.5, FontWeight.w500, c);
  static TextStyle body(Color c) => _sat(14, FontWeight.w400, c, h: 1.4);
  static TextStyle tiny(Color c) => _sat(11, FontWeight.w500, c, ls: 0.3);
  static TextStyle axis(Color c) => _sat(11, FontWeight.w400, c, ls: 0.2);
  static TextStyle button(Color c) => _sat(15.5, FontWeight.w500, c, ls: 0.2);
}

ThemeData buildTheme(AppPalette p) {
  final base = p.brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();
  final textTheme = base.textTheme
      .apply(fontFamily: 'Satoshi', bodyColor: p.textPrimary, displayColor: p.textPrimary);
  return base.copyWith(
    brightness: p.brightness,
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.bg,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    textTheme: textTheme,
    extensions: [p],
    colorScheme: base.colorScheme.copyWith(
      brightness: p.brightness,
      surface: p.surface,
      primary: p.green,
      secondary: p.amber,
    ),
    dividerColor: p.divider,
    timePickerTheme: TimePickerThemeData(
      backgroundColor: p.surface,
      hourMinuteTextColor: p.textPrimary,
      dialBackgroundColor: p.surfaceAlt,
      dialHandColor: p.green,
    ),
  );
}

/// Spacing & radius tokens for a consistent, generous, minimal layout.
class Gap {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 30;
  static const double screen = 22;
  static const double cardRadius = 26;
  static const double cardPad = 20;
}
