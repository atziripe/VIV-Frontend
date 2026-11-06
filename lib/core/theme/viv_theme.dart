import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'viv_colors.dart';
import 'viv_spacing.dart';
import 'viv_typography.dart';

export 'viv_colors.dart';
export 'viv_motion.dart';
export 'viv_spacing.dart';
export 'viv_typography.dart';

abstract final class VivTheme {
  static ThemeData light() => _build(VivColors.light, Brightness.light);
  static ThemeData dark() => _build(VivColors.dark, Brightness.dark);

  /// Status bar glyphs: dark on the light page, light on the wine field, the
  /// done stage and in dark mode.
  static SystemUiOverlayStyle overlayFor(Brightness pageBrightness) =>
      pageBrightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light;

  /// For surfaces that are always dark (wine field, done stage).
  static const overlayOnField = SystemUiOverlayStyle.light;

  static ThemeData _build(VivColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.ctaText,
      secondary: c.ink,
      onSecondary: c.page,
      error: c.accent,
      onError: c.ctaText,
      surface: c.page,
      onSurface: c.ink,
      onSurfaceVariant: c.muted,
      surfaceContainerLowest: c.raised,
      surfaceContainerLow: c.raised,
      surfaceContainer: c.raised,
      surfaceContainerHigh: c.raised,
      surfaceContainerHighest: c.sunken,
      outline: c.line,
      outlineVariant: c.line,
      scrim: c.scrim,
    );

    final textTheme = TextTheme(
      displayLarge: VivType.hero.copyWith(color: c.ink),
      headlineLarge: VivType.h1.copyWith(color: c.ink),
      headlineMedium: VivType.h3.copyWith(color: c.ink),
      titleMedium: VivType.rowTitle.copyWith(color: c.ink),
      bodyLarge: VivType.lead.copyWith(color: c.ink),
      bodyMedium: VivType.body.copyWith(color: c.muted),
      labelLarge: VivType.button.copyWith(color: c.ink),
      labelMedium: VivType.label.copyWith(color: c.ink),
      bodySmall: VivType.meta.copyWith(color: c.subtle),
      labelSmall: VivType.eyebrow.copyWith(color: c.subtle),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: c.line),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: VivType.family,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.page,
      canvasColor: c.page,
      textTheme: textTheme,
      extensions: [c],
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: c.page,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: overlayFor(brightness),
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.raised,
        hintStyle: VivType.lead.copyWith(color: c.subtle),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(borderSide: BorderSide(color: c.accent, width: 1.5)),
        errorBorder: inputBorder.copyWith(borderSide: BorderSide(color: c.accent)),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        errorStyle: VivType.meta.copyWith(color: c.accent),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.raised,
        modalBackgroundColor: c.raised,
        modalBarrierColor: c.scrim,
        showDragHandle: true,
        dragHandleColor: c.line,
        dragHandleSize: const Size(38, 5),
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(VivRadius.sheet)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.toast,
        elevation: 0,
        contentTextStyle: VivType.body.copyWith(color: c.onToast, fontWeight: FontWeight.w600),
        shape: const StadiumBorder(),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : c.raised,
        ),
        checkColor: WidgetStatePropertyAll(c.ctaText),
        side: BorderSide(color: c.ring, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : c.ring,
        ),
        thumbColor: WidgetStatePropertyAll(c.raised),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.sunken,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent,
        selectionColor: c.accent.withValues(alpha: 0.25),
        selectionHandleColor: c.accent,
      ),
    );
  }
}

extension VivThemeContext on BuildContext {
  /// Semantic VIV colors for the current brightness.
  VivColors get viv => Theme.of(this).extension<VivColors>()!;
}
