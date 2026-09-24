import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'viv_colors.dart';
import 'viv_spacing.dart';
import 'viv_typography.dart';

export 'viv_colors.dart';
export 'viv_spacing.dart';
export 'viv_typography.dart';

abstract final class VivTheme {
  static ThemeData light() => _build(VivColors.light, Brightness.light);
  static ThemeData dark() => _build(VivColors.dark, Brightness.dark);

  static ThemeData _build(VivColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.inverse,
      onSecondary: c.onInverse,
      error: const Color(0xFFB3261E),
      onError: Colors.white,
      surface: c.background,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surface,
      surfaceContainerHighest: c.surfaceMuted,
      outline: c.border,
      outlineVariant: c.border,
      scrim: c.scrim,
    );

    final textTheme = TextTheme(
      displayLarge: VivType.display.copyWith(color: c.textPrimary),
      headlineLarge: VivType.title.copyWith(color: c.textPrimary),
      headlineMedium: VivType.headline.copyWith(color: c.textPrimary),
      titleMedium: VivType.cardTitle.copyWith(color: c.textPrimary),
      bodyLarge: VivType.body.copyWith(color: c.textPrimary),
      bodyMedium: VivType.bodySmall.copyWith(color: c.textSecondary),
      labelLarge: VivType.button.copyWith(color: c.textPrimary),
      labelMedium: VivType.label.copyWith(color: c.textPrimary),
      bodySmall: VivType.caption.copyWith(color: c.textTertiary),
      labelSmall: VivType.eyebrow.copyWith(color: c.textTertiary),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(VivRadius.md),
      borderSide: BorderSide(color: c.border),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      textTheme: textTheme,
      extensions: [c],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: VivType.body.copyWith(color: c.textTertiary),
        contentPadding: const EdgeInsets.symmetric(horizontal: VivSpace.md, vertical: VivSpace.md),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(borderSide: BorderSide(color: c.primary, width: 1.2)),
        errorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFFB3261E))),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.2),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.background,
        modalBarrierColor: c.scrim,
        showDragHandle: true,
        dragHandleColor: c.borderStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(VivRadius.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.inverse,
        contentTextStyle: VivType.bodySmall.copyWith(color: c.onInverse),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VivRadius.md)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.surface,
        ),
        checkColor: WidgetStatePropertyAll(c.onPrimary),
        side: BorderSide(color: c.borderStrong, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.border,
        ),
        thumbColor: WidgetStatePropertyAll(c.surface),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.border,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withValues(alpha: 0.25),
        selectionHandleColor: c.primary,
      ),
    );
  }
}

extension VivThemeContext on BuildContext {
  /// Semantic VIV colors for the current brightness.
  VivColors get viv => Theme.of(this).extension<VivColors>()!;
}
