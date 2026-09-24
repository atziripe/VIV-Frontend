import 'package:flutter/material.dart';

/// Raw palette, named after the Figma variables in the VIVFEM file
/// (e.g. `color/red/42` = "Cannon Pink"). Screens should not use these
/// directly — read semantic colors from [VivColors] via `context.viv`.
abstract final class VivPalette {
  static const zeus = Color(0xFF16110F); // color/orange/7
  static const gondola = Color(0xFF1A1210); // color/red/8
  static const orange8 = Color(0xFF1A1310); // color/orange/8
  static const orange11 = Color(0xFF211A17); // color/orange/11
  static const taupe = Color(0xFF352C28); // color/orange/18
  static const orange25 = Color(0xFF4A3B36); // color/orange/25
  static const masala = Color(0xFF4A403D); // color/grey/26
  static const dorado = Color(0xFF6E6260); // color/grey/40
  static const sandstone = Color(0xFF7A6B66); // color/grey/44
  static const americano = Color(0xFF8A7B76); // color/grey/50
  static const zorba = Color(0xFFA2938E); // color/grey/60
  static const martini = Color(0xFFB4A8A4); // color/grey/67
  static const swirl = Color(0xFFD8CCC7); // color/orange/81
  static const wafer = Color(0xFFE4DAD6); // color/orange/87
  static const dawnPink = Color(0xFFF5EFEC); // color/grey/94
  static const vistaWhite = Color(0xFFFBF7F5); // color/grey/97
  static const white = Color(0xFFFFFFFF);

  static const cannonPink = Color(0xFF8A4A57); // color/red/42 — primary (light)
  static const puce = Color(0xFFC97F8D); // color/red/64 — primary (dark)
}

/// Semantic color roles used across VIV screens. Available as a
/// [ThemeExtension] so light/dark switch automatically.
@immutable
class VivColors extends ThemeExtension<VivColors> {
  const VivColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.primaryBorder,
    required this.inverse,
    required this.onInverse,
    required this.scrim,
  });

  /// Screen background.
  final Color background;

  /// Cards, inputs, secondary buttons.
  final Color surface;

  /// Rest-day rows, disabled buttons, inline notes.
  final Color surfaceMuted;

  final Color border;
  final Color borderStrong;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// Brand accent: main CTAs, selected pills, links.
  final Color primary;
  final Color onPrimary;

  /// Tinted background for highlighted cards ("Before you start", selected options).
  final Color primarySoft;
  final Color primaryBorder;

  /// High-contrast button (e.g. "Continue with Apple").
  final Color inverse;
  final Color onInverse;

  /// Dimmed backdrop behind bottom sheets.
  final Color scrim;

  static const light = VivColors(
    background: VivPalette.vistaWhite,
    surface: VivPalette.white,
    surfaceMuted: VivPalette.dawnPink,
    border: VivPalette.wafer,
    borderStrong: VivPalette.swirl,
    textPrimary: VivPalette.zeus,
    textSecondary: VivPalette.sandstone,
    textTertiary: VivPalette.zorba,
    primary: VivPalette.cannonPink,
    onPrimary: VivPalette.white,
    primarySoft: Color(0xFFF6E9EA),
    primaryBorder: Color(0xFFD9AFB7),
    inverse: VivPalette.zeus,
    onInverse: VivPalette.vistaWhite,
    scrim: Color(0x8C140E0C), // color/orange/6 55%
  );

  static const dark = VivColors(
    background: VivPalette.zeus,
    surface: VivPalette.orange11,
    surfaceMuted: VivPalette.orange8,
    border: VivPalette.taupe,
    borderStrong: VivPalette.orange25,
    textPrimary: VivPalette.vistaWhite,
    textSecondary: VivPalette.zorba,
    textTertiary: VivPalette.sandstone,
    primary: VivPalette.puce,
    onPrimary: VivPalette.gondola,
    primarySoft: Color(0xFF2B1F1E),
    primaryBorder: Color(0xFF6B4049),
    inverse: VivPalette.dawnPink,
    onInverse: VivPalette.zeus,
    scrim: Color(0xD1140E0C), // color/orange/6 82%
  );

  @override
  VivColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? primary,
    Color? onPrimary,
    Color? primarySoft,
    Color? primaryBorder,
    Color? inverse,
    Color? onInverse,
    Color? scrim,
  }) {
    return VivColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primarySoft: primarySoft ?? this.primarySoft,
      primaryBorder: primaryBorder ?? this.primaryBorder,
      inverse: inverse ?? this.inverse,
      onInverse: onInverse ?? this.onInverse,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  VivColors lerp(ThemeExtension<VivColors>? other, double t) {
    if (other is! VivColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return VivColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      primarySoft: l(primarySoft, other.primarySoft),
      primaryBorder: l(primaryBorder, other.primaryBorder),
      inverse: l(inverse, other.inverse),
      onInverse: l(onInverse, other.onInverse),
      scrim: l(scrim, other.scrim),
    );
  }
}
