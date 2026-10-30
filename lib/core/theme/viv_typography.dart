import 'package:flutter/material.dart';

/// Pulse type scale (`design_handoff_viv_pulse/README.md` → Typography):
/// Schibsted Grotesk 400–800, bundled in `assets/fonts`. Letter spacing in
/// the handoff is in em; here it's converted to logical pixels.
///
/// Colors are applied by [VivTheme] or with `.copyWith(color: ...)` — these
/// only carry metrics.
abstract final class VivType {
  static const family = 'SchibstedGrotesk';

  static const _tabular = [FontFeature.tabularFigures()];

  // ── Headlines ────────────────────────────────────────────────────────────

  /// Hero / proposal headline: 40 / 1.02 / 800 / −0.04em.
  static const hero = TextStyle(
    fontFamily: family,
    fontSize: 40,
    height: 1.02,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.6,
  );

  /// Screen title (h1): 32–36 / 1.04 / 800 / −0.038em.
  static const h1 = TextStyle(
    fontFamily: family,
    fontSize: 34,
    height: 1.04,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.29,
  );

  /// Check-in question: 36 / 1.06 / 800 / −0.035em.
  static const question = TextStyle(
    fontFamily: family,
    fontSize: 36,
    height: 1.06,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.26,
  );

  /// Wine field title: 30–34 / 1.04 / 800 / −0.035em.
  static const fieldTitle = TextStyle(
    fontFamily: family,
    fontSize: 34,
    height: 1.04,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.19,
  );

  /// Card title (h3): 22–28 / 1.08 / 800 / −0.03em.
  static const h3 = TextStyle(
    fontFamily: family,
    fontSize: 26,
    height: 1.08,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.78,
  );

  // ── Body ─────────────────────────────────────────────────────────────────

  /// Body lead: 15.5–16 / 1.5 / 400.
  static const lead = TextStyle(
    fontFamily: family,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  /// Body: 14.5–15 / 1.45 / 400.
  static const body = TextStyle(
    fontFamily: family,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  /// Row title: 15.5–16 / 500–700.
  static const rowTitle = TextStyle(
    fontFamily: family,
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );

  /// Eyebrow: 12 / 700 / +0.1em, uppercase (callers upper-case the text).
  static const eyebrow = TextStyle(
    fontFamily: family,
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );

  /// Meta: 13 / 400–600.
  static const meta = TextStyle(
    fontFamily: family,
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w400,
  );

  /// Legal: 12.5 / 1.5 / 400 — the smallest allowed.
  static const legal = TextStyle(
    fontFamily: family,
    fontSize: 12.5,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  /// Pill buttons: 16.5 / 700.
  static const button = TextStyle(
    fontFamily: family,
    fontSize: 16.5,
    height: 1.0,
    fontWeight: FontWeight.w700,
  );

  // ── Numbers (protein, rest timer, ring) ──────────────────────────────────

  /// Protein in the field: 52 / 800 / −0.045em, tabular.
  static const number = TextStyle(
    fontFamily: family,
    fontSize: 52,
    height: 1,
    fontWeight: FontWeight.w800,
    letterSpacing: -2.34,
    fontFeatures: _tabular,
  );

  /// Rest timer: 96 / 800 / −0.05em, tabular.
  static const timer = TextStyle(
    fontFamily: family,
    fontSize: 96,
    height: 1,
    fontWeight: FontWeight.w800,
    letterSpacing: -4.8,
    fontFeatures: _tabular,
  );

  /// Done ring count: 62 / 800 / −0.05em, tabular.
  static const ringCount = TextStyle(
    fontFamily: family,
    fontSize: 62,
    height: 1,
    fontWeight: FontWeight.w800,
    letterSpacing: -3.1,
    fontFeatures: _tabular,
  );

  // ── Pre-Pulse names, kept so screens not yet rebuilt still compile ───────

  static const display = h1;
  static const title = h1;
  static const headline = h3;
  static const cardTitle = rowTitle;
  static const bodySmall = body;
  static const label = TextStyle(
    fontFamily: family,
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
  static const caption = meta;
}
