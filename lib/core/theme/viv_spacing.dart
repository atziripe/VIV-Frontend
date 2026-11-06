/// Spacing scale used across VIV screens.
abstract final class VivSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;

  /// Horizontal page padding.
  static const gutter = 20.0;

  /// Top padding that clears the status bar. Set on the scaffold, never
  /// inside the scroll view.
  static const top = 60.0;

  /// Bottom inset for a pinned footer or the tab bar.
  static const bottomInset = 30.0;

  /// Card padding (16–18 compact).
  static const card = 20.0;
}

/// Pulse radii. Buttons, chips, segmented controls, set rows, strips and
/// toggles are always fully rounded ([pill]).
abstract final class VivRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 14.0;

  /// Options and inputs.
  static const option = 20.0;

  /// Tiles.
  static const tile = 22.0;

  /// Grouped lists; also wine-field day rows.
  static const group = 24.0;
  static const xl = group;

  /// Cards; also wine fields inside a list.
  static const card = 26.0;

  /// The full wine field, and sheets (top corners only).
  static const field = 30.0;
  static const sheet = 30.0;

  static const pill = 999.0;
}

abstract final class VivSize {
  /// Bottom CTA.
  static const cta = 58.0;

  /// In-card buttons.
  static const control = 54.0;

  /// Compact buttons.
  static const compact = 48.0;

  /// Minimum tap target.
  static const minTap = 44.0;

  /// Max content width on tablets / landscape, so phone layouts stay readable.
  static const maxContentWidth = 560.0;
}
