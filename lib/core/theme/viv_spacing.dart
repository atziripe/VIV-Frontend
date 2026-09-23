/// Spacing and radius scale used across VIV screens.
abstract final class VivSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;

  /// Horizontal page gutter on phones.
  static const gutter = 20.0;
}

abstract final class VivRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 14.0;
  static const xl = 24.0;
  static const pill = 999.0;
}

abstract final class VivSize {
  /// Height of primary/secondary buttons and text fields.
  static const control = 52.0;

  /// Max content width on tablets / landscape, so phone layouts stay readable.
  static const maxContentWidth = 560.0;
}
