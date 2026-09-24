import 'package:flutter/material.dart';

/// Text styles taken from the Figma text styles (SF Pro + JetBrains Mono).
///
/// The sans family is left as the platform default on purpose: on iOS that
/// is SF Pro (exactly what the design uses); on Android it falls back to
/// Roboto. Colors are applied by [VivTheme] — these only carry metrics.
abstract final class VivType {
  static const mono = 'JetBrainsMono';

  /// Welcome hero: "Some weeks you train. Most weeks, life wins."
  static const display = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.08,
    letterSpacing: -1.12,
  );

  /// Screen titles: "Create your account", "This week". Semantic/Heading 2.
  static const title = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: -0.75,
  );

  /// Big number/section headline, e.g. "Hey Atziri", "Eat today".
  static const headline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.6,
  );

  /// Card titles: "Lower strength · 60 min". SF Pro/Semibold 17.
  static const cardTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.17,
  );

  /// Primary body copy. SF Pro/Regular 16.
  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: -0.32,
  );

  /// Supporting copy under titles (15.5 / 22.48 in Figma).
  static const bodySmall = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: -0.24,
  );

  /// Buttons and list-row titles. SF Pro/Medium 16.
  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: -0.32,
  );

  /// Field labels, row titles. Semantic/Label.
  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.13,
  );

  /// Captions and hints (12.5 / 18.75 in Figma).
  static const caption = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );

  /// Uppercase eyebrow: "BEFORE YOU START", "TODAY". JetBrains Mono/Regular.
  static const eyebrow = TextStyle(
    fontFamily: mono,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 1.2,
  );
}
