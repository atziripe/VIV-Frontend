import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import '../theme/viv_theme.dart';
import 'viv_button.dart';

/// Renders an [AsyncValue] with VIV's loading and error states so every
/// screen handles them the same way.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.data, this.onRetry, this.loading});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      data: data,
      loading: () => loading ?? const LoadingView(),
      error: (e, _) => ErrorView(error: e, onRetry: onRetry),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VivSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            if (message != null) ...[
              const SizedBox(height: VivSpace.md),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: VivType.bodySmall.copyWith(color: c.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VivSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Something went sideways',
              style: VivType.cardTitle.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: VivSpace.xs),
            Text(
              userMessageFor(error),
              textAlign: TextAlign.center,
              style: VivType.bodySmall.copyWith(color: c.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: VivSpace.lg),
              VivButton.secondary(label: 'Try again', onPressed: onRetry, expand: false),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows a snackbar with a friendly message for [error].
void showErrorSnack(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(userMessageFor(error))));
}
