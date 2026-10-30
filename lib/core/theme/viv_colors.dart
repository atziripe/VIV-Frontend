import 'package:flutter/material.dart';

import '../../data/models/catalog.dart';

/// Semantic colour tokens from the Pulse design handoff
/// (`design_handoff_viv_pulse/README.md` → Design tokens). Available as a
/// [ThemeExtension] so light/dark switch automatically: read them with
/// `context.viv`, never raw hex in screens.
@immutable
class VivColors extends ThemeExtension<VivColors> {
  const VivColors({
    required this.page,
    required this.raised,
    required this.sunken,
    required this.line,
    required this.ring,
    required this.ink,
    required this.ink2,
    required this.muted,
    required this.subtle,
    required this.faint,
    required this.accent,
    required this.ctaText,
    required this.tint,
    required this.tintInk,
    required this.field,
    required this.photo,
    required this.stage,
    required this.scrim,
    required this.toast,
    required this.onToast,
    required this.hasShadow,
  });

  /// Screen background.
  final Color page;

  /// Cards, sheets, grouped lists.
  final Color raised;

  /// Rest-day pills, quiet strips, done-check fill, segmented track.
  final Color sunken;

  /// 1px hairlines.
  final Color line;

  /// Unselected radio/circle outlines, toggle off.
  final Color ring;

  /// Titles, values.
  final Color ink;

  /// Body inside cards.
  final Color ink2;

  /// Body on the page.
  final Color muted;

  /// Eyebrows, meta.
  final Color subtle;

  /// Chevrons only.
  final Color faint;

  /// Primary buttons, links, selection, active tab dot.
  final Color accent;

  /// Text on [accent].
  final Color ctaText;

  /// Soft info cards ("What changes").
  final Color tint;

  /// Text and eyebrows on [tint].
  final Color tintInk;

  /// The wine "now" block. Use [WineField] rather than painting it by hand.
  final Color field;

  /// Image slots (welcome hero, meal thumbnails).
  final Color photo;

  /// Session-done background.
  final Color stage;

  /// Behind bottom sheets.
  final Color scrim;

  /// Toast pill.
  final Color toast;
  final Color onToast;

  /// Cards cast the soft shadow in light mode only.
  final bool hasShadow;

  // ── On the wine field (both themes) ──────────────────────────────────────

  /// Titles on the field, primary pill background.
  static const onField = Color(0xFFFFF8F6);

  /// Body on the field.
  static const onFieldSoft = Color(0xE0FFF8F6); // 0.88

  /// Eyebrows and the pillar label on the field.
  static const onFieldMuted = Color(0xCCFFF8F6); // 0.80

  /// Secondary pill background, unselected options, progress track.
  static const onFieldFaint = Color(0x29FFF8F6); // 0.16

  /// Unselected check-in options.
  static const onFieldOption = Color(0x21FFF8F6); // 0.13

  /// Text on the [onField] pill.
  static const onFieldInv = Color(0xFF5E2C38);

  /// The blurred blob drifting behind the field's content.
  static const fieldGlow = Color(0xFFC97F8D);
  static const fieldGlow2 = Color(0xFFE7B3BC);

  // ── Session-done stage (both themes) ─────────────────────────────────────

  static const stageInk = Color(0xFFF5EFEC);
  static const doneRing = Color(0xFFC97F8D);
  static const onDoneRing = Color(0xFF1A1210);

  /// Track under the done ring.
  static const doneTrack = Color(0x1FF5EFEC); // 0.12

  /// Unselected pills on the stage.
  static const stageFaint = Color(0x14FFFFFF); // 0.08

  /// One dot per screen, fill only, never text. Identical in both themes.
  static Color phaseDot(CyclePhase phase) => switch (phase) {
    // McNulty et al. 2020: menstruation sits inside early follicular.
    CyclePhase.menstrual => const Color(0xFFB66F75), // early follicular
    CyclePhase.follicular => const Color(0xFF978642), // late follicular
    CyclePhase.ovulatory => const Color(0xFF57966E),
    CyclePhase.earlyLuteal => const Color(0xFF4590B2), // early/mid luteal
    CyclePhase.lateLuteal => const Color(0xFF9777AF),
  };

  /// `0 1px 2px rgba(26,19,16,.04), 0 10px 28px rgba(26,19,16,.06)`; none in dark.
  List<BoxShadow> get cardShadow => hasShadow
      ? const [
          BoxShadow(color: Color(0x0A1A1310), offset: Offset(0, 1), blurRadius: 2),
          BoxShadow(color: Color(0x0F1A1310), offset: Offset(0, 10), blurRadius: 28),
        ]
      : const [];

  static const light = VivColors(
    page: Color(0xFFFBF7F5),
    raised: Color(0xFFFFFFFF),
    sunken: Color(0xFFF3EDEA),
    line: Color(0xFFE4DAD6),
    ring: Color(0xFFD3C6C2),
    ink: Color(0xFF1A1310),
    ink2: Color(0xFF4A403D),
    muted: Color(0xFF6E6260),
    subtle: Color(0xFF7A6D69),
    faint: Color(0xFFC4B6B1),
    accent: Color(0xFF8A4A57),
    ctaText: Color(0xFFFFFFFF),
    tint: Color(0xFFF6EEEF),
    tintInk: Color(0xFF8A4A57),
    field: Color(0xFF8A4A57),
    photo: Color(0xFFE9DFDB),
    stage: Color(0xFF1A1310),
    scrim: Color(0x731A1310), // rgba(26,19,16,.45)
    toast: Color(0xFF1A1310),
    onToast: Color(0xFFF5EFEC),
    hasShadow: true,
  );

  static const dark = VivColors(
    page: Color(0xFF16110F),
    raised: Color(0xFF211A17),
    sunken: Color(0xFF2A221F),
    line: Color(0xFF352C28),
    ring: Color(0xFF4A3E39),
    ink: Color(0xFFF5EFEC),
    ink2: Color(0xFFD8CCC7),
    muted: Color(0xFFA2938E),
    subtle: Color(0xFF968782),
    faint: Color(0xFF6E5F5A),
    accent: Color(0xFFC97F8D),
    ctaText: Color(0xFF1A1210),
    tint: Color(0xFF2E2125),
    tintInk: Color(0xFFD998A4),
    field: Color(0xFF8E4D5B),
    photo: Color(0xFF2A221F),
    stage: Color(0xFF211A17),
    scrim: Color(0x99000000), // rgba(0,0,0,.6)
    toast: Color(0xFFF5EFEC),
    onToast: Color(0xFF1A1310),
    hasShadow: false,
  );

  @override
  VivColors copyWith({
    Color? page,
    Color? raised,
    Color? sunken,
    Color? line,
    Color? ring,
    Color? ink,
    Color? ink2,
    Color? muted,
    Color? subtle,
    Color? faint,
    Color? accent,
    Color? ctaText,
    Color? tint,
    Color? tintInk,
    Color? field,
    Color? photo,
    Color? stage,
    Color? scrim,
    Color? toast,
    Color? onToast,
    bool? hasShadow,
  }) {
    return VivColors(
      page: page ?? this.page,
      raised: raised ?? this.raised,
      sunken: sunken ?? this.sunken,
      line: line ?? this.line,
      ring: ring ?? this.ring,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      muted: muted ?? this.muted,
      subtle: subtle ?? this.subtle,
      faint: faint ?? this.faint,
      accent: accent ?? this.accent,
      ctaText: ctaText ?? this.ctaText,
      tint: tint ?? this.tint,
      tintInk: tintInk ?? this.tintInk,
      field: field ?? this.field,
      photo: photo ?? this.photo,
      stage: stage ?? this.stage,
      scrim: scrim ?? this.scrim,
      toast: toast ?? this.toast,
      onToast: onToast ?? this.onToast,
      hasShadow: hasShadow ?? this.hasShadow,
    );
  }

  @override
  VivColors lerp(ThemeExtension<VivColors>? other, double t) {
    if (other is! VivColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return VivColors(
      page: l(page, other.page),
      raised: l(raised, other.raised),
      sunken: l(sunken, other.sunken),
      line: l(line, other.line),
      ring: l(ring, other.ring),
      ink: l(ink, other.ink),
      ink2: l(ink2, other.ink2),
      muted: l(muted, other.muted),
      subtle: l(subtle, other.subtle),
      faint: l(faint, other.faint),
      accent: l(accent, other.accent),
      ctaText: l(ctaText, other.ctaText),
      tint: l(tint, other.tint),
      tintInk: l(tintInk, other.tintInk),
      field: l(field, other.field),
      photo: l(photo, other.photo),
      stage: l(stage, other.stage),
      scrim: l(scrim, other.scrim),
      toast: l(toast, other.toast),
      onToast: l(onToast, other.onToast),
      hasShadow: t < 0.5 ? hasShadow : other.hasShadow,
    );
  }
}
